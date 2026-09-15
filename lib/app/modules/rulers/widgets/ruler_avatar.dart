import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../ruler_service.dart';

/// Avatar ya Ruler kwenye orodha - inavuta picha HALISI (kama ipo) kwa
/// authenticated request (siyo NetworkImage ya kawaida, kwa sababu picha
/// zote zinahitaji Bearer token). Ikiwa hana picha (404), inaonyesha icon
/// ya kawaida bila ku-flicker/kujaribu tena mara kwa mara.
class RulerAvatar extends StatefulWidget {
  final int rulerId;
  final double radius;
  const RulerAvatar({super.key, required this.rulerId, this.radius = 15});

  @override
  State<RulerAvatar> createState() => _RulerAvatarState();
}

class _RulerAvatarState extends State<RulerAvatar> {
  static final Map<int, List<int>?> _cache = {}; // cache rahisi ya session hii
  List<int>? _bytes;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_cache.containsKey(widget.rulerId)) {
      setState(() {
        _bytes = _cache[widget.rulerId];
        _loaded = true;
      });
      return;
    }
    final service = Get.find<RulerService>();
    final bytes = await service.getPhotoBytes(widget.rulerId);
    _cache[widget.rulerId] = bytes;
    if (mounted) {
      setState(() {
        _bytes = bytes;
        _loaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return CircleAvatar(
        radius: widget.radius,
        backgroundColor: AppColors.avatarBg,
        child: SizedBox(
          height: widget.radius * 0.8,
          width: widget.radius * 0.8,
          child: const CircularProgressIndicator(strokeWidth: 1.5),
        ),
      );
    }
    if (_bytes != null) {
      return CircleAvatar(
        radius: widget.radius,
        backgroundImage: MemoryImage(Uint8List.fromList(_bytes!)),
        backgroundColor: AppColors.avatarBg,
      );
    }
    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: AppColors.avatarBg,
      child: Icon(Icons.person, size: widget.radius * 1.05, color: AppColors.primaryGreen),
    );
  }
}
