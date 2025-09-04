class UserModel {
final String id;
final String fullName;
final String phone;
bool approved;


UserModel({
required this.id,
required this.fullName,
required this.phone,
this.approved = false,
});
}