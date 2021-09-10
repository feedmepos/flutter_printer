import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_html2image/src/merger.dart';
import 'package:flutter_inappwebview_forked/flutter_inappwebview.dart';
import 'package:image/image.dart';
import 'package:puppeteer/puppeteer.dart' as puppeteer;

class ImageInfo {
  ImageInfo(this.data, this.width, this.height);

  final Uint8List data;
  final int width;
  final int height;
}

class Html2Image {
  bool _initialized = false;
  HeadlessInAppWebView? _headlessWebView;
  puppeteer.Browser? _browser;
  puppeteer.Page? _page;

  /// Initialize a new platform-specific web instance
  ///
  /// Android/iOS: HeadlessInAppWebView instance
  ///
  /// Windows: Puppeteer Page instance(Chrome supports multi tab pages)
  Future<void> _initialize() async {
    if (_initialized) return;

    if (Platform.isAndroid) {
      await AndroidInAppWebViewController.setWebContentsDebuggingEnabled(true);
    }

    if (Platform.isAndroid || Platform.isIOS) {
      if (_headlessWebView == null) {
        _headlessWebView = new HeadlessInAppWebView(
            initialData: InAppWebViewInitialData(data: "<html><html>"),
            onWebViewCreated: (controller) {},
            onLoadStop: (controller, url) {});

        await _headlessWebView?.run();
        await _headlessWebView?.setSize(Size(300, 300));
        _initialized = true;
      }
    } else {
      if (_browser == null) {
        _browser = await puppeteer.puppeteer
            .launch(defaultViewport: puppeteer.DeviceViewport(width: 300));
      }

      if (_page == null) {
        _page = await _browser?.newPage();
      }
      _initialized = true;
    }
  }

  Future<Uint8List?> _captureiOS(double contentHeight) async {
    return await _headlessWebView?.webViewController.takeScreenshot(
        screenshotConfiguration: ScreenshotConfiguration(
            snapshotWidth: 300,
            iosAfterScreenUpdates: false,
            rect: InAppWebViewRect(
                x: 0, y: 0, width: 300, height: contentHeight)));
  }

  Future<ImageInfo> generateImage(
      {required String content,
      required int paperWidth,
      required int paperHeight,
      required int dpi,
      required bool isTspl,
      int delayMs = 150}) async {
    if (!_initialized) await _initialize();

    Uint8List? screenshot;
    List<Uint8List> screenshotImages = [];

    if (Platform.isAndroid || Platform.isIOS) {
      await _headlessWebView?.webViewController.loadData(data: content);
      await Future.delayed(Duration(milliseconds: delayMs));
    } else if (Platform.isWindows) {
      await _page?.setContent(content, wait: puppeteer.Until.load);
    }

    if (Platform.isAndroid) {
      screenshot = await _headlessWebView?.capture();
    } else if (Platform.isIOS) {
      // setSize on WKWebView does not execute immediately
      await _headlessWebView?.setSize(Size(300, 300));
      await Future.delayed(Duration(milliseconds: 10));

      final int webViewHeight =
          (await _headlessWebView?.webViewController.getContentHeight())!;

      // iOS has a height limit of 2700
      // So we must programmatically scroll and take screenshot
      final int heightLimit = 2700;
      if (webViewHeight > heightLimit) {
        final chunks = webViewHeight ~/ heightLimit;
        for (var i = 0; i < chunks; ++i) {
          bool isLast = webViewHeight - (i * heightLimit) < heightLimit;
          final int chunkHeight =
              isLast ? (webViewHeight - (chunks * heightLimit)) : heightLimit;
          await _headlessWebView?.webViewController
              .scrollTo(x: 0, y: (i * chunkHeight).toInt());
          await _headlessWebView?.setSize(Size(300, chunkHeight.toDouble()));
          // 100ms is enough for the setSize to take affect
          await Future.delayed(Duration(milliseconds: 100));
          var image = await _captureiOS(chunkHeight.toDouble());
          if (image != null) screenshotImages.add(image);
        }

        // merge image
        // all images are the same width, so no fit to sppedup the merge process
        screenshot = await Merger.mergeImages(screenshotImages, fit: false);
      } else {
        screenshot = await _captureiOS(webViewHeight.toDouble());
      }
    } else {
      screenshot = await _page?.screenshot(fullPage: true);
    }

    final double mmToInch = 0.036;
    final decodedImage = decodeImage(screenshot!);
    final oriWidth = decodedImage!.width;
    final oriHeight = decodedImage.height;
    int targetWidthPx =
        (paperWidth.toDouble() * dpi.toDouble() * mmToInch).toInt();
    final int nearest = 8;
    targetWidthPx = (targetWidthPx - (targetWidthPx % nearest)).round();
    final int widthRatio = targetWidthPx ~/ oriWidth;

    int targetHeightPx = 0;
    if (isTspl) {
      targetHeightPx =
          (paperHeight.toDouble() * dpi.toDouble() * mmToInch).toInt();
    } else {
      targetHeightPx = oriHeight * widthRatio;
    }
    return ImageInfo(screenshot, targetWidthPx, targetHeightPx);
  }

  Future<void> dispose({bool all = false}) async {
    if (!_initialized) return;

    if (_headlessWebView != null) {
      await _headlessWebView?.dispose();
    }
    if (_page != null) {
      await _page?.close();
    }
    if (_browser != null) {
      await _browser?.close();
    }
  }
}
