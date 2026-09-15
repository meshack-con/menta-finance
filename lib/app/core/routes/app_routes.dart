/// Majina ya routes zote za app - moduli mpya zinaongeza route yake hapa.
class AppRoutes {
  AppRoutes._();

  static const login = '/login';
  static const dashboard = '/dashboard';

  static const rulerList = '/rulers';
  static const msajiliDashboard = '/msajili-dashboard';
  // Ukurasa RASMI wa "Income" (angalia income_view.dart) - CHANZO cha
  // takwimu ni Backend (/api/income), SIYO 'msajiliDashboard' (hiyo ni
  // dashibodi TOFAUTI kabisa, ya role "MSAJILI" - Wanachama, siyo Income).
  static const income = '/income';
  static const expenses = '/expenses';

  static const regions = '/maeneo/regions';
  static const branches = '/maeneo/branches';
  static const educationLevels = '/elimu/levels';
  static const educationPrograms = '/elimu/programs';
  static const institutes = '/taasisi';
  static const titles = '/uongozi/titles';
  static const activities = '/shughuli';

  static const users = '/watumiaji';
  static const loginHistory = '/historia-login';
  static const leadership = '/uongozi/nafasi';
  static const settings = '/mipangilio';
  static const auditTrail = '/audit-trail';
  static const forumCategories = '/forum/categories';
  static const forumModeration = '/forum/moderation';
  static const forumContent = '/forum/content';
  // Ukurasa wa "Performance ya Projects Zote" - unafikiwa TU kupitia
  // kitufe cha "Tazama Zote" kwenye Dashboard (Performance card).
  // KUSUDI: haipaswi kuonekana kwenye Sidebar (angalia app_sidebar.dart),
  // hivyo route hii HAIJAONGEZWA humo kwa makusudi.
  static const projectsPerformance = '/projects/performance';
  // Ukurasa wa "Taarifa Kamili za Client" (client + projects zake zote,
  // jumla ya paid/outstanding na % ya Total Income). Unafikiwa TU kupitia
  // kitufe cha "Tazama" kwenye orodha ya Clients (ruler_list_view.dart).
  // KUSUDI: haipaswi kuonekana kwenye Sidebar (angalia app_sidebar.dart),
  // hivyo route hii HAIJAONGEZWA humo kwa makusudi - inapokelewa client id
  // kupitia Get.arguments (String).
  static const clientDetail = '/clients/detail';
  static const settingsHub = '/usanidi';
  static const reports = '/ripoti';
  static const adminMessages = '/ujumbe';
  static const conversations = '/mazungumzo';
  static const adminNotifications = '/admin-notifications';
  static const leadershipVerification = '/uongozi/uthibitisho';
  static const documentTypes = '/nyaraka/aina';
  static const wadau = '/wadau';

  // Zitakazoongezwa kwenye moduli zijazo (Member Detail, n.k.):
}
