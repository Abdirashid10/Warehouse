class CreateUserInput {
  const CreateUserInput({
    required this.username,
    required this.email,
    required this.password,
    required this.role,
  });

  final String username;
  final String email;
  final String password;
  final String role;

  Map<String, dynamic> toJson() => {
        'username': username.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
        'role': role,
      };
}
