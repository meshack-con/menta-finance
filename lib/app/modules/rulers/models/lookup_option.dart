/// Option rahisi ya dropdown (id + name) - kwa Leadership/State/Region
/// zinazotumika kwenye hatua ya "Uongozi" ya fomu ya Ruler. 'parentId'
/// (hiari) inatumika kwa Matawi - kuhifadhi Mkoa (region_id) wake, ili
/// yachujwe kulingana na Mkoa uliochaguliwa.
class LookupOption {
  final int id;
  final String name;
  final int? parentId;
  LookupOption(this.id, this.name, {this.parentId});
  factory LookupOption.fromJson(Map<String, dynamic> j, {String? parentKey}) =>
      LookupOption(j['id'] as int, j['name'] as String, parentId: parentKey != null ? j[parentKey] as int? : null);
}
