class AppConstants {
  static const String appName = 'DPresse';

  // BNF Auth — target URL for EZProxy
  static const String bnfLoginQuery =
      'url=https://nouveau.europresse.com/access/ip/default.aspx?un=D000067U_1';
  static const String europresseDomain = 'nouveau.europresse.com';

  // Europresse endpoints (desktop — mobile loads results via JS/AJAX)
  static const String searchReadingPath = '/Search/Reading';
  static const String searchAdvancedPath = '/Search/Advanced';
  static const String searchResultPath = '/Search/Result';
  static const String searchGetPagePath = '/Search/GetPage';
  static const String articleViewPath = '/Document/ViewMobile';
  static const String sourcesFilterPath = '/Criteria/SourcesFilter';

  // Cookie settings
  static const Duration cookieValidDuration = Duration(minutes: 30);
  static const String cookieStorageKey = 'europresse_cookies';
  static const String cookieDomainKey = 'europresse_domain';
  static const String cookieTimestampKey = 'europresse_cookie_timestamp';

  // Search
  static const int docsPerPage = 50;

  // Date ranges for search
  static const int dateRangeWeek = 3;
  static const int dateRangeMonth = 4;
  static const int dateRangeYear = 7;
  static const int dateRangeAll = 9;
}
