class StakeholderModel {
  final int? id;
  final String name;
  final String kind; // BINAFSI | TAASISI
  final String? phoneNumber;
  final String? emailAddress;
  final String? address;
  final String? contactPerson;
  final String? notes;
  final bool isBlocked;

  StakeholderModel({
    this.id,
    required this.name,
    required this.kind,
    this.phoneNumber,
    this.emailAddress,
    this.address,
    this.contactPerson,
    this.notes,
    this.isBlocked = false,
  });

  factory StakeholderModel.fromJson(Map<String, dynamic> j) {
    return StakeholderModel(
      id: j['id'] as int?,
      name: j['name'] as String? ?? '',
      kind: j['kind'] as String? ?? 'BINAFSI',
      phoneNumber: j['phone_number'] as String?,
      emailAddress: j['email_address'] as String?,
      address: j['address'] as String?,
      contactPerson: j['contact_person'] as String?,
      notes: j['notes'] as String?,
      isBlocked: j['is_blocked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'kind': kind,
        'phone_number': phoneNumber,
        'email_address': emailAddress,
        'address': address,
        'contact_person': contactPerson,
        'notes': notes,
      };
}
