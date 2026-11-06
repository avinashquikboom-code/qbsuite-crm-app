/// Global Application Configuration for QuikBoom CRM Mobile.
class AppConfig {
  /// UI-only mode keeps the employee demo local and disables network services.
  /// Set to [false] to restore the existing authentication and API-backed app.
  static const bool uiOnlyMode = true;

  /// Application environment identifier
  static const String appName = 'QB Suite';
  static const String appVersion = '1.0.0+1';
}
