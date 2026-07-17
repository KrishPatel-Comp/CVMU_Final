import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static final String baseUrl = 'https://rupee-lens-v2.loca.lt';

  final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 3),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Bypass-Tunnel-Reminder': 'true',
    },
  ));

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Auth Methods
  Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String pin,
    required String userType,
    int? monthlyBudget,
    int? salary,
  }) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone': phone,
        'pin': pin,
        'user_type': userType,
        'monthly_budget': monthlyBudget,
        'salary': salary,
      });
      return response.data;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> login(String email, String pin) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'pin': pin,
      });
      return response.data;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> sendOtp(String email) async {
    try {
      final response = await _dio.post('/auth/send-otp', queryParameters: {'email': email});
      return response.data;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    try {
      final response = await _dio.post('/auth/verify-otp', queryParameters: {
        'email': email,
        'otp': otp,
      });
      return response.data;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> createTransaction({
    required int userId,
    required double amount,
    required String merchantName,
    String? category,
    String? note,
    String? rawSms,
  }) async {
    try {
      final response = await _dio.post('/transactions/', data: {
        'user_id': userId,
        'amount': amount,
        'merchant_name': merchantName,
        'category': category,
        'note': note,
        'raw_sms': rawSms,
      });
      return response.data;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateTransaction({
    required String transactionId,
    String? category,
    String? note,
    double? amount,
    String? merchantName,
  }) async {
    try {
      final response = await _dio.put('/transactions/$transactionId', data: {
        'category': category,
        'note': note,
        'amount': amount,
        'merchant_name': merchantName,
      });
      return response.data;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> deleteTransaction(String transactionId) async {
    try {
      final response = await _dio.delete('/transactions/$transactionId');
      return response.data;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<List<dynamic>> getTransactions(int userId) async {
    try {
      final response = await _dio.get('/transactions/', queryParameters: {'user_id': userId});
      return response.data;
    } catch (e) {
      debugPrint('Error fetching transactions: $e');
      return [];
    }
  }

  // Analytics Methods
  Future<Map<String, dynamic>> getMonthlySummary(int userId) async {
    try {
      final response = await _dio.get('/analytics/monthly-summary', queryParameters: {'user_id': userId});
      return response.data;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getMonthlyComparison(int userId) async {
    try {
      final response = await _dio.get('/analytics/monthly-comparison', queryParameters: {'user_id': userId});
      return response.data;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<List<dynamic>> getTopCategories(int userId) async {
    try {
      final response = await _dio.get('/analytics/top-categories', queryParameters: {'user_id': userId});
      return response.data;
    } catch (e) {
      debugPrint('Error fetching top categories: $e');
      return [];
    }
  }

  Future<List<dynamic>> getRecentTransactions(int userId) async {
    try {
      final response = await _dio.get('/analytics/recent-transactions', queryParameters: {'user_id': userId});
      return response.data;
    } catch (e) {
      debugPrint('Error fetching recent transactions: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getBudgetWarnings(int userId) async {
    try {
      final response = await _dio.get('/analytics/budget-warning', queryParameters: {'user_id': userId});
      return response.data;
    } catch (e) {
      return _handleError(e);
    }
  }

  Map<String, dynamic> _handleError(dynamic e) {
    if (e is DioException) {
      final message = e.response?.data?['detail'] ?? e.message ?? 'Unknown error occurred';
      return {'error': message};
    }
    return {'error': e.toString()};
  }
}
