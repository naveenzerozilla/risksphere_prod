import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HazardInfoSection extends StatefulWidget {
  final String hazardName;
  final String? hazardType;
  final String selectedDate;
  final String lastUpdated;
  final Function(String?) onDateChanged;

  /// Full datetime strings like "2026-09-01 04:14:15".
  /// The widget groups them by date internally.
  final List<String> availableDates;

  final int? rating;
  final VoidCallback? onRefresh;
  final Widget? trailingWidget;

  const HazardInfoSection({
    super.key,
    required this.hazardName,
    this.hazardType,
    required this.selectedDate,
    required this.lastUpdated,
    required this.onDateChanged,
    required this.availableDates,
    this.rating,
    this.onRefresh,
    this.trailingWidget,
  });

  @override
  State<HazardInfoSection> createState() => _HazardInfoSectionState();
}

class _HazardInfoSectionState extends State<HazardInfoSection> {
  // Map from "yyyy-MM-dd" → full date string
  Map<String, String> _dateMap = {};

  // The currently selected date key ("yyyy-MM-dd") — initialized to empty
  String _selectedDateKey = '';

  @override
  void initState() {
    super.initState();
    _buildMaps();
  }

  @override
  void didUpdateWidget(covariant HazardInfoSection old) {
    super.didUpdateWidget(old);
    // Only rebuild the date→time map when the set of available dates changes.
    // Do NOT rebuild on selectedDate change — that would reset the user's pick.
    if (!_listEquals(old.availableDates, widget.availableDates)) {
      _buildMaps();
    }
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Group the incoming full-datetime strings into { date → full_datetime }
  void _buildMaps() {
    _dateMap = {};

    for (final raw in widget.availableDates) {
      final dt = DateTime.tryParse(raw);
      if (dt != null) {
        final dateKey = DateFormat('yyyy-MM-dd').format(dt);
        _dateMap.putIfAbsent(dateKey, () => raw);
      } else {
        _dateMap.putIfAbsent(raw, () => raw);
      }
    }

    // Sort date keys to find the earliest (event start date)
    final sortedDates = _dateMap.keys.toList()..sort();

    // If the user has already selected a date that still exists in the new
    // map, keep it. Otherwise default to the earliest (event start date).
    final keepCurrent = _selectedDateKey.isNotEmpty &&
        _dateMap.containsKey(_selectedDateKey);

    if (!keepCurrent) {
      _selectedDateKey = sortedDates.isNotEmpty ? sortedDates.first : '';
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Helpers
  // ────────────────────────────────────────────────────────────────────────────

  String _resolveTypeLabel() {
    String label = widget.hazardType?.trim() ?? '';
    if (label.isEmpty || label.toLowerCase() == 'event hazard') {
      final n = widget.hazardName.toLowerCase();
      if (n.contains('earthquake')) return 'Earthquake';
      if (n.contains('hurricane')) return 'Hurricane';
      if (n.contains('tropical storm') || n.contains('storm'))
        return 'Tropical Storm';
      if (n.contains('flood')) return 'Flood';
      if (n.contains('wildfire') || n.contains('fire')) return 'Wildfire';
      if (n.contains('tornado')) return 'Tornado';
      return 'Hurricane';
    }
    return label;
  }

  int _resolveScore(String typeLabel) {
    if (widget.rating != null) return widget.rating!;
    final text =
        '${widget.hazardName.toLowerCase()} ${widget.lastUpdated.toLowerCase()}';
    if (text.contains('cat 5') ||
        text.contains('category 5') ||
        text.contains('mag 7') ||
        text.contains('magnitude 7')) return 5;
    if (text.contains('cat 4') ||
        text.contains('category 4') ||
        text.contains('mag 6') ||
        text.contains('magnitude 6')) return 4;
    if (text.contains('cat 3') ||
        text.contains('category 3') ||
        text.contains('mag 5') ||
        text.contains('magnitude 5')) return 3;
    if (text.contains('cat 2') ||
        text.contains('category 2') ||
        text.contains('mag 4') ||
        text.contains('magnitude 4')) return 2;
    if (text.contains('cat 1') ||
        text.contains('category 1') ||
        text.contains('mag 3') ||
        text.contains('magnitude 3')) return 1;
    if (typeLabel == 'Earthquake') return 3;
    return 2;
  }

  Color _colorForScore(int score) {
    switch (score) {
      case 5:
        return const Color(0xFFFF5252);
      case 4:
        return const Color(0xFFFF6E40);
      case 3:
        return const Color(0xFFFF9800);
      case 2:
        return const Color(0xFFFFD54F);
      default:
        return const Color(0xFF81C784);
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Date picker
  // ────────────────────────────────────────────────────────────────────────────

  Future<void> _openDatePicker(BuildContext context) async {
    if (_dateMap.isEmpty) return;

    final sortedKeys = _dateMap.keys.toList()..sort();
    
    DateTime firstDt = DateTime.now();
    DateTime lastDt = DateTime.now();
    try {
      firstDt = DateTime.parse(sortedKeys.first);
      lastDt = DateTime.parse(sortedKeys.last);
    } catch (_) {}

    // Start on the currently selected date if it parses, else first available
    DateTime initial;
    try {
      initial = DateTime.parse(_selectedDateKey);
    } catch (_) {
      initial = firstDt;
    }
    // Clamp to valid range
    if (initial.isBefore(firstDt)) initial = firstDt;
    if (initial.isAfter(lastDt)) initial = lastDt;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDt,
      lastDate: lastDt,
      selectableDayPredicate: (day) {
        final key = DateFormat('yyyy-MM-dd').format(day);
        return _dateMap.containsKey(key);
      },
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF4FC3F7),
              onPrimary: Colors.black,
              surface: Color(0xFF1E1E2E),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF1A1A2E),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      final key = DateFormat('yyyy-MM-dd').format(picked);
      setState(() {
        _selectedDateKey = key;
      });
      final notifyWith = _dateMap[key] ?? key;
      widget.onDateChanged(notifyWith);
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Build
  // ────────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final typeLabel = _resolveTypeLabel();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,

        children: [
          // ── Combined Event Name and Type ──
          Text(
            '$typeLabel  -  ${widget.hazardName}',
            style: const TextStyle(
              fontSize: 19.0,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),


          Row(
            children: [
              GestureDetector(
                onTap: () => _openDatePicker(context),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E2E),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.18), width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_month_outlined,
                          color: Color(0xFF4FC3F7), size: 14),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _selectedDateKey.isNotEmpty
                              ? _selectedDateKey
                              : 'Select Date',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down,
                          color: Colors.white54, size: 16),
                    ],
                  ),
                ),
              ),
              if (widget.trailingWidget != null) const Spacer(),
              if (widget.trailingWidget != null) widget.trailingWidget!,
            ],
          ),


          // const SizedBox(height: 6),

          // ── Footer: Last Updated & Refresh ──
          // Row(
          //   children: [
          //     Text(
          //       'Last Updated: ${widget.lastUpdated}',
          //       style: TextStyle(
          //         fontSize: 12.0,
          //         color: Colors.white.withOpacity(0.55),
          //         fontWeight: FontWeight.w400,
          //       ),
          //     ),
          //     const SizedBox(width: 8),
          //     if (widget.onRefresh != null)
          //       GestureDetector(
          //         onTap: widget.onRefresh,
          //         child: Icon(
          //           Icons.refresh,
          //           size: 15,
          //           color: Colors.white.withOpacity(0.6),
          //         ),
          //       ),
          //   ],
          // ),
        ],
      ),
    );
  }
}
