import 'package:get/get.dart';

import '../../modules/auth/bindings/login_binding.dart';
import '../../modules/auth/views/login_view.dart';
import '../../modules/dashboard/bindings/dashboard_binding.dart';
import '../../modules/dashboard/views/dashboard_view.dart';
import '../../modules/expenses/views/expenses_view.dart';
import '../../modules/income/views/income_view.dart';
import '../../modules/rulers/bindings/ruler_list_binding.dart';
import '../../modules/rulers/views/ruler_list_view.dart';
import '../../modules/msajili_dashboard/views/msajili_dashboard_view.dart';
import '../../modules/lookup/bindings/lookup_binding.dart';
import '../../modules/lookup/lookup_config.dart';
import '../../modules/lookup/views/lookup_list_view.dart';
import '../../modules/users/bindings/users_binding.dart';
import '../../modules/users/views/users_view.dart';
import '../../modules/login_history/bindings/login_history_binding.dart';
import '../../modules/login_history/views/login_history_view.dart';
import '../../modules/leadership/bindings/leadership_binding.dart';
import '../../modules/leadership/views/leadership_view.dart';
import '../../modules/settings/bindings/settings_binding.dart';
import '../../modules/settings/views/settings_view.dart';
import '../../modules/audit/bindings/audit_binding.dart';
import '../../modules/audit/views/audit_view.dart';
import '../../modules/forum_categories/bindings/forum_categories_binding.dart';
import '../../modules/forum_categories/views/forum_categories_view.dart';
import '../../modules/forum_moderation/bindings/forum_moderation_binding.dart';
import '../../modules/forum_moderation/views/forum_moderation_view.dart';
import '../../modules/forum_content/bindings/forum_content_binding.dart';
import '../../modules/forum_content/views/forum_content_view.dart';
import '../../modules/project_performance/views/project_performance_view.dart';
import '../../modules/client_detail/views/client_detail_view.dart';
import '../../modules/settings_hub/views/settings_hub_view.dart';
import '../../modules/reports/views/reports_view.dart';
import '../../modules/admin_messages/views/admin_messages_view.dart';
import '../../modules/conversations/views/conversations_view.dart';
import '../../modules/admin_notifications/views/admin_notifications_view.dart';
import '../../modules/leadership_verification/bindings/leadership_verification_binding.dart';
import '../../modules/leadership_verification/views/leadership_verification_view.dart';
import '../../modules/stakeholders/views/wadau_view.dart';
import '../../modules/document_types/bindings/document_types_binding.dart';
import '../../modules/document_types/views/document_types_view.dart';
import 'app_routes.dart';

/// Orodha ya pages zote za GetX - moduli mpya inaongeza [GetPage] moja hapa.
class AppPages {
  AppPages._();

  static final routes = [
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginView(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: AppRoutes.dashboard,
      page: () => const DashboardView(),
      binding: DashboardBinding(),
    ),
    GetPage(
      name: AppRoutes.rulerList,
      page: () => const RulerListView(),
      binding: RulerListBinding(),
    ),
    GetPage(
      name: AppRoutes.msajiliDashboard,
      page: () => const MsajiliDashboardView(),
    ),
    // NB: "Ongeza/Hariri Mwanachama" siyo tena route tofauti - sasa ni
    // RulerFormDialog (modal) inayofunguliwa moja kwa moja kutoka
    // RulerListView (angalia ruler_list_view.dart) - hii inatoa design
    // bora zaidi (haifungui ukurasa mpya, inabaki juu ya orodha).

    // ---------- Moduli za "Lookup" rahisi (jina + mzazi wa hiari) ----------
    GetPage(
      name: AppRoutes.regions,
      page: () => const LookupListView(config: regionConfig),
      binding: LookupBinding(regionConfig),
    ),
    GetPage(
      name: AppRoutes.branches,
      page: () => const LookupListView(config: branchConfig),
      binding: LookupBinding(branchConfig),
    ),
    GetPage(
      name: AppRoutes.educationLevels,
      page: () => const LookupListView(config: educationLevelConfig),
      binding: LookupBinding(educationLevelConfig),
    ),
    GetPage(
      name: AppRoutes.educationPrograms,
      page: () => const LookupListView(config: educationProgramConfig),
      binding: LookupBinding(educationProgramConfig),
    ),
    GetPage(
      name: AppRoutes.institutes,
      page: () => const LookupListView(config: instituteConfig),
      binding: LookupBinding(instituteConfig),
    ),
    GetPage(
      name: AppRoutes.titles,
      page: () => const LookupListView(config: titleEntityConfig),
      binding: LookupBinding(titleEntityConfig),
    ),
    // 'AppRoutes.activities' (Shughuli) ILIONDOLEWA - jedwali hilo
    // halikuwa limeunganishwa na Ruler wala kitu kingine chochote
    // (duplication isiyo na maana dhidi ya Occupation/OccupationType).

    // ---------- Uongozi (extra fields), Watumiaji, Historia, Mipangilio ----------
    GetPage(
      name: AppRoutes.leadership,
      page: () => const LeadershipView(),
      binding: LeadershipBinding(),
    ),
    GetPage(
      name: AppRoutes.users,
      page: () => const UsersView(),
      binding: UsersBinding(),
    ),
    GetPage(
      name: AppRoutes.loginHistory,
      page: () => const LoginHistoryView(),
      binding: LoginHistoryBinding(),
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsView(),
      binding: SettingsBinding(),
    ),
    GetPage(
      name: AppRoutes.auditTrail,
      page: () => const AuditView(),
      binding: AuditBinding(),
    ),
    GetPage(
      name: AppRoutes.expenses,
      page: () => const ExpensesView(),
    ),
    GetPage(
      name: AppRoutes.income,
      page: () => const IncomeView(),
    ),
    GetPage(
      name: AppRoutes.forumCategories,
      page: () => const ForumCategoriesView(),
      binding: ForumCategoriesBinding(),
    ),
    GetPage(
      name: AppRoutes.forumModeration,
      page: () => const ForumModerationView(),
      binding: ForumModerationBinding(),
    ),
    GetPage(
      name: AppRoutes.forumContent,
      page: () => const ForumContentView(),
      binding: ForumContentBinding(),
    ),
    // NB: route hii HAIONGEZWI kwenye Sidebar (app_sidebar.dart) kwa
    // makusudi - inafikiwa TU kupitia "Tazama Zote" kwenye Performance
    // card ya Dashboard.
    GetPage(
      name: AppRoutes.projectsPerformance,
      page: () => const ProjectPerformanceView(),
    ),
    // NB: route hii HAIONGEZWI kwenye Sidebar (app_sidebar.dart) kwa
    // makusudi - inafikiwa TU kupitia kitufe cha "Tazama" kwenye orodha
    // ya Clients (ruler_list_view.dart). Client id hupitishwa kupitia
    // Get.arguments (String).
    GetPage(
      name: AppRoutes.clientDetail,
      page: () => const ClientDetailView(),
    ),
    GetPage(
      name: AppRoutes.settingsHub,
      page: () => const SettingsHubView(),
    ),
    GetPage(
      name: AppRoutes.reports,
      page: () => const ReportsView(),
    ),
    GetPage(
      name: AppRoutes.adminMessages,
      page: () => const AdminMessagesView(),
    ),
    GetPage(
      name: AppRoutes.conversations,
      page: () => const ConversationsView(),
    ),
    GetPage(
      name: AppRoutes.adminNotifications,
      page: () => const AdminNotificationsView(),
    ),
    GetPage(
      name: AppRoutes.leadershipVerification,
      page: () => const LeadershipVerificationView(),
      binding: LeadershipVerificationBinding(),
    ),
    GetPage(
      name: AppRoutes.documentTypes,
      page: () => const DocumentTypesView(),
      binding: DocumentTypesBinding(),
    ),
    GetPage(
      name: AppRoutes.wadau,
      page: () => const WadauView(),
    ),
    // Moduli inayofuata: Member Detail (tabs 7) - kwa Wanachama.
  ];
}
