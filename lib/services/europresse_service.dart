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

    final data = {
      'Keywords': keywords,
      'CriteriaKeys[0].Operator': '&',
      'CriteriaKeys[0].Key': 'TIT_HEAD',
      'CriteriaKeys[0].Text': titleQuery,
      'CriteriaKeys[1].Operator': '&',
      'CriteriaKeys[1].Key': 'LEAD',
      'CriteriaKeys[1].Text': '',
      'CriteriaKeys[2].Operator': '&',
      'CriteriaKeys[2].Key': 'AUT_BY',
      'CriteriaKeys[2].Text': '',
      'DateFilter.DateRange': dateRange.toString(),
      'DateFilter.DateStart': dateStart ?? '',
      'DateFilter.DateStop': dateStop ?? '',
      'SourcesForm': sourcesForm.toString(),
      '__RequestVerificationToken': token,
    };

    // POST search — a 302 to ResultMobile is expected
    await _client.post(
      AppConstants.searchAdvancedPath,
      data: data,
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        followRedirects: false,
        validateStatus: (status) => status != null && status < 400,
      ),
    );

    // Follow the redirect to initialize results in the server session.
    await _client.get(AppConstants.searchResultPath);
  }

  /// Get paginated search results
  Future<List<SearchResult>> getSearchResults({int page = 1}) async {
    final response = await _client.get(
      AppConstants.searchGetPagePath,
      queryParameters: {
        'pageNo': page,
        'docPerPage': AppConstants.docsPerPage,
      },
      headers: {'X-Requested-With': 'XMLHttpRequest'},
    );

    final html = response.data ?? '';
    print('[Europresse] GetPage response (${html.length} chars)');
    if (html.isNotEmpty) {
      final preview = html.length > 500 ? html.substring(0, 500) : html;
      print('[Europresse] GetPage preview:\n$preview');
    }
    return HtmlParserService.parseSearchResults(html);
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

    final html = response.data ?? '';
    // Debug: check article HTML structure
    final titleIdx = html.indexOf('titreArticle');
    final contentIdx = html.indexOf('docOcurrContainer');
    final docViewIdx = html.indexOf('docView');
    print('[Europresse] Article HTML (${html.length} chars): titreArticle@$titleIdx, docOcurrContainer@$contentIdx, docView@$docViewIdx');
    if (html.length > 500) {
      // Show body area
      final bodyIdx = html.indexOf('<body');
      if (bodyIdx > 0) {
        final end = (bodyIdx + 1500).clamp(0, html.length);
        print('[Europresse] Article body:\n${html.substring(bodyIdx, end)}');
      }
    }
    final parsed = HtmlParserService.parseArticle(html);
    print('[Europresse] Parsed article: title="${parsed.title}", html=${parsed.html.length} chars');
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
