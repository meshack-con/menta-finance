import 'dart:async';

import 'package:get/get.dart';

import '../network/api_client.dart';

/// Controller ya PERMANENT inayoangalia mara kwa mara (polling - kila
/// sekunde 10) idadi ya ujumbe mapya (ambayo Admin hajayasoma) kwenye
/// Mazungumzo - kwa ajili ya 'badge' kwenye Sidebar. Admin (Flutter Web)
/// haina WebSocket ya kudumu kama Mobile, kwa hiyo 'polling' rahisi
/// ndiyo njia ya kuaminika zaidi ya 'karibu-real-time'.
class ConversationsBadgeController extends GetxController {
  final ApiClient _api;
  ConversationsBadgeController(this._api);

  final unreadTotal = 0.obs;
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    refresh_();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => refresh_());
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  Future<void> refresh_() async {
    try {
      final data = await _api.get('/api/admin/messages/unread-total');
      unreadTotal.value = (data as Map)['total'] as int;
    } catch (_) {
      // si hatari kubwa - itajaribu tena baada ya sekunde 10
    }
  }
}
