class UserAddress {
  final String id;
  final String type;
  final String tag;
  final String houseNo;
  final String village;
  final String street;
  final String locality;
  final String city;
  final String state;
  final String country;
  final String zipCode;

  UserAddress({
    this.id = '',
    required this.type,
    required this.tag,
    required this.houseNo,
    required this.village,
    required this.street,
    required this.locality,
    required this.city,
    required this.state,
    required this.country,
    required this.zipCode,
  });

  factory UserAddress.fromJson(Map<String, dynamic> json) {
    return UserAddress(
      id: json['user_address_id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'D',
      tag: json['tag']?.toString() ?? '',
      houseNo: json['house_no']?.toString() ?? json['house']?.toString() ?? '',
      village: json['village']?.toString() ?? '',
      street: json['street']?.toString() ?? '',
      locality: json['locality']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      zipCode: json['zip_code']?.toString() ?? json['zipcode']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'tag': tag,
      'house_no': houseNo,
      'house': houseNo, // redundant but often used in these APIs
      'village': village,
      'street': street,
      'locality': locality,
      'city': city,
      'state': state,
      'country': country,
      'zip_code': zipCode,
      'zipcode': zipCode, // redundant for compatibility
    };
  }
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAddress &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          tag == other.tag &&
          houseNo == other.houseNo &&
          zipCode == other.zipCode;

  @override
  int get hashCode => id.hashCode ^ tag.hashCode ^ houseNo.hashCode ^ zipCode.hashCode;
}
