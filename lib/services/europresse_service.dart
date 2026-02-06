import 'package:dio/dio.dart';
import '../core/constants.dart';
import '../models/article.dart';
import '../models/search_result.dart';
import '../models/source_filter.dart';
import 'http_client.dart';
import 'html_parser.dart';

class EuropresseService {
  final AppHttpClient _client;
  String? _csrfToken;
  String _lastResultPath = '/Search/ResultMobile';
  EuropresseService(this._client);

  /// Fetch CSRF token from the search reading page
  Future<String> _getCsrfToken({bool forceRefresh = false}) async {
    if (_csrfToken != null && !forceRefresh) return _csrfToken!;

    final response = await _client.get(AppConstants.searchReadingPath);

    // Capture __RequestVerificationToken cookie from response —
    // ASP.NET requires both the form field AND the HttpOnly cookie.
    final setCookies = response.headers['set-cookie'];
    if (setCookies != null) {
      for (final cookie in setCookies) {
        if (cookie.startsWith('__RequestVerificationToken=')) {
          _client.appendCookie(cookie.split(';').first);
          break;
        }
      }
    }

    // If we got a redirect (302/301), the session might be invalid
    final statusCode = response.statusCode ?? 0;
    final responseData = response.data ?? '';

    if (statusCode >= 300 || responseData.isEmpty) {
      throw Exception(
        'Session invalide (status $statusCode). Reconnectez-vous.',
      );
    }

    final token = HtmlParserService.extractCsrfToken(responseData);
    if (token == null) {
      // Log the first 200 chars of the response for debugging
      final preview = responseData.length > 200
          ? responseData.substring(0, 200)
          : responseData;
      throw Exception(
        'CSRF token introuvable. Réponse: $preview',
      );
    }
    _csrfToken = token;
    return token;
  }

  /// Clear cached CSRF token (e.g. after session refresh)
  void clearCsrfToken() {
    _csrfToken = null;
  }

  /// URL-encode a single value for form data
  String _enc(String v) => Uri.encodeQueryComponent(v);

  /// Search Europresse
  Future<void> search({
    String keywords = '',
    String titleQuery = '',
    int dateRange = AppConstants.dateRangeAll,
    String? dateStart,
    String? dateStop,
    int sourcesForm = 1,
  }) async {
    final token = await _getCsrfToken();

    // Build Keywords value: prefix with TIT_HEAD= for title search
    String kw;
    if (titleQuery.isNotEmpty) {
      kw = 'TIT_HEAD=$titleQuery';
    } else {
      kw = keywords;
    }

    // Build form body matching browser format (POST to /Search/Reading)
    final body = [
      '__RequestVerificationToken=${_enc(token)}',
      'Keywords=${_enc(kw)}',
      'DateFilter.DateRange=$dateRange',
      'DateFilter.DateStart=${_enc(dateStart ?? '')}',
      'DateFilter.DateStop=${_enc(dateStop ?? '')}',
      'CriteriaSet=0',
      'SearchType=Mobile',
    ].join('&');

    // POST search to /Search/Reading (same endpoint, handles both GET form + POST submit)
    final postResponse = await _client.post(
      AppConstants.searchReadingPath,
      data: body,
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        followRedirects: false,
        validateStatus: (status) => status != null && status < 400,
        headers: {
          'Origin': _client.baseUrl,
          'Referer': '${_client.baseUrl}${AppConstants.searchReadingPath}',
        },
      ),
    );

    // Follow the actual redirect to initialize results in the server session.
    final location = postResponse.headers.value('location') ?? '';
    final redirectPath = Uri.parse(location).path;
    if (redirectPath.isEmpty) {
      throw Exception('Pas de redirection après la recherche');
    }
    _lastResultPath = redirectPath;

    await _client.get(redirectPath);
  }

  /// Get paginated search results (pageNo is 0-indexed)
  Future<List<SearchResult>> getSearchResults({int page = 0}) async {
    final response = await _client.get(
      AppConstants.searchGetPagePath,
      queryParameters: {
        'pageNo': page,
        'docPerPage': AppConstants.docsPerPage,
      },
      headers: {
        'X-Requested-With': 'XMLHttpRequest',
        'Referer': '${_client.baseUrl}$_lastResultPath',
        'Accept': 'text/html, */*; q=0.01',
      },
    );

    return HtmlParserService.parseSearchResults(response.data ?? '');
  }

  /// Get full article content
  Future<Article> getArticle(String docKey) async {
    final response = await _client.get(
      AppConstants.articleViewPath,
      queryParameters: {
        'docKey': docKey,
        'fromBasket': 'false',
        'viewEvent': '1',
        'invoiceCode': '',
      },
    );

    final parsed = HtmlParserService.parseArticle(response.data ?? '');
    return Article(
      id: docKey,
      title: parsed.title,
      source: '',
      date: '',
      description: '',
      html: parsed.html,
    );
  }

  /// Search for available sources
  Future<List<SourceFilter>> searchSources(String query) async {
    final response = await _client.get(
      AppConstants.sourcesFilterPath,
      queryParameters: {'term': query},
    );

    return HtmlParserService.parseSources(response.data ?? '');
  }
}
