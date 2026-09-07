import 'package:flutter/material.dart';

import '../models/service_method.dart';
import '../theme/service_colors.dart';

/// Which parts of the standard booking form a given Master Method needs,
/// plus the `create_service_booking` `p_location_type` it maps to. Keeps
/// the method → form-shape decision in one place instead of scattered
/// `if (code == ...)` across the screen.
class MethodBookingPlan {
  final bool needsServiceAddress;
  final bool needsDate;
  final bool needsTimeSlot;

  /// Passed to create_service_booking as p_location_type
  /// (customer_home | provider_location | onsite | pickup_drop | other).
  final String locationType;
  final String addressLabel;

  /// A short line shown above the method-specific fields.
  final String intro;

  const MethodBookingPlan({
    required this.needsServiceAddress,
    required this.needsDate,
    required this.needsTimeSlot,
    required this.locationType,
    required this.addressLabel,
    required this.intro,
  });

  static const _generic = MethodBookingPlan(
    needsServiceAddress: true,
    needsDate: true,
    needsTimeSlot: true,
    locationType: 'customer_home',
    addressLabel: 'Address',
    intro: '',
  );

  factory MethodBookingPlan.forCode(String? code) {
    switch (code) {
      case 'store_pickup':
        return const MethodBookingPlan(
          needsServiceAddress: false,
          needsDate: true,
          needsTimeSlot: true,
          locationType: 'provider_location',
          addressLabel: 'Address',
          intro: 'You collect the completed service from the provider\'s store.',
        );
      case 'walk_in':
        return const MethodBookingPlan(
          needsServiceAddress: false,
          needsDate: false,
          needsTimeSlot: false,
          locationType: 'provider_location',
          addressLabel: 'Address',
          intro: 'No slot needed — walk in during the provider\'s open hours.',
        );
      case 'store_delivery':
        return const MethodBookingPlan(
          needsServiceAddress: true,
          needsDate: true,
          needsTimeSlot: true,
          locationType: 'customer_home',
          addressLabel: 'Delivery address',
          intro: 'The finished service / item is delivered to you.',
        );
      case 'home_visit':
        return const MethodBookingPlan(
          needsServiceAddress: true,
          needsDate: true,
          needsTimeSlot: true,
          locationType: 'customer_home',
          addressLabel: 'Service address',
          intro: 'A technician travels to your address.',
        );
      case 'instant_on_demand':
        return const MethodBookingPlan(
          needsServiceAddress: true,
          needsDate: false,
          needsTimeSlot: false,
          locationType: 'customer_home',
          addressLabel: 'Service address',
          intro: 'On-demand — a provider responds as soon as possible, no slot.',
        );
      case 'pickup_and_drop':
        return const MethodBookingPlan(
          needsServiceAddress: true,
          needsDate: true,
          needsTimeSlot: true,
          locationType: 'pickup_drop',
          addressLabel: 'Pickup address',
          intro: 'The provider collects the item, services it, and returns it.',
        );
      case 'appointment_booking':
        return const MethodBookingPlan(
          needsServiceAddress: false,
          needsDate: true,
          needsTimeSlot: true,
          locationType: 'provider_location',
          addressLabel: 'Address',
          intro: 'Pick a date and time slot for your appointment.',
        );
      case 'multi_step_workflow':
        return const MethodBookingPlan(
          needsServiceAddress: true,
          needsDate: true,
          needsTimeSlot: true,
          locationType: 'onsite',
          addressLabel: 'Service address',
          intro: 'Runs in stages — you approve a quote before any paid work.',
        );
      case 'subscription':
        return const MethodBookingPlan(
          needsServiceAddress: true,
          needsDate: true,
          needsTimeSlot: true,
          locationType: 'customer_home',
          addressLabel: 'Service address',
          intro: 'Set up a recurring plan; the first visit is booked now.',
        );
      case 'lead_generation':
        return const MethodBookingPlan(
          needsServiceAddress: false,
          needsDate: false,
          needsTimeSlot: false,
          locationType: 'other',
          addressLabel: 'Address',
          intro: 'Submit an enquiry — the provider contacts you to finalise.',
        );
      case 'hybrid':
        return const MethodBookingPlan(
          needsServiceAddress: true,
          needsDate: true,
          needsTimeSlot: true,
          locationType: 'other',
          addressLabel: 'Service address',
          intro: 'A combined flow — choose which part happens first.',
        );
      default:
        return _generic;
    }
  }
}

/// Renders the method-specific inputs for the chosen [method] and reports
/// their values through [onChanged] as a flat `Map<String,dynamic>` the
/// booking screen folds into `p_customer_notes` (a labelled block the
/// provider + Services Admin read). The map is also inspected by the
/// screen for a couple of cross-field effects (subscription → recurring).
class MethodBookingFields extends StatefulWidget {
  final ServiceMethodRow method;
  final ValueChanged<Map<String, dynamic>> onChanged;

  const MethodBookingFields({super.key, required this.method, required this.onChanged});

  @override
  State<MethodBookingFields> createState() => _MethodBookingFieldsState();
}

class _MethodBookingFieldsState extends State<MethodBookingFields> {
  final Map<String, dynamic> _values = {};

  String get _code => widget.method.methodCode;
  /// Vendor's APPROVED method_config takes precedence over the Admin's
  /// service-level config for any key both set.
  Map<String, dynamic> get _svcCfg => {
        ...widget.method.serviceConfig,
        ...widget.method.vendorMethodConfig,
      };

  void _set(String key, dynamic value) {
    setState(() {
      if (value == null || (value is String && value.trim().isEmpty)) {
        _values.remove(key);
      } else {
        _values[key] = value is String ? value.trim() : value;
      }
    });
    widget.onChanged(Map<String, dynamic>.from(_values));
  }

  @override
  void initState() {
    super.initState();
    // seed subscription defaults so the parent sees them immediately
    if (_code == 'subscription') {
      final freqs = _frequencyOptions;
      _values['plan_frequency'] = (_svcCfg['frequency'] ?? (freqs.isNotEmpty ? freqs.first : 'monthly')).toString();
      final dur = _svcCfg['duration_months'];
      if (dur != null) _values['plan_duration_months'] = dur;
      final visits = _svcCfg['visits_included'];
      if (visits != null) _values['visits_included'] = visits;
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onChanged(Map<String, dynamic>.from(_values)));
    }
  }

  List<String> get _frequencyOptions {
    for (final f in widget.method.configSchema) {
      if (f['key'] == 'frequency' && f['options'] is List) {
        return (f['options'] as List).map((e) => e.toString()).toList();
      }
    }
    return const ['weekly', 'fortnightly', 'monthly', 'quarterly'];
  }

  List<String> get _hybridParts {
    final fromCfg = _svcCfg['component_methods'];
    if (fromCfg is List && fromCfg.isNotEmpty) return fromCfg.map((e) => e.toString()).toList();
    for (final f in widget.method.configSchema) {
      if (f['key'] == 'component_methods' && f['options'] is List) {
        return (f['options'] as List).map((e) => e.toString()).toList();
      }
    }
    return const ['appointment_booking', 'home_visit'];
  }

  List<String> get _workflowSteps {
    final s = _svcCfg['steps'];
    if (s is List && s.isNotEmpty) return s.map((e) => e.toString()).toList();
    if (s is String && s.trim().isNotEmpty) {
      return s.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    return const ['Inspection', 'Quotation', 'Your approval', 'Work', 'Completion'];
  }

  @override
  Widget build(BuildContext context) {
    final plan = MethodBookingPlan.forCode(_code);
    final rows = <Widget>[];

    if (plan.intro.isNotEmpty) {
      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(plan.intro, style: const TextStyle(fontSize: 12.5, color: ServiceColors.textSecondary)),
      ));
    }

    switch (_code) {
      case 'store_pickup':
        rows.add(_text('pickup_branch', 'Preferred store / branch',
            hint: _svcCfg['pickup_branch']?.toString() ?? 'Which outlet will you collect from?'));
        rows.add(_text('pickup_slot', 'Preferred pickup time', hint: 'e.g. 5 PM onwards'));
        break;
      case 'walk_in':
        rows.add(_text('branch', 'Which branch will you visit?',
            hint: _svcCfg['branch']?.toString() ?? 'Branch / outlet'));
        if (_svcCfg['queue_support'] == true) {
          rows.add(const Text('This provider issues a queue token on arrival.',
              style: TextStyle(fontSize: 12, color: ServiceColors.textSecondary)));
        }
        break;
      case 'store_delivery':
        rows.add(_text('delivery_instructions', 'Delivery instructions (optional)',
            hint: 'Gate code, floor, preferred time', maxLines: 2));
        break;
      case 'instant_on_demand':
        rows.add(_text('urgency', 'Describe what you need right now *', maxLines: 3));
        break;
      case 'pickup_and_drop':
        rows.add(_text('drop_address', 'Drop-off address *', maxLines: 2,
            hint: 'Where should the item be returned?'));
        rows.add(_text('item_note', 'Item / condition note', hint: 'e.g. 1 laptop, screen cracked', maxLines: 2));
        break;
      case 'appointment_booking':
        rows.add(_text('appointment_note', 'Anything the provider should prepare for?', maxLines: 2));
        break;
      case 'multi_step_workflow':
        rows.add(Align(
          alignment: Alignment.centerLeft,
          child: Text('Stages', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
        ));
        for (var i = 0; i < _workflowSteps.length; i++) {
          rows.add(Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('${i + 1}. ${_workflowSteps[i]}', style: const TextStyle(fontSize: 12.5)),
          ));
        }
        rows.add(const SizedBox(height: 8));
        rows.add(_text('scope_note', 'Describe the problem / scope *', maxLines: 3));
        break;
      case 'subscription':
        rows.add(_dropdown('plan_frequency', 'Plan frequency *', _frequencyOptions,
            _values['plan_frequency']?.toString()));
        rows.add(_number('plan_duration_months', 'Plan duration (months)',
            initial: _values['plan_duration_months']));
        if (_svcCfg['visits_included'] != null) {
          rows.add(Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text('Includes ${_svcCfg['visits_included']} visit(s) per cycle.',
                style: const TextStyle(fontSize: 12, color: ServiceColors.textSecondary)),
          ));
        }
        break;
      case 'lead_generation':
        rows.add(_text('requirement', 'What do you need? *', maxLines: 3));
        rows.add(_text('contact_phone', 'Best contact number *'));
        rows.add(_text('contact_email', 'Contact email (optional)'));
        break;
      case 'hybrid':
        rows.add(_dropdown('first_part', 'Which part happens first? *', _hybridParts,
            _values['first_part']?.toString()));
        rows.add(_text('hybrid_note', 'Anything else we should know?', maxLines: 2));
        break;
      default:
        break;
    }

    // Any remaining schema fields not covered above → render generically so
    // an Admin-added field is never silently dropped.
    final handled = _values.keys.toSet()
      ..addAll(['plan_frequency', 'plan_duration_months', 'visits_included']);
    for (final f in widget.method.configSchema) {
      final key = f['key']?.toString() ?? '';
      if (key.isEmpty || handled.contains(key)) continue;
      if (['pickup_branch', 'branch', 'steps', 'frequency', 'component_methods', 'contact_phone', 'contact_email']
          .contains(key)) {
        continue;
      }
      // only surface customer-relevant free inputs, not vendor-config toggles
      final type = f['type']?.toString();
      if (type == 'bool' || type == 'days' || type == 'time' || type == 'slots') continue;
      rows.add(_text(key, (f['label'] ?? key).toString()));
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ServiceColors.cardGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('${widget.method.methodName} details',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 10),
          ...rows,
        ],
      ),
    );
  }

  Widget _text(String key, String label, {String? hint, int maxLines = 1}) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          maxLines: maxLines,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            isDense: true,
            border: const OutlineInputBorder(),
          ),
          onChanged: (v) => _set(key, v),
        ),
      );

  Widget _number(String key, String label, {dynamic initial}) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextFormField(
          initialValue: initial?.toString(),
          keyboardType: const TextInputType.numberWithOptions(decimal: false),
          decoration: InputDecoration(labelText: label, isDense: true, border: const OutlineInputBorder()),
          onChanged: (v) => _set(key, int.tryParse(v.trim())),
        ),
      );

  Widget _dropdown(String key, String label, List<String> options, String? value) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: DropdownButtonFormField<String>(
          initialValue: options.contains(value) ? value : null,
          decoration: InputDecoration(labelText: label, isDense: true, border: const OutlineInputBorder()),
          items: [for (final o in options) DropdownMenuItem(value: o, child: Text(o))],
          onChanged: (v) => _set(key, v),
        ),
      );
}
