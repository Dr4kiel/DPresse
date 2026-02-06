import 'package:dio/dio.dart';
import 'package:xml/xml.dart';
import '../models/feed_item.dart';

class RssService {
  final Dio _dio;

  RssService({Dio? dio}) : _dio = dio ?? Dio();

  /// Fetch and parse an RSS feed
  Future<List<FeedItem>> fetchFeed(String url, String sourceName) async {
    try {
      final response = await _dio.get<String>(
        url,
        options: Options(
          responseType: ResponseType.plain,
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.data == null) return [];

      return _parseRss(response.data!, sourceName);
    } catch (e) {
      return [];
    }
  }

  List<FeedItem> _parseRss(String xml, String sourceName) {
    try {
      final document = XmlDocument.parse(xml);
      final items = document.findAllElements('item');
      final feedItems = <FeedItem>[];

      for (final item in items) {
        final title = _getElementText(item, 'title');
        final link = _getElementText(item, 'link');
        final description = _stripHtml(_getElementText(item, 'description'));
        final pubDateStr = _getElementText(item, 'pubDate');

        DateTime? pubDate;
        if (pubDateStr.isNotEmpty) {
          pubDate = _parseDate(pubDateStr);
        }

        if (title.isNotEmpty) {
          feedItems.add(FeedItem(
            title: title,
            link: link,
            description: description,
            source: sourceName,
            pubDate: pubDate,
          ));
        }
      }

      return feedItems;
    } catch (e) {
      return [];
    }
  }

  String _getElementText(XmlElement parent, String name) {
    final el = parent.findElements(name).firstOrNull;
    return el?.innerText.trim() ?? '';
  }

  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  DateTime? _parseDate(String dateStr) {
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      // Try RFC 822 format commonly used in RSS
      try {
        return _parseRfc822(dateStr);
      } catch (_) {
        return null;
      }
    }
  }

  static final _rfc822Re = RegExp(
    r'(\d{1,2})\s+(\w{3})\s+(\d{4})\s+(\d{2}):(\d{2}):(\d{2})',
  );
  static const _months = {
    'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
    'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
  };

  DateTime? _parseRfc822(String dateStr) {
    final match = _rfc822Re.firstMatch(dateStr);
    if (match == null) return null;

    final day = int.parse(match.group(1)!);
    final month = _months[match.group(2)!];
    final year = int.parse(match.group(3)!);
    final hour = int.parse(match.group(4)!);
    final minute = int.parse(match.group(5)!);
    final second = int.parse(match.group(6)!);

    if (month == null) return null;
    return DateTime.utc(year, month, day, hour, minute, second);
  }
}
