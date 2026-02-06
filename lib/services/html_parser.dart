import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';
import '../models/search_result.dart';
import '../models/source_filter.dart';

class HtmlParserService {
  /// Parse search results from Europresse HTML
  static List<SearchResult> parseSearchResults(String html) {
    final document = html_parser.parse(html);
    final items = document.querySelectorAll('.docListItem');
    final results = <SearchResult>[];

    for (final item in items) {
      final titleEl = item.querySelector('.docList-links');
      final sourceEl = item.querySelector('.source-name');
      final detailsEl = item.querySelector('.details');
      final descEl = item.querySelector('.kwicResult.clearfix');
      final idInput = item.querySelector('input#doc-name') ??
          item.querySelector('input[name="doc-name"]');

      final title = titleEl?.text.trim() ?? '';
      final source = sourceEl?.text.trim() ?? '';
      final id = idInput?.attributes['value'] ?? '';

      // Date is before the bullet "•" in details
      String date = '';
      if (detailsEl != null) {
        final detailsText = detailsEl.text.trim();
        final bulletIndex = detailsText.indexOf('•');
        if (bulletIndex > 0) {
          date = detailsText.substring(0, bulletIndex).trim();
        } else {
          date = detailsText;
        }
      }

      final description = descEl?.text.trim() ?? '';

      if (id.isNotEmpty) {
        results.add(SearchResult(
          id: id,
          title: title,
          source: source,
          date: date,
          description: description,
        ));
      }
    }

    return results;
  }

  /// Extract CSRF token from search page
  static String? extractCsrfToken(String html) {
    final document = html_parser.parse(html);
    final input = document.querySelector(
      'input[name="__RequestVerificationToken"]',
    );
    return input?.attributes['value'];
  }

  /// Parse article HTML content
  static ({String title, String html}) parseArticle(String rawHtml) {
    final document = html_parser.parse(rawHtml);

    // Extract title
    final titleEl = document.querySelector('.titreArticleVisu');
    final title = titleEl?.text.trim() ?? '';

    // Extract main content
    final contentEl = document.querySelector('.docOcurrContainer');
    if (contentEl == null) {
      return (title: title, html: '');
    }

    // Remove search highlight marks
    for (final mark in contentEl.querySelectorAll('mark')) {
      mark.replaceWith(Text(mark.text));
    }

    return (title: title, html: contentEl.innerHtml);
  }

  /// Parse source filters from Europresse
  static List<SourceFilter> parseSources(String html) {
    final document = html_parser.parse(html);
    final divs = document.querySelectorAll('div');
    final sources = <SourceFilter>[];

    for (final div in divs) {
      final titleEl = div.querySelector('.plainTxt');
      final idInput = div.querySelector('input[criteriaId]') ??
          div.querySelector('input[criteriaid]');

      if (titleEl != null && idInput != null) {
        var title = titleEl.text.trim();
        final id = idInput.attributes['criteriaId'] ??
            idInput.attributes['criteriaid'] ?? '';

        // Reformat titles like "Monde, Le" → "Le Monde"
        title = _reformatSourceTitle(title);

        if (id.isNotEmpty) {
          sources.add(SourceFilter(title: title, id: id));
        }
      }
    }

    return sources;
  }

  /// Reformat source titles: "Monde, Le" → "Le Monde"
  static String _reformatSourceTitle(String title) {
    final commaIndex = title.indexOf(',');
    if (commaIndex > 0) {
      final main = title.substring(0, commaIndex).trim();
      final prefix = title.substring(commaIndex + 1).trim();
      if (prefix.isNotEmpty) {
        return '$prefix $main';
      }
    }
    return title;
  }
}
