import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme.dart';
import '../data/webview_data.dart';

/// The website shown after the native IntroGate finishes.
class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key, this.windowId});

  static const initialUrl = 'https://gamelink.legonn.my/';
  final int? windowId;

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  InAppWebViewController? _controller;
  bool _canGoBack = false;
  String? _error;
  Map<String, dynamic>? _deviceData;

  @override
  void initState() {
    super.initState();
    _prepareDeviceData();
  }

  Future<void> _prepareDeviceData() async {
    try {
      final data = await loadDeviceData();
      await NcupSaveJsonToLocalStorageAndPrefs(
        controller: null,
        key: appDataKey,
        data: data,
      );
      if (mounted) setState(() => _deviceData = data);
    } catch (_) {
      if (mounted)
        setState(() => _error = 'Could not prepare app data. Please retry.');
    }
  }

  String get _storageScript =>
      "if (location.origin === '$appOrigin') { ${localStorageJsonScript(appDataKey, _deviceData!)} }";

  String get _externalLinksScript =>
      r'''(function () {
  if (window.__legonExternalLinks) return;
  window.__legonExternalLinks = true;
  function external(url) {
    if (['javascript:', 'data:', 'blob:', 'file:', 'about:'].includes(url.protocol)) return false;
    if (!['https:', 'http:'].includes(url.protocol)) return true;
    const host = url.hostname.toLowerCase().replace(/\.$/, '');
    return __EXTERNAL_DOMAINS__.some(domain => host === domain || host.endsWith('.' + domain));
  }
  function open(url) {
    function launch() {
      window.flutter_inappwebview.callHandler('legonOpenExternal', url.href);
    }
    if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) launch();
    else window.addEventListener('flutterInAppWebViewPlatformReady', launch, {once: true});
  }
  document.addEventListener('click', function (event) {
    const anchor = event.composedPath().find(node => node.tagName === 'A' && node.href);
    if (!anchor) return;
    const url = new URL(anchor.href, document.baseURI);
    if (!external(url)) return;
    event.preventDefault();
    event.stopImmediatePropagation();
    open(url);
  }, true);
  const originalOpen = window.open;
  window.open = function (value) {
    if (!value) return originalOpen.apply(window, arguments);
    const url = new URL(value, document.baseURI);
    if (!external(url)) return originalOpen.apply(window, arguments);
    open(url);
    return null;
  };
})();
'''
          .replaceAll('__EXTERNAL_DOMAINS__', jsonEncode(externalAppDomains));

  final _settings = InAppWebViewSettings(
    javaScriptEnabled: true,
    transparentBackground: true,
    isInspectable: true,
    disableDefaultErrorPage: true,
    mediaPlaybackRequiresUserGesture: false,
    allowsInlineMediaPlayback: true,
    allowsPictureInPictureMediaPlayback: true,
    useOnDownloadStart: true,
    javaScriptCanOpenWindowsAutomatically: true,
    useShouldOverrideUrlLoading: true,
    supportMultipleWindows: true,
    thirdPartyCookiesEnabled: true,
    sharedCookiesEnabled: true,
    domStorageEnabled: true,
    databaseEnabled: true,
    cacheEnabled: true,
    mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
    allowsBackForwardNavigationGestures: true,
  );

  Future<void> _updateHistory(InAppWebViewController controller) async {
    final canGoBack = await controller.canGoBack();
    if (mounted) setState(() => _canGoBack = canGoBack);
  }

  Future<void> _openExternal(WebUri url) async {
    final uri = Uri.tryParse(url.toString());
    if (uri == null || !canOpenExternally(uri)) return;
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      // Show a recoverable message if no app can handle the URL.
    }
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Could not open this link.')));
  }

  void _showError(String message) {
    if (mounted) setState(() => _error = message);
  }

  Future<void> _retry() async {
    setState(() => _error = null);
    if (_deviceData == null) {
      await _prepareDeviceData();
    } else {
      await _controller?.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_canGoBack,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && _canGoBack) {
          await _controller?.goBack();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF16181F),
        appBar: widget.windowId == null
            ? null
            : AppBar(
                title: const Text('LEG ON'),
                leading: IconButton(
                  tooltip: 'Close window',
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
        body: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_deviceData == null)
                const Center(child: CircularProgressIndicator())
              else
                InAppWebView(
                  windowId: widget.windowId,
                  initialUrlRequest: widget.windowId == null
                      ? URLRequest(url: WebUri(WebViewScreen.initialUrl))
                      : null,
                  initialSettings: _settings,
                  initialUserScripts: UnmodifiableListView([
                    UserScript(
                      source: _storageScript,
                      injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
                      forMainFrameOnly: true,
                    ),
                    UserScript(
                      source: _externalLinksScript,
                      injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
                      forMainFrameOnly: true,
                    ),
                  ]),
                  onWebViewCreated: (controller) {
                    _controller = controller;
                    controller.addJavaScriptHandler(
                      handlerName: 'legonOpenExternal',
                      callback: (arguments) async {
                        if (arguments.length == 1 &&
                            arguments.first is String) {
                          final uri = Uri.tryParse(arguments.first as String);
                          if (uri != null && shouldOpenExternally(uri)) {
                            await _openExternal(WebUri(uri.toString()));
                          }
                        }
                        return null;
                      },
                    );
                  },
                  onLoadStart: (controller, url) {
                    if (mounted) setState(() => _error = null);
                  },
                  onLoadStop: (controller, url) async {
                    await NcupSaveJsonToLocalStorageAndPrefs(
                      controller: controller,
                      key: appDataKey,
                      data: _deviceData!,
                    );
                    await _updateHistory(controller);
                  },
                  onUpdateVisitedHistory: (controller, url, isReload) =>
                      _updateHistory(controller),
                  shouldOverrideUrlLoading: (controller, action) async {
                    final url = action.request.url;
                    if (url == null) return NavigationActionPolicy.ALLOW;
                    if (!action.isForMainFrame)
                      return NavigationActionPolicy.ALLOW;
                    final uri = Uri.tryParse(url.toString());
                    if (uri == null) return NavigationActionPolicy.CANCEL;
                    if (shouldOpenExternally(uri)) {
                      await _openExternal(url);
                      return NavigationActionPolicy.CANCEL;
                    }
                    if (const {
                      'http',
                      'https',
                      'about',
                      'data',
                      'blob',
                    }.contains(uri.scheme)) {
                      return NavigationActionPolicy.ALLOW;
                    }
                    return NavigationActionPolicy.CANCEL;
                  },
                  onCreateWindow: (controller, action) async {
                    final url = action.request.url;
                    final uri = url == null
                        ? null
                        : Uri.tryParse(url.toString());
                    if (uri != null && shouldOpenExternally(uri)) {
                      await _openExternal(url!);
                      return false;
                    }
                    if (uri != null &&
                        !const {
                          'http',
                          'https',
                          'about',
                          'data',
                          'blob',
                        }.contains(uri.scheme)) {
                      return false;
                    }
                    if (!mounted) return false;
                    Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) =>
                            WebViewScreen(windowId: action.windowId),
                      ),
                    );
                    return true;
                  },
                  onCloseWindow: (controller) {
                    if (mounted && widget.windowId != null)
                      Navigator.of(context).pop();
                  },
                  onDownloadStartRequest: (controller, request) async {
                    // Let the system browser handle HTTP downloads.
                    if (const {'http', 'https'}.contains(request.url.scheme)) {
                      await _openExternal(request.url);
                    } else {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'This download requires a browser link.',
                          ),
                        ),
                      );
                    }
                  },
                  onReceivedError: (controller, request, error) {
                    if (request.isForMainFrame == true) {
                      _showError(
                        'Could not load the page. Check your connection.',
                      );
                    }
                  },
                  onReceivedHttpError: (controller, request, response) {
                    if (request.isForMainFrame == true) {
                      _showError(
                        'The server returned an error (${response.statusCode}).',
                      );
                    }
                  },
                ),
              if (_error != null)
                ColoredBox(
                  color: LegonColors.ground,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_error!, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _retry,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
