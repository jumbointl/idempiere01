class UserModel {
  String name;
  String email;
  String phone;
  String dob;
  String gender;
  String address;
  String country;

  UserModel({
    required this.name,
    required this.email,
    required this.phone,
    required this.dob,
    required this.address,
    required this.gender,
    required this.country,
  });
}

final UserModel user = UserModel(
  name: 'John Doe',
  email: 'john@example.com',
  phone: '+1 123 456 7890',
  dob: 'January 1, 1990',
  gender: 'Male',
  address: '123 Main Street, New York, NY',
  country: 'USA',
);
