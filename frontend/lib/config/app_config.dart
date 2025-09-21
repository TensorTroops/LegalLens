class AppConfig {
  // API Configuration - Google Cloud Run backend
  static const String apiBaseUrl = 'https://backend-795183661271.asia-south1.run.app';
  
  // API Endpoints
  static String get legalChatBaseUrl => '$apiBaseUrl/api/v1/legal-chat';
  
  // Network timeouts (in seconds)
  static const int connectionTimeout = 30;
  static const int receiveTimeout = 30;
  
  // Debug info
  static String get currentEnvironment => 'Production';
  static String get currentApiUrl => apiBaseUrl;
}