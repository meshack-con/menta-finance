class AdminPositionModel {
  final int id;
  final int leadershipId;
  final int regionId;
  final int? branchId;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isVerified;

  AdminPositionModel({
    required this.id,
    required this.leadershipId,
    required this.regionId,
    this.branchId,
    this.startDate,
    this.endDate,
    required this.isVerified,
  });

  factory AdminPositionModel.fromJson(Map<String, dynamic> j) {
    return AdminPositionModel(
      id: j['id'] as int,
      leadershipId: j['leadership_id'] as int,
      regionId: j['region_id'] as int,
      branchId: j['branch_id'] as int?,
      startDate: j['start_date'] != null ? DateTime.tryParse(j['start_date'] as String) : null,
      endDate: j['end_date'] != null ? DateTime.tryParse(j['end_date'] as String) : null,
      isVerified: j['is_verified'] as bool? ?? false,
    );
  }

  /// "Sasa" (bado inaendelea) au "Historia" (imekwisha) - TU kwa nafasi
  /// zilizothibitishwa. Nafasi zisizothibitishwa zinaonekana kando (pending).
  bool get isCurrentlyOngoing => endDate == null || endDate!.isAfter(DateTime.now());
}
