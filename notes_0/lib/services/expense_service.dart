import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/expense.dart';

class ExpenseService {
  static ExpenseService? _instance;

  factory ExpenseService() {
    _instance ??= ExpenseService._internal();
    return _instance!;
  }

  ExpenseService._internal();

  Future<PaginatedExpenses> getExpenses({
    required String apiEndpoint,
    int page = 1,
    int perPage = 20,
    String orderBy = 'purchased_at',
    String orderDir = 'desc',
  }) async {
    if (apiEndpoint.isEmpty) {
      throw Exception('API endpoint not configured');
    }

    // Ensure endpoint has base URL without /upload
    final baseUrl = apiEndpoint.replaceAll('/upload', '');

    // Build query parameters
    final queryParams = {
      'page': page.toString(),
      'per_page': perPage.toString(),
      'order[by]': orderBy,
      'order[dir]': orderDir,
    };

    final uri = Uri.parse('$baseUrl/expenses').replace(queryParameters: queryParams);

    try {
      final response = await http.get(uri).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        return PaginatedExpenses.fromJson(jsonData);
      } else {
        throw Exception('Failed to load expenses: HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching expenses: $e');
      rethrow;
    }
  }
}
