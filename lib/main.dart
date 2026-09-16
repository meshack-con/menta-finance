import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app/core/config/app_config.dart';
import 'app/core/controllers/admin_badges_controller.dart';
import 'app/core/controllers/sidebar_state_controller.dart';
import 'app/core/controllers/theme_controller.dart';
import 'app/core/data/client_project_store.dart';
import 'app/core/network/api_client.dart';
import 'app/core/routes/app_pages.dart';
import 'app/core/routes/app_routes.dart';
import 'app/core/storage/storage_service.dart';
import 'app/core/theme/app_theme.dart';
import 'app/core/translations/app_translations.dart';
import 'app/modules/expenses/expenses_store.dart';
import 'app/modules/income/income_store.dart';
import 'app/modules/reports/reports_store.dart';
import 'app/modules/stakeholders/services_store.dart';

/// KWA NINI HII IPO: Kwa default, Flutter (release mode) ikikutana na
/// hitilafu wakati wa "build" ya widget yoyote, inaficha ujumbe wa hitilafu
/// na kuonyesha BOX TUPU YA KIJIVU tu (ndiyo chanzo cha "blank gray box"
/// zilizoonekana kwenye ukurasa wa Reports). Override hii inahakikisha
/// tunaona UJUMBE HALISI wa tatizo (kwa maandishi mekundu, si kijivu tupu),
/// ili iwe rahisi kutambua na kurekebisha haraka - badala ya kukisia.
void _installFriendlyErrorWidget() {
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: const Color(0xFFFDECEA),
      alignment: Alignment.centerLeft,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.error_outline, color: Color(0xFFD32F2F), size: 18),
              SizedBox(width: 8),
              Text(
                'Sehemu hii imeshindwa kuonyesha (hitilafu ya UI)',
                style: TextStyle(color: Color(0xFFD32F2F), fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            details.exceptionAsString(),
            style: const TextStyle(color: Color(0xFFD32F2F), fontSize: 11.5),
          ),
        ],
      ),
    );
  };
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _installFriendlyErrorWidget();

  // 1) Local storage (GetStorage) - lazima i-init kabla ya kuitumia
  await StorageService.init();
  final storageService = StorageService();

  // 2) Dependency Injection ya jumla (GetX) - vitu vinavyotumika app nzima
  Get.put<StorageService>(storageService, permanent: true);
  Get.put<ApiClient>(ApiClient(storage: storageService), permanent: true);
  Get.put<ClientProjectStore>(ClientProjectStore(Get.find<ApiClient>()), permanent: true);
  Get.put<ExpensesStore>(ExpensesStore(Get.find<ApiClient>()), permanent: true);
  Get.put<IncomeStore>(IncomeStore(Get.find<ApiClient>()), permanent: true);
  Get.put<ServicesStore>(ServicesStore(Get.find<ApiClient>()), permanent: true);
  Get.put<ReportsStore>(
    ReportsStore(
      Get.find<ApiClient>(),
      incomeStore: Get.find<IncomeStore>(),
      expensesStore: Get.find<ExpensesStore>(),
      clientProjectStore: Get.find<ClientProjectStore>(),
      servicesStore: Get.find<ServicesStore>(),
    ),
    permanent: true,
  );
  Get.put<SidebarStateController>(SidebarStateController(), permanent: true);
  Get.put<AdminBadgesController>(AdminBadgesController(Get.find<ApiClient>()), permanent: true);
  final themeController = Get.put<ThemeController>(ThemeController(storageService), permanent: true);

  runApp(UmisAdminApp(themeController: themeController));
}

class UmisAdminApp extends StatelessWidget {
  final ThemeController themeController;
  const UmisAdminApp({super.key, required this.themeController});

  @override
  Widget build(BuildContext context) {
    final storage = Get.find<StorageService>();

    return GetMaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeController.themeMode.value,
      translations: AppTranslations(),
      locale: const Locale('sw', 'TZ'),
      fallbackLocale: const Locale('sw', 'TZ'),
      initialRoute: storage.isLoggedIn ? AppRoutes.dashboard : AppRoutes.login,
      getPages: AppPages.routes,
      // Admin Panel ni web dashboard - kubadilisha ukurasa kunapaswa
      // kuwa PAPO HAPO (kama Gmail/Notion), siyo "kuanimishwa" (fade/slide).
      // Bila hii, GetX inaanimisha UKURASA MZIMA (Sidebar+Topbar ikiwemo)
      // kila unapobofya kipengele cha menu, na kwa sababu Sidebar
      // inajengwa upya kila wakati, matokeo yake ni "ghosting"/kutikisika
      // kwa muda mfupi (frame mbili zinachanganyika) - ndiyo "kusheki"
      // kulikoonekana kwenye video.
      defaultTransition: Transition.noTransition,
      transitionDuration: Duration.zero,
    );
  }
}
