// Complete code for the Transaction model
class Transaction {
  final String? id;
  final double originalAmount;
  final String originalCurrency;
  final String description;
  final DateTime createdAt;
  final double? convertedAmount;
  final String? convertedCurrency;

  Transaction({
    this.id,
    required this.originalAmount,
    required this.originalCurrency,
    required this.description,
    required this.createdAt,
    this.convertedAmount,
    this.convertedCurrency,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    // Print the incoming JSON for debugging
    print('Parsing transaction JSON: $json');

    // Helper to safely get and cast, throwing if a required field is missing or of the wrong type.
    T getRequiredField<T>(String key, {T Function(dynamic)? convert}) {
      final value = json[key];
      if (value == null) {
        throw FormatException(
          "Missing required key \'$key\' in Transaction JSON",
        );
      }
      if (convert != null) {
        try {
          return convert(value);
        } catch (e) {
          throw FormatException("Invalid format for key \'$key\'. Error: $e");
        }
      }
      if (value is T) {
        return value;
      }
      // Attempt common numeric conversions
      if (T == double && value is int) {
        return value.toDouble() as T;
      }
      if (T == String && value is num) {
        return value.toString() as T;
      }
      throw FormatException(
        "Invalid type for key \'$key\'. Expected $T, got ${value.runtimeType}",
      );
    }

    // Helper for optional fields, returning null if missing or of an incompatible type.
    T? getOptionalField<T>(String key, {T? Function(dynamic)? convert}) {
      final value = json[key];
      if (value == null) return null;
      if (convert != null) {
        try {
          return convert(value);
        } catch (e) {
          // Print error for debugging
          print("Warning: Could not convert optional key \'$key\'. Error: $e");
          return null;
        }
      }
      if (value is T) {
        return value;
      }
      if (T == double && value is int) {
        return value.toDouble() as T?;
      }
      if (T == String && value is num) {
        return value.toString() as T?;
      }
      // Print warning for type mismatch
      print(
        "Warning: Type mismatch for optional key \'$key\'. Expected $T, got ${value.runtimeType}. Returning null.",
      );
      return null;
    }

    try {
      return Transaction(
        id: getOptionalField<String>('_id'),
        originalAmount: getRequiredField<double>(
          'originalAmount',
          convert: (v) => (v as num).toDouble(),
        ),
        originalCurrency: getRequiredField<String>('originalCurrency'),
        description: getRequiredField<String>('description'),
        createdAt: getRequiredField<DateTime>(
          'createdAt',
          convert: (v) => DateTime.parse(v as String),
        ),
        convertedAmount: getOptionalField<double>(
          'convertedAmount',
          convert: (v) => (v as num?)?.toDouble(),
        ),
        convertedCurrency: getOptionalField<String>('convertedCurrency'),
      );
    } catch (e) {
      // More robust error handling - log the error and create a fallback transaction
      print('Error creating Transaction from JSON: $e');
      try {
        // Attempt to create with minimum required fields using more flexible parsing
        return Transaction(
          id: json['_id']?.toString(),
          originalAmount: (json['originalAmount'] as num?)?.toDouble() ?? 0.0,
          originalCurrency: json['originalCurrency']?.toString() ?? 'Unknown',
          description: json['description']?.toString() ?? 'Unknown transaction',
          createdAt:
              json['createdAt'] != null
                  ? DateTime.parse(json['createdAt'].toString())
                  : DateTime.now(),
          convertedAmount: (json['convertedAmount'] as num?)?.toDouble(),
          convertedCurrency: json['convertedCurrency']?.toString(),
        );
      } catch (fallbackError) {
        print('Fallback transaction creation also failed: $fallbackError');
        throw FormatException(
          'Could not parse transaction: $e, fallback also failed: $fallbackError',
        );
      }
    }
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'originalAmount': originalAmount,
      'originalCurrency': originalCurrency,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'convertedAmount': convertedAmount,
      'convertedCurrency': convertedCurrency,
    };
  }
}
