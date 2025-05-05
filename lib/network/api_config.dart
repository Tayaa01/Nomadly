class ApiConfig {
  // Main base URL for all services
  //static const String BASE_URL = "http://espritmobile.com/api";
  static const String BASE_URL = "http://192.168.238.159:3000/api";

  // Endpoints for Auth Service
  static const String REGISTER_ENDPOINT = "/auth/register";
  static const String LOGIN_ENDPOINT = "/auth/login";
  static const String VERIFY_JWT_ENDPOINT =
      "/auth/verify-jwt"; // New endpoint for JWT verification

  // Endpoints for User Service
  static const String USER_PROFILE_ENDPOINT = "/users/me";
  static const String USER_UPDATE_ENDPOINT = "/users/me";

  // Endpoints for Currency Service
  static const String CURRENCY_ANALYZE_ENDPOINT = "/tax-free/analyze";
  static const String CURRENCY_CONVERT_ENDPOINT = "/currency-converter/convert";
  static const String CURRENCIES_LIST_ENDPOINT =
      "/currency-converter/currencies";

  // Endpoints for Translation Service
  static const String TRANSLATION_ENDPOINT = "/translation/translate";

  // Endpoints for Deals Service
  static const String DEALS_ENDPOINT = "/deals/travel/cheapest";
  static const String DEALS_SEARCH_ENDPOINT = "/deals/search";

  // Endpoints for Finance Service
  static const String TRANSACTIONS_BY_DAY_ENDPOINT = "/transactions/by-day";
  static const String SAVINGS_BY_DAY_ENDPOINT = "/savings/by-day";

  // Add the new endpoint for image analysis without saving a transaction
  static const String IMAGE_ANALYZE_CONVERT_ENDPOINT =
      "/image-currency/analyze-and-convert";

  // New endpoint for Travel Planner
  static const String TRAVEL_ITINERARY_ENDPOINT = "/travel/itinerary";

  // Travel Planner endpoints
  static const String TRAVEL_PLAN_ENDPOINT = "/travel-planner/plan";
  static const String TRAVEL_GENERATE_PLAN_ENDPOINT =
      "/travel-planner/generate-plan";
  static const String TRAVEL_GENERATE_BUDGET_PLAN_ENDPOINT =
      "/travel-planner/generate-budget-plan";

  // Request timeouts
  static const int CONNECT_TIMEOUT = 30000; // 30 seconds
  static const int RECEIVE_TIMEOUT = 30000; // 30 seconds
  static const int SEND_TIMEOUT = 30000; // 30 seconds

  // Common headers
  static Map<String, String> get commonHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Add list of supported currencies
  static const List<String> SUPPORTED_CURRENCIES = [
    'EUR',
    'USD',
    'GBP',
    'JPY',
    'CAD',
    'AUD',
    'CHF',
    'CNY',
    'INR',
    'TND', // Tunisian Dinar
  ];

  // Helper to create authenticated headers
  static Map<String, String> getAuthHeaders(String token) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }
}
