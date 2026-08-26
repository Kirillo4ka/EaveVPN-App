import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String trayIconSource;

  setUpAll(() {
    final sourceFile = [
      File('macos/Classes/TrayIcon.swift'),
      File('macos/tray_manager/Classes/TrayIcon.swift'),
      File('packages/tray_manager/macos/Classes/TrayIcon.swift'),
      File('packages/tray_manager/macos/tray_manager/Classes/TrayIcon.swift'),
    ].firstWhere(
      (file) => file.existsSync(),
      orElse: () => throw StateError('Could not find TrayIcon.swift'),
    );
    trayIconSource = sourceFile.readAsStringSync();
  });

  test('macOS tray title is self-drawn instead of using NSTextField', () {
    expect(trayIconSource, contains('class SpeedTextView: NSView'));
    expect(trayIconSource, isNot(contains('NSTextField')));
  });

  test('macOS tray icon position reorders image and title views', () {
    expect(trayIconSource, contains('applyImagePosition'));
    expect(trayIconSource, contains('insertArrangedSubview'));
    expect(
      trayIconSource,
      contains('imagePosition == "right"'),
    );
  });

  test('macOS tray title text is drawn centered', () {
    expect(trayIconSource, contains('override var isFlipped: Bool'));
    expect(trayIconSource, contains('.alignment = .right'));
    expect(
      trayIconSource,
      contains('(bounds.height - textBounds.height) / 2'),
    );
  });
}
