class PendingPositionModel {
  final int id;
  final int rulerId;
  final int leadershipId;
  final int regionId;
  final String? startDate;
  final String? endDate;
  final bool isVerified;

  PendingPositionModel({
    required this.id,
    required this.rulerId,
    required this.leadershipId,
    required this.regionId,
    this.startDate,
    this.endDate,
    required this.isVerified,
  });

  factory PendingPositionModel.fromJson(Map<String, dynamic> j) {
    return PendingPositionModel(
      id: j['id'] as int,
      rulerId: j['ruler_id'] as int,
      leadershipId: j['leadership_id'] as int,
      regionId: j['region_id'] as int,
      startDate: j['start_date'] as String?,
      endDate: j['end_date'] as String?,
      isVerified: j['is_verified'] as bool? ?? false,
    );
  }
}
