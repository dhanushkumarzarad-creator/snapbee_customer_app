import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/entertainment_repository.dart';
import '../theme/entertainment_colors.dart';
import 'movie_ticket_screen.dart';

/// Select Seats -> 5-minute Lock -> Guest Details -> Payment -> Confirmation.
///
/// The lock is enforced SERVER-SIDE (lock_movie_seats() in
/// entertainment_module.sql — a real Postgres row lock + a pg_cron sweep
/// that releases expired locks every minute). This screen's countdown is
/// purely a UI convenience mirroring `lock_expires_at`; if the customer's
/// timer runs out, confirmBooking() will simply reject the stale lock_token
/// server-side — the countdown never IS the enforcement.
class SeatSelectionScreen extends StatefulWidget {
  final Map<String, dynamic> show;
  const SeatSelectionScreen({super.key, required this.show});

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

enum _Stage { selecting, locked, confirming }

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  final _repo = EntertainmentRepository(Supabase.instance.client);
  List<Map<String, dynamic>> _seats = [];
  final Set<String> _selectedSeatIds = {}; // movie_screen_seats.id (seat_id)
  bool _loading = true;
  String? _error;

  _Stage _stage = _Stage.selecting;
  String? _lockToken;
  DateTime? _lockExpiresAt;
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final seats = await _repo.listSeatsForShow(widget.show['id'] as String);
      setState(() {
        _seats = seats;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load seats: $e';
        _loading = false;
      });
    }
  }

  num get _totalPrice => _selectedSeatIds.fold<num>(0, (sum, id) {
        final seat = _seats.firstWhere((s) => s['seat_id'] == id);
        return sum + (seat['price'] as num);
      });

  Future<void> _lockAndContinue() async {
    if (_selectedSeatIds.isEmpty) return;
    setState(() => _error = null);
    try {
      final result = await _repo.lockSeats(showId: widget.show['id'] as String, seatIds: _selectedSeatIds.toList());
      final expiresAt = DateTime.parse(result['expires_at'] as String);
      setState(() {
        _lockToken = result['lock_token'] as String;
        _lockExpiresAt = expiresAt;
        _stage = _Stage.locked;
      });
      _startCountdown();
    } catch (e) {
      setState(() => _error = 'Could not lock seats — someone may have just taken one. $e');
      await _load();
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_lockExpiresAt == null) return;
      final remaining = _lockExpiresAt!.difference(DateTime.now());
      if (remaining.isNegative) {
        timer.cancel();
        setState(() {
          _stage = _Stage.selecting;
          _selectedSeatIds.clear();
          _error = 'Your seat lock expired. Please select again.';
        });
        _load();
      } else {
        setState(() => _remaining = remaining);
      }
    });
  }

  Future<void> _confirm() async {
    if (_lockToken == null) return;
    setState(() => _stage = _Stage.confirming);
    try {
      final bookingId = await _repo.confirmBooking(showId: widget.show['id'] as String, seatIds: _selectedSeatIds.toList(), lockToken: _lockToken!);
      _timer?.cancel();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => MovieTicketScreen(bookingId: bookingId, show: widget.show, seatCount: _selectedSeatIds.length, totalAmount: _totalPrice)));
    } catch (e) {
      setState(() {
        _stage = _Stage.locked;
        _error = 'Payment/confirmation failed: $e';
      });
    }
  }

  Color _colorFor(Map<String, dynamic> seat) {
    if (_selectedSeatIds.contains(seat['seat_id'])) return EntertainmentColors.seatSelected;
    final status = seat['status'] as String;
    if (status == 'BOOKED') return EntertainmentColors.seatBooked;
    if (status == 'LOCKED') return EntertainmentColors.seatBlocked;
    switch (seat['seat_type'] as String) {
      case 'premium':
        return EntertainmentColors.seatPremium;
      case 'recliner':
        return EntertainmentColors.seatRecliner;
      case 'couple':
        return EntertainmentColors.seatCouple;
      case 'disabled_access':
        return EntertainmentColors.seatDisabled;
      default:
        return EntertainmentColors.seatAvailable;
    }
  }

  @override
  Widget build(BuildContext context) {
    final movie = (widget.show['movies'] as Map?)?['title'] ?? 'Movie';
    return Scaffold(
      backgroundColor: EntertainmentColors.background,
      appBar: AppBar(title: Text('$movie · ${widget.show['show_time']}'), backgroundColor: EntertainmentColors.primary, foregroundColor: Colors.white),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_stage == _Stage.locked)
                  Container(
                    width: double.infinity,
                    color: EntertainmentColors.accent.withValues(alpha: 0.15),
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'Seats locked — complete booking within ${_remaining.inMinutes}:${(_remaining.inSeconds % 60).toString().padLeft(2, '0')}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: EntertainmentColors.accent),
                    ),
                  ),
                if (_error != null) Padding(padding: const EdgeInsets.all(8), child: Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center)),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: _buildSeatGrid(),
                  ),
                ),
                _buildBottomBar(),
              ],
            ),
    );
  }

  Widget _buildSeatGrid() {
    final byRow = <String, List<Map<String, dynamic>>>{};
    for (final s in _seats) {
      final seatMeta = s['movie_screen_seats'] as Map;
      final row = seatMeta['row_label'] as String;
      byRow.putIfAbsent(row, () => []).add(s);
    }
    final rows = byRow.keys.toList()..sort();
    return Column(
      children: rows.map((row) {
        final seats = byRow[row]!..sort((a, b) => ((a['movie_screen_seats'] as Map)['seat_number'] as int).compareTo((b['movie_screen_seats'] as Map)['seat_number'] as int));
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(width: 20, child: Text(row, style: const TextStyle(fontWeight: FontWeight.bold))),
              ...seats.map((seat) {
                final seatMeta = seat['movie_screen_seats'] as Map;
                final canTap = _stage == _Stage.selecting && (seat['status'] == 'AVAILABLE' || _selectedSeatIds.contains(seat['seat_id']));
                return Padding(
                  padding: const EdgeInsets.all(2),
                  child: InkWell(
                    onTap: canTap
                        ? () => setState(() {
                              final id = seat['seat_id'] as String;
                              if (_selectedSeatIds.contains(id)) {
                                _selectedSeatIds.remove(id);
                              } else {
                                _selectedSeatIds.add(id);
                              }
                            })
                        : null,
                    child: Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: _colorFor(seat), borderRadius: BorderRadius.circular(6)),
                      child: Text('${seatMeta['seat_number']}', style: const TextStyle(color: Colors.white, fontSize: 8)),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: EntertainmentColors.surface, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8)]),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _selectedSeatIds.isEmpty ? 'Select seats' : '${_selectedSeatIds.length} seat(s) · ₹$_totalPrice',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (_stage == _Stage.selecting)
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: EntertainmentColors.primary),
                onPressed: _selectedSeatIds.isEmpty ? null : _lockAndContinue,
                child: const Text('Lock seats'),
              )
            else
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: EntertainmentColors.accent),
                onPressed: _stage == _Stage.confirming ? null : _confirm,
                child: _stage == _Stage.confirming ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Pay & Confirm'),
              ),
          ],
        ),
      ),
    );
  }
}
