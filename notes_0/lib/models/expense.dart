class Expense {
  final String id;
  final String description;
  final double quantity;
  final String unit;
  final double unitPrice;
  final DateTime purchasedAt;
  final DateTime createdAt;

  Expense({
    required this.id,
    required this.description,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.purchasedAt,
    required this.createdAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      description: json['description'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String,
      unitPrice: (json['unit_price'] as num).toDouble(),
      purchasedAt: DateTime.parse(json['purchased_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  double get totalPrice => quantity * unitPrice;

  String get formattedTotal => '\$${totalPrice.toStringAsFixed(2)}';

  String get formattedUnitPrice => '\$${unitPrice.toStringAsFixed(2)}';

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(purchasedAt);

    if (difference.inDays < 1) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${purchasedAt.day}/${purchasedAt.month}/${purchasedAt.year}';
    }
  }
}

class PaginatedExpenses {
  final List<Expense> data;
  final int page;
  final int perPage;
  final int total;
  final int totalPages;

  PaginatedExpenses({
    required this.data,
    required this.page,
    required this.perPage,
    required this.total,
    required this.totalPages,
  });

  factory PaginatedExpenses.fromJson(Map<String, dynamic> json) {
    return PaginatedExpenses(
      data: (json['data'] as List<dynamic>)
          .map((item) => Expense.fromJson(item as Map<String, dynamic>))
          .toList(),
      page: json['page'] as int,
      perPage: json['per_page'] as int,
      total: json['total'] as int,
      totalPages: json['total_pages'] as int,
    );
  }

  bool get hasNextPage => page < totalPages;
  bool get hasPreviousPage => page > 1;
}
