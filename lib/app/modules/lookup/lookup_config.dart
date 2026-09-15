/// Maelezo ya entity moja "rahisi" - endpoint yake, jina la kuonyesha, na
/// (kama ipo) FK ya "mzazi" pamoja na config ya huyo mzazi (kwa dropdown).
class LookupConfig {
  final String title; // jina la kuonyesha kwenye topbar/menu
  final String addLabel; // jina la kitu kimoja, kwa fomu ya "Ongeza ..."
  final String endpoint; // mfano '/api/states'
  final String? parentKey; // mfano 'region_id' - null kama hakuna mzazi
  final String? parentLabel; // mfano 'State' - jina la dropdown
  final LookupConfig? parentConfig; // config ya huyo mzazi (kuvuta orodha yake)

  const LookupConfig({
    required this.title,
    required this.addLabel,
    required this.endpoint,
    this.parentKey,
    this.parentLabel,
    this.parentConfig,
  });
}

// ---------------- Maeneo (Region -> Branch, hierarchy rahisi) ----------------
const regionConfig = LookupConfig(title: 'Mikoa (Regions)', addLabel: 'Region', endpoint: '/api/regions');

const branchConfig = LookupConfig(
  title: 'Matawi (Branches)',
  addLabel: 'Branch',
  endpoint: '/api/branches',
  parentKey: 'region_id',
  parentLabel: 'Region',
  parentConfig: regionConfig,
);

// ---------------- Elimu (Tawi -> Ngazi ya Elimu -> Programu) ----------------
const educationLevelConfig = LookupConfig(
  title: 'Ngazi za Elimu (Education Levels)',
  addLabel: 'Ngazi ya Elimu',
  endpoint: '/api/education-levels',
  parentKey: 'branch_id',
  parentLabel: 'Tawi',
  parentConfig: branchConfig,
);

const educationProgramConfig = LookupConfig(
  title: 'Programu za Elimu (Education Programs)',
  addLabel: 'Programu',
  endpoint: '/api/education-programs',
  parentKey: 'education_level_id',
  parentLabel: 'Ngazi ya Elimu',
  parentConfig: educationLevelConfig,
);

// ---------------- Nyingine (hakuna mzazi) ----------------
const instituteConfig = LookupConfig(title: 'Taasisi (Institutes)', addLabel: 'Taasisi', endpoint: '/api/institutes');
const titleEntityConfig = LookupConfig(title: 'Vyeo (Titles)', addLabel: 'Cheo', endpoint: '/api/titles');
// 'activityConfig' (Shughuli) ILIONDOLEWA - jedwali hilo halikuwa
// limeunganishwa na Ruler wala kitu kingine chochote (duplication
// isiyo na maana dhidi ya Occupation/OccupationType).

// ---------------- Kazi/Utaalamu (Occupation) ----------------
const occupationConfig = LookupConfig(title: 'Fani', addLabel: 'Fani', endpoint: '/api/occupations');
const occupationTypeConfig = LookupConfig(title: 'Aina ya Kazi', addLabel: 'Aina ya Kazi', endpoint: '/api/occupation-types');
