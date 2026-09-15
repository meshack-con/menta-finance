import 'package:intl/intl.dart';

final _dateFmt = DateFormat('yyyy-MM-dd');

DateTime? _parseDate(dynamic v) => (v == null || v == '') ? null : DateTime.tryParse(v as String);
String? _formatDate(DateTime? d) => d == null ? null : _dateFmt.format(d);

class RulerModel {
  final int? id;

  final String? membershipCode;
  final String? username;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String? otherName;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? placeOfBirth;
  final DateTime? registrationDate;
  final String? phoneNumber;
  final String? disabilityInfo;
  final String? identificationType;
  final String? emailAddress;

  final String? identificationNumber;
  final String? voterId;
  final String? maritalStatus;
  final String? occupation;
  final int? occupationId; // Fani
  final int? occupationTypeId; // Aina ya Kazi
  final String? placeIssued;

  final String? uwtCardNo;
  final DateTime? uwtCardNoDateIssued;
  final String? uvccmCardNo;
  final DateTime? uvccmCardNoDateIssued;
  final String? uvccmCardNoPlaceIssued;
  final String? wazaziCardNo;
  final DateTime? wazaziCardNoDateIssued;
  final String? wazaziCardNoPlaceIssued;

  final String? memberPhoto;
  final String? memberSignature;

  final int? instituteId;
  final int? regionId;
  final String? membershipStatus; // MUHITIMU | MWANACHUO | DIASPORA
  final DateTime? courseStartDate;
  final DateTime? courseEndDate;
  final String? courseDuration;

  // Server-computed - hazitumwi kwenye create/update
  final bool isBlocked;
  final bool isLeader;
  final String leadershipStatus;
  final String? currentPositionTitle; // Nafasi/Cheo cha sasa
  final String? regionName; // Mkoa
  final String? instituteName; // Tawi
  final String? registeredByType; // SELF | ADMIN | MSAJILI
  final String? registeredByName; // Jina la Admin/Msajili aliyesajili
  final bool hasLoginAccount;
  final String? defaultPassword; // inarudi MARA MOJA TU wakati wa create/update

  RulerModel({
    this.id,
    this.membershipCode,
    this.username,
    required this.firstName,
    this.middleName,
    required this.lastName,
    this.otherName,
    this.gender,
    this.dateOfBirth,
    this.placeOfBirth,
    this.registrationDate,
    this.phoneNumber,
    this.disabilityInfo,
    this.identificationType,
    this.emailAddress,
    this.identificationNumber,
    this.voterId,
    this.maritalStatus,
    this.occupation,
    this.occupationId,
    this.occupationTypeId,
    this.placeIssued,
    this.uwtCardNo,
    this.uwtCardNoDateIssued,
    this.uvccmCardNo,
    this.uvccmCardNoDateIssued,
    this.uvccmCardNoPlaceIssued,
    this.wazaziCardNo,
    this.wazaziCardNoDateIssued,
    this.wazaziCardNoPlaceIssued,
    this.memberPhoto,
    this.memberSignature,
    this.instituteId,
    this.regionId,
    this.membershipStatus,
    this.courseStartDate,
    this.courseEndDate,
    this.courseDuration,
    this.isBlocked = false,
    this.isLeader = false,
    this.leadershipStatus = 'Mwanachama wa Kawaida',
    this.currentPositionTitle,
    this.regionName,
    this.instituteName,
    this.registeredByType,
    this.registeredByName,
    this.hasLoginAccount = false,
    this.defaultPassword,
  });

  factory RulerModel.fromJson(Map<String, dynamic> j) {
    return RulerModel(
      id: j['id'] as int?,
      membershipCode: j['membership_code'],
      username: j['username'],
      firstName: j['first_name'] ?? '',
      middleName: j['middle_name'],
      lastName: j['last_name'] ?? '',
      otherName: j['other_name'],
      gender: j['gender'],
      dateOfBirth: _parseDate(j['date_of_birth']),
      placeOfBirth: j['place_of_birth'],
      registrationDate: _parseDate(j['registration_date']),
      phoneNumber: j['phone_number'],
      disabilityInfo: j['disability_info'],
      identificationType: j['identification_type'],
      emailAddress: j['email_address'],
      identificationNumber: j['identification_number'],
      voterId: j['voter_id'],
      maritalStatus: j['marital_status'],
      occupation: j['occupation'],
      occupationId: j['occupation_id'],
      occupationTypeId: j['occupation_type_id'],
      placeIssued: j['place_issued'],
      uwtCardNo: j['uwt_card_no'],
      uwtCardNoDateIssued: _parseDate(j['uwt_card_no_date_issued']),
      uvccmCardNo: j['uvccm_card_no'],
      uvccmCardNoDateIssued: _parseDate(j['uvccm_card_no_date_issued']),
      uvccmCardNoPlaceIssued: j['uvccm_card_no_place_issued'],
      wazaziCardNo: j['wazazi_card_no'],
      wazaziCardNoDateIssued: _parseDate(j['wazazi_card_no_date_issued']),
      wazaziCardNoPlaceIssued: j['wazazi_card_no_place_issued'],
      memberPhoto: j['member_photo'],
      memberSignature: j['member_signature'],
      instituteId: j['institute_id'],
      regionId: j['region_id'],
      membershipStatus: j['membership_status'],
      courseStartDate: _parseDate(j['course_start_date']),
      courseEndDate: _parseDate(j['course_end_date']),
      courseDuration: j['course_duration'],
      isBlocked: j['is_blocked'] ?? false,
      isLeader: j['is_leader'] ?? false,
      leadershipStatus: j['leadership_status'] ?? 'Mwanachama wa Kawaida',
      currentPositionTitle: j['current_position_title'],
      regionName: j['region_name'],
      instituteName: j['institute_name'],
      registeredByType: j['registered_by_type'],
      registeredByName: j['registered_by_name'],
      hasLoginAccount: j['has_login_account'] ?? false,
      defaultPassword: j['default_password'],
    );
  }

  /// Kwa POST (create) / PUT (update) - haitumi fields za server-computed
  Map<String, dynamic> toJson() => {
        'membership_code': membershipCode,
        'first_name': firstName,
        'middle_name': middleName,
        'last_name': lastName,
        'other_name': otherName,
        'gender': gender,
        'date_of_birth': _formatDate(dateOfBirth),
        'place_of_birth': placeOfBirth,
        'registration_date': _formatDate(registrationDate),
        'phone_number': phoneNumber,
        'disability_info': disabilityInfo,
        'identification_type': identificationType,
        'email_address': emailAddress,
        'identification_number': identificationNumber,
        'voter_id': voterId,
        'marital_status': maritalStatus,
        'occupation': occupation,
        'occupation_id': occupationId,
        'occupation_type_id': occupationTypeId,
        'place_issued': placeIssued,
        'uwt_card_no': uwtCardNo,
        'uwt_card_no_date_issued': _formatDate(uwtCardNoDateIssued),
        'uvccm_card_no': uvccmCardNo,
        'uvccm_card_no_date_issued': _formatDate(uvccmCardNoDateIssued),
        'uvccm_card_no_place_issued': uvccmCardNoPlaceIssued,
        'wazazi_card_no': wazaziCardNo,
        'wazazi_card_no_date_issued': _formatDate(wazaziCardNoDateIssued),
        'wazazi_card_no_place_issued': wazaziCardNoPlaceIssued,
        'member_photo': memberPhoto,
        'member_signature': memberSignature,
        'institute_id': instituteId,
        'region_id': regionId,
        'membership_status': membershipStatus,
        'course_start_date': _formatDate(courseStartDate),
        'course_end_date': _formatDate(courseEndDate),
        'course_duration': courseDuration,
      }..removeWhere((k, v) => v == null);

  String get fullName => [firstName, middleName, lastName].where((e) => (e ?? '').isNotEmpty).join(' ');

  /// Muhtasari wa "Alisajiliwa Na" - kwa ajili ya kuonyesha kwenye Profile.
  String get registeredByLabel {
    switch (registeredByType) {
      case 'SELF':
        return 'Mwenyewe (kupitia Mobile App)';
      case 'ADMIN':
        return registeredByName != null ? 'Admin - $registeredByName' : 'Admin';
      case 'MSAJILI':
        return registeredByName != null ? 'Msajili - $registeredByName' : 'Msajili';
      default:
        return 'Haijulikani (data ya zamani)';
    }
  }

  RulerModel copyWith({
    String? membershipCode,
    String? firstName,
    String? middleName,
    String? lastName,
    String? otherName,
    String? gender,
    DateTime? dateOfBirth,
    String? placeOfBirth,
    DateTime? registrationDate,
    String? phoneNumber,
    String? disabilityInfo,
    String? identificationType,
    String? emailAddress,
    String? identificationNumber,
    String? voterId,
    String? maritalStatus,
    String? occupation,
    int? occupationId,
    int? occupationTypeId,
    String? placeIssued,
    String? uwtCardNo,
    DateTime? uwtCardNoDateIssued,
    String? uvccmCardNo,
    DateTime? uvccmCardNoDateIssued,
    String? uvccmCardNoPlaceIssued,
    String? wazaziCardNo,
    DateTime? wazaziCardNoDateIssued,
    String? wazaziCardNoPlaceIssued,
    String? memberPhoto,
    String? memberSignature,
    int? instituteId,
    int? regionId,
    String? membershipStatus,
    DateTime? courseStartDate,
    DateTime? courseEndDate,
    String? courseDuration,
  }) {
    return RulerModel(
      id: id,
      membershipCode: membershipCode ?? this.membershipCode,
      username: this.username,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      otherName: otherName ?? this.otherName,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      placeOfBirth: placeOfBirth ?? this.placeOfBirth,
      registrationDate: registrationDate ?? this.registrationDate,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      disabilityInfo: disabilityInfo ?? this.disabilityInfo,
      identificationType: identificationType ?? this.identificationType,
      emailAddress: emailAddress ?? this.emailAddress,
      identificationNumber: identificationNumber ?? this.identificationNumber,
      voterId: voterId ?? this.voterId,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      occupation: occupation ?? this.occupation,
      occupationId: occupationId ?? this.occupationId,
      occupationTypeId: occupationTypeId ?? this.occupationTypeId,
      placeIssued: placeIssued ?? this.placeIssued,
      uwtCardNo: uwtCardNo ?? this.uwtCardNo,
      uwtCardNoDateIssued: uwtCardNoDateIssued ?? this.uwtCardNoDateIssued,
      uvccmCardNo: uvccmCardNo ?? this.uvccmCardNo,
      uvccmCardNoDateIssued: uvccmCardNoDateIssued ?? this.uvccmCardNoDateIssued,
      uvccmCardNoPlaceIssued: uvccmCardNoPlaceIssued ?? this.uvccmCardNoPlaceIssued,
      wazaziCardNo: wazaziCardNo ?? this.wazaziCardNo,
      wazaziCardNoDateIssued: wazaziCardNoDateIssued ?? this.wazaziCardNoDateIssued,
      wazaziCardNoPlaceIssued: wazaziCardNoPlaceIssued ?? this.wazaziCardNoPlaceIssued,
      memberPhoto: memberPhoto ?? this.memberPhoto,
      memberSignature: memberSignature ?? this.memberSignature,
      instituteId: instituteId ?? this.instituteId,
      regionId: regionId ?? this.regionId,
      membershipStatus: membershipStatus ?? this.membershipStatus,
      courseStartDate: courseStartDate ?? this.courseStartDate,
      courseEndDate: courseEndDate ?? this.courseEndDate,
      courseDuration: courseDuration ?? this.courseDuration,
      isBlocked: isBlocked,
      isLeader: isLeader,
      leadershipStatus: leadershipStatus,
    );
  }
}
