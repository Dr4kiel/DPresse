import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../core/constants.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String _currentUrl = '';
  bool _loginAttempted = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (url) {
          if (mounted) setState(() => _isLoading = true);
        },
        onPageFinished: (url) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _currentUrl = url;
            });
          }
          _checkForEuropresse(url);
        },
        onNavigationRequest: (request) {
          return NavigationDecision.navigate;
        },
      ));
    _clearCookiesAndLoad();
  }

  Future<void> _clearCookiesAndLoad() async {
    await WebViewCookieManager().clearCookies();
    _controller.loadRequest(Uri(
      scheme: 'https',
      host: 'bnf.idm.oclc.org',
      path: '/login',
      query: AppConstants.bnfLoginQuery,
    ));
  }

  bool _isEuropresseUrl(String url) {
    final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
    return host.contains('europresse');
  }

  Future<void> _checkForEuropresse(String url) async {
    if (!_isEuropresseUrl(url) || _loginAttempted) return;

    // Skip the /access/ip/ authentication page — session isn't fully
    // established until Europresse redirects to the main page.
    final uri = Uri.parse(url);
    if (uri.path.toLowerCase().contains('/access/ip/')) return;

    _loginAttempted = true;
    final domain = uri.host;

    try {
      String? rawCookies;

      // Get ALL cookies (including HttpOnly) via native Android CookieManager
      try {
        const channel = MethodChannel('dpresse/cookies');
        rawCookies = await channel.invokeMethod<String>(
          'getCookies',
          {'url': url},
        );
      } catch (_) {
        // Fallback to JavaScript
        final Object result = await _controller
            .runJavaScriptReturningResult('document.cookie');
        rawCookies = result.toString().replaceAll('"', '');
      }

      if (rawCookies == null || rawCookies.isEmpty) {
        _loginAttempted = false;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aucun cookie capturé. Réessayez.')),
          );
        }
        return;
      }

      if (!mounted) return;

      // Pass the raw cookie string directly — no parsing needed
      ref.read(authProvider.notifier).loginWithCookies(
        domain: domain,
        rawCookies: rawCookies,
      );
    } catch (e) {
      _loginAttempted = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Connexion BNF',
          style: theme.textTheme.titleLarge,
        ),
        actions: [
          if (_currentUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Text(
                  Uri.tryParse(_currentUrl)?.host ?? '',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const LinearProgressIndicator(),
        ],
      ),
    );
  }
}
