import 'package:get/get.dart';

/// Inahifadhi ni makundi (groups) gani ya Sidebar yamefunguliwa (Wanachama,
/// Uongozi, Maeneo, Elimu), ILI isipotee unapobadilisha ukurasa.
///
/// Kabla ya hii, hali ya "imefunguliwa" ilikuwa ikiishi ndani ya State ya
/// AppSidebar - na kwa sababu Sidebar inatengenezwa upya kila unapohama
/// ukurasa (route mpya = AppShell mpya = AppSidebar mpya), kundi lililokuwa
/// wazi lilikuwa "linajifunga" kila mara. Sasa hali hii inaishi hapa
/// (imesajiliwa permanent = true kwenye main.dart), hivyo inadumu.
class SidebarStateController extends GetxController {
  final RxSet<String> expandedGroups = <String>{}.obs;

  void toggle(String groupLabel) {
    if (expandedGroups.contains(groupLabel)) {
      expandedGroups.remove(groupLabel);
    } else {
      expandedGroups.add(groupLabel);
    }
  }
}
