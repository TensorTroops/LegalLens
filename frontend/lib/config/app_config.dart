class AppConfig {
  // API Configuration - Local backend for testing migration
  static const String apiBaseUrl = 'https://legallens-backend-371570013381.asia-south1.run.app';
  
  // API Endpoints - Updated to use MCP Server
  static String get legalChatBaseUrl => '$apiBaseUrl/api/v1/mcp';
  static String get documentsBaseUrl => '$apiBaseUrl/api/v1/documents';
  static String get dictionaryBaseUrl => '$apiBaseUrl/api/v1';
  
  // MCP Specific Endpoints
  static String get mcpProcessText => '$apiBaseUrl/api/v1/mcp/process-text';
  static String get mcpProcessDocument => '$apiBaseUrl/api/v1/mcp/process-document';
  static String get mcpLookupTerm => '$apiBaseUrl/api/v1/mcp/lookup-term';
  static String get mcpHealth => '$apiBaseUrl/api/v1/mcp/health';
  
  // Network timeouts (in seconds)
  static const int connectionTimeout = 120; // Increased for MCP processing
  static const int receiveTimeout = 120;
  
  // Debug info
  static String get currentEnvironment => 'Development (MCP Enabled)';
  static String get currentApiUrl => apiBaseUrl;
}