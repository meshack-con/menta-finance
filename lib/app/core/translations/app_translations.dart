import 'package:get/get.dart';

/// Maandishi ya Admin Panel (Kiswahili TU - hakuna lugha nyingine).
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'sw_TZ': _sw,
      };

  static const _sw = {
    // Sidebar
    'sb_dashboard': 'Dashboard',
    'sb_projects': 'Projects',
    'sb_clients': 'Clients',
    'sb_income': 'Income',
    'sb_expenses': 'Expenses',
    'sb_services': 'Services',
    'sb_team': 'Team',
    'sb_registration_group': 'Usajili',
    'sb_msajili_dashboard': 'Dashibodi ya Msajili',
    'sb_rulers': 'Wanachama',
    'sb_leadership_verification': 'Uthibitisho wa Uongozi',
    'sb_wadau': 'Wadau',
    'sb_msajili_reports': 'Ripoti za Usajili',
    'sb_settings_group': 'Mipangilio',
    'sb_settings_hub': 'Usanidi wa Mfumo',
    'sb_reports_group': 'Ripoti',
    'sb_reports': 'Reports',
    'sb_messages_group': 'Mawasiliano',
    'sb_admin_messages': 'Ujumbe kwa Wanachama',
    'sb_conversations': 'Mazungumzo',
    'sb_admin_notifications': 'Arifa',
    'sb_users': 'Watumiaji wa Mfumo',
    'sb_login_history': 'Historia ya Login',
    'sb_audit_trail': 'Audit Trail',
    'sb_forum': 'Forum',
    'sb_forum_content': 'Mada na Fursa',
    'sb_forum_categories': 'Kategoria',
    'sb_forum_moderation': 'Uthibiti (Ripoti)',
    'sb_settings': 'Mipangilio',

    // Vitufe vya kawaida
    'save': 'Hifadhi',
    'cancel': 'Ghairi',
    'search': 'Tafuta',
    'edit': 'Hariri',
    'delete': 'Futa',
    'add': 'Ongeza',
    'confirm': 'Thibitisha',
    'loading': 'Inapakia...',
    'retry': 'Jaribu tena',
    'logout': 'Toka',
    'submit': 'Wasilisha',
    'close': 'Funga',

    // Mipangilio - theme
    'appearance': 'Mwonekano',
    'dark_mode': 'Giza (Dark Mode)',
    'light_mode': 'Mwanga (Light Mode)',
  };
}
