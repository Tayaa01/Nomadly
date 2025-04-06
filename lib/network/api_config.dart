class ApiConfig {
  // Main base URL for all services
  static const String BASE_URL =
      "http://192.168.31.171:3000";

  // Endpoints for Auth Service
  static const String REGISTER_ENDPOINT = "/auth/register";
  static const String LOGIN_ENDPOINT = "/auth/login";

  // Endpoints for Currency Service
  static const String CURRENCY_ANALYZE_ENDPOINT = "/tax-free/analyze";
  static const String CURRENCY_CONVERT_ENDPOINT = "/currency-converter/convert";
  static const String CURRENCIES_LIST_ENDPOINT =
      "/currency-converter/currencies";

  // Endpoints for Translation Service
  static const String TRANSLATION_ENDPOINT = "/translation/translate";

  // Endpoints for Deals Service
  static const String DEALS_ENDPOINT = "/deals";
  static const String DEALS_SEARCH_ENDPOINT = "/deals/search";

  // Endpoints for Finance Service
  static const String TRANSACTIONS_BY_DAY_ENDPOINT = "/transactions/by-day";
  static const String SAVINGS_BY_DAY_ENDPOINT = "/savings/by-day";

  // Request timeouts
  static const int CONNECT_TIMEOUT = 30000; // 30 seconds
  static const int RECEIVE_TIMEOUT = 30000; // 30 seconds
  static const int SEND_TIMEOUT = 30000; // 30 seconds

  // Common headers
  static Map<String, String> get commonHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}
