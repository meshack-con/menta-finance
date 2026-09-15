class DashboardSummaryModel {
  final int totalRulers;
  final int totalLeaders;
  final int totalMembers;
  final int totalRegions;
  final int totalBranches;
  final int totalLocations;
  final int totalUsers;

  DashboardSummaryModel({
    required this.totalRulers,
    required this.totalLeaders,
    required this.totalMembers,
    required this.totalRegions,
    required this.totalBranches,
    required this.totalLocations,
    required this.totalUsers,
  });

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    return DashboardSummaryModel(
      totalRulers: json['total_rulers'] ?? 0,
      totalLeaders: json['total_leaders'] ?? 0,
      totalMembers: json['total_members'] ?? 0,
      totalRegions: json['total_regions'] ?? 0,
      totalBranches: json['total_branches'] ?? 0,
      totalLocations: json['total_locations'] ?? 0,
      totalUsers: json['total_users'] ?? 0,
    );
  }

  double get leaderPercent => totalRulers == 0 ? 0 : (totalLeaders / totalRulers) * 100;
}
