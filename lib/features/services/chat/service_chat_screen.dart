import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/service_media_uploader.dart';
import '../data/services_booking_repository.dart';
import '../models/service_chat_message.dart';

/// The shared per-booking chat thread (`service_chat`). Every participant
/// of the booking — this customer, the provider, the assigned technician
/// or inspector — sees the same thread; the existing
/// `service_chat_participant_*` RLS policies gate it, so there is no RPC.
/// Reached from the booking tracking screen.
class ServiceChatScreen extends StatefulWidget {
  final String bookingId;
  final String? title;

  const ServiceChatScreen({super.key, required this.bookingId, this.title});

  @override
  State<ServiceChatScreen> createState() => _ServiceChatScreenState();
}

class _ServiceChatScreenState extends State<ServiceChatScreen> {
  final _repo = ServicesBookingRepository(Supabase.instance.client);
  final _controller = TextEditingController();

  List<ServiceChatMessage> _messages = const [];
  String? _myCustomerId;
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    String? myId;
    if (user != null) {
      final row = await client.from('customers').select('id').eq('auth_user_id', user.id).maybeSingle();
      myId = row?['id'] as String?;
    }
    final messages = await _repo.fetchChatThread(widget.bookingId);
    if (!mounted) return;
    setState(() {
      _myCustomerId = myId;
      _messages = messages;
      _loading = false;
    });
  }

  Future<void> _send({String? message, String? mediaUrl}) async {
    if ((message == null || message.isEmpty) && mediaUrl == null) return;
    setState(() => _sending = true);
    try {
      await _repo.sendChatMessage(bookingId: widget.bookingId, message: message, mediaUrl: mediaUrl);
      _controller.clear();
      await _load();
    } on ServicesException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendPhoto() async {
    setState(() => _sending = true);
    final url = await captureAndUploadServiceMedia(Supabase.instance.client);
    if (url == null) {
      if (mounted) setState(() => _sending = false);
      return;
    }
    await _send(mediaUrl: url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title ?? 'Chat')),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(child: Text('No messages yet. Ask your provider anything.'))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (context, i) => _Bubble(
                            message: _messages[i],
                            mine: _messages[i].isMine(_myCustomerId),
                          ),
                        ),
                      ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 12, 12),
            child: Row(
              children: [
                IconButton(
                  onPressed: _sending ? null : _sendPhoto,
                  icon: const Icon(Icons.add_a_photo_outlined),
                  tooltip: 'Send a photo',
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (v) => _send(message: v.trim()),
                    decoration: const InputDecoration(
                      hintText: 'Message',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _sending ? null : () => _send(message: _controller.text.trim()),
                  icon: _sending
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ServiceChatMessage message;
  final bool mine;

  const _Bubble({required this.message, required this.mine});

  @override
  Widget build(BuildContext context) {
    final align = mine ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = mine ? const Color(0xFFDCEBFF) : const Color(0xFFF1F1F4);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Text(mine ? 'You' : message.senderLabel, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            constraints: const BoxConstraints(maxWidth: 300),
            decoration: BoxDecoration(color: bubbleColor, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((message.message ?? '').isNotEmpty) Text(message.message!),
                if (message.mediaUrl != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(message.mediaUrl!, height: 150, fit: BoxFit.cover),
                    ),
                  ),
                const SizedBox(height: 2),
                Text(
                  TimeOfDay.fromDateTime(message.createdAt.toLocal()).format(context),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
