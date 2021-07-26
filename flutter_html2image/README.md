# flutter_html2image

A Flutter plugin to generate full content screenshot from raw HTML using platform-specific web engine.

- WebView (Android)
- WKWebView (iOS)
- Chromium (Windows)

## Requirements
- Android: minSdkVersion 17

## Example
```dart
    await _generator.load(html);
    Uint8List image = await _generator.generate();
```

## Credits
- https://github.com/pichillilorenzo/flutter_inappwebview