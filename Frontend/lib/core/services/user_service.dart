class UserService {
  static int? userId;
  static String firstName = 'User';
  static String? email;
  static String? phone;
  static double salary = 30000.0; // Default salary

  static void logout() {
    userId = null;
    firstName = 'User';
    email = null;
    phone = null;
    salary = 30000.0;
  }
}
