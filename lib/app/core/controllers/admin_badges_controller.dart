import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../network/api_client.dart';

/// Controller ya PERMANENT inayoangalia mara kwa mara (polling - kila
/// sekunde 15) 'chips/badges' za maeneo mbalimbali ya Admin Panel -
/// kila mahali penye 'data mpya kutoka kwa Wanachama' inayohitaji
/// uangalizi. Endpoint MOJA (badges zote kwa mkupuo mmoja) kwa ufanisi.
///
/// MUHIMU: pindi idadi YOYOTE ikiongezeka (ikilinganishwa na 'poll'
/// iliyopita), tunaonyesha 'toast' (Get.snackbar) - Admin anajua PAPO
/// HAPO kuna kitu kipya, bila kuhitaji kufungua ukurasa husika kwanza.
class AdminBadgesController extends GetxController {
  final ApiClient _api;
  AdminBadgesController(this._api);

  final unreadMessages = 0.obs;
  final newMembers7d = 0.obs;
  final pendingLeadership = 0.obs;
  final pendingReports = 0.obs;
  final pendingOpportunities = 0.obs;

  Timer? _timer;
  bool _isFirstLoad = true; // usionyeshe 'toast' mara ya kwanza app inapoanza

  @override
  void onInit() {
    super.onInit();
    refresh_();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => refresh_());
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  Future<void> refresh_() async {
    try {
      final data = await _api.get('/api/admin/dashboard/badges') as Map;
      final newUnreadMessages = data['unread_messages'] as int;
      final newNewMembers7d = data['new_members_7d'] as int;
      final newPendingLeadership = data['pending_leadership'] as int;
      final newPendingReports = data['pending_reports'] as int;
      final newPendingOpportunities = data['pending_opportunities'] as int;

      if (!_isFirstLoad) {
        _popIfIncreased('Ujumbe Mpya', 'Umepokea ujumbe mpya kutoka kwa Mwanachama.', unreadMessages.value, newUnreadMessages, Icons.mail_outline);
        _popIfIncreased('Mwanachama Mpya', 'Mwanachama mpya amejiunga.', newMembers7d.value, newNewMembers7d, Icons.person_add_alt_1_outlined);
        _popIfIncreased('Uongozi Unaosubiri', 'Nafasi mpya ya uongozi inasubiri uthibitisho.', pendingLeadership.value, newPendingLeadership, Icons.emoji_events_outlined);
        _popIfIncreased('Ripoti Mpya', 'Ripoti mpya ya Forum imepokelewa.', pendingReports.value, newPendingReports, Icons.flag_outlined);
        _popIfIncreased('Fursa Inasubiri', 'Fursa mpya ya Mwanachama inasubiri idhini.', pendingOpportunities.value, newPendingOpportunities, Icons.work_outline);
      }

      unreadMessages.value = newUnreadMessages;
      newMembers7d.value = newNewMembers7d;
      pendingLeadership.value = newPendingLeadership;
      pendingReports.value = newPendingReports;
      pendingOpportunities.value = newPendingOpportunities;
      _isFirstLoad = false;
    } catch (_) {
      // si hatari kubwa - itajaribu tena baada ya sekunde 15
    }
  }

  void _popIfIncreased(String title, String message, int oldValue, int newValue, IconData icon) {
    if (newValue > oldValue) {
      Get.snackbar(
        title,
        message,
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFF008A3B),
        colorText: Colors.white,
        icon: Icon(icon, color: Colors.white),
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 5),
      );
    }
  }
}
