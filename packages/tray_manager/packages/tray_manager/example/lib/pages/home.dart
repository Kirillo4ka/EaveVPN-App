// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tray_manager/tray_manager.dart';

const _kIconTypeDefault = 'default';
const _kIconTypeOriginal = 'original';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TrayListener {
  ValueNotifier<bool> shouldForegroundOnContextMenu = ValueNotifier(false);
  String _iconType = _kIconTypeOriginal;
  Menu? _menu;

  Timer? _iconFlashTimer;
  Timer? _titleRefreshTimer;

  @override
  void initState() {
    trayManager.addListener(this);
    super.initState();
  }

  @override
  void dispose() {
    _iconFlashTimer?.cancel();
    _titleRefreshTimer?.cancel();
    trayManager.removeListener(this);
    super.dispose();
  }

  Future<void> _handleSetIcon(String iconType) async {
    _iconType = iconType;
    String iconPath =
    Platform.isWindows ? 'images/tray_icon.ico' : 'images/tray_icon.png';

    if (_iconType == 'original') {
      iconPath = Platform.isWindows
          ? 'images/tray_icon_original.ico'
          : 'images/tray_icon_original.png';
    }

    await trayManager.setIcon(iconPath);
  }

  void _startIconFlashing() {
    _iconFlashTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      _handleSetIcon(
        _iconType == _kIconTypeOriginal
            ? _kIconTypeDefault
            : _kIconTypeOriginal,
      );
    });
    setState(() {});
  }

  void _stopIconFlashing() {
    _iconFlashTimer?.cancel();
    setState(() {});
  }

  void _startTitleRefreshing() {
    _titleRefreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final time = DateTime.now().toIso8601String().substring(11, 19);
      trayManager.setTitle('$time\n$time');
    });
    setState(() {});
  }

  void _stopTitleRefreshing() {
    _titleRefreshTimer?.cancel();
    setState(() {});
  }

  Widget _buildBody(BuildContext context) {
    return ListView(
      children: <Widget>[
        ListTile(
          title: const Text('destroy'),
          onTap: () {
            trayManager.destroy();
          },
        ),
        const Divider(height: 0),
        ListTile(
          title: const Text('setIcon'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Builder(
                builder: (_) {
                  bool isFlashing =
                  (_iconFlashTimer != null && _iconFlashTimer!.isActive);
                  return TextButton(
                    onPressed:
                    isFlashing ? _stopIconFlashing : _startIconFlashing,
                    child: isFlashing
                        ? const Text('stop flash')
                        : const Text('start flash'),
                  );
                },
              ),
              TextButton(
                child: const Text('Default'),
                onPressed: () => _handleSetIcon(_kIconTypeDefault),
              ),
              TextButton(
                child: const Text('Original'),
                onPressed: () => _handleSetIcon(_kIconTypeOriginal),
              ),
            ],
          ),
          onTap: () => _handleSetIcon(_kIconTypeDefault),
        ),
        const Divider(height: 0),
        ListTile(
          title: const Text('setIconPosition'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                child: const Text('left'),
                onPressed: () {
                  trayManager.setIconPosition(TrayIconPosition.left);
                },
              ),
              TextButton(
                child: const Text('right'),
                onPressed: () {
                  trayManager.setIconPosition(TrayIconPosition.right);
                },
              ),
            ],
          ),
          onTap: () => _handleSetIcon(_kIconTypeDefault),
        ),
        const Divider(height: 0),
        ListTile(
          title: const Text('setToolTip'),
          onTap: () async {
            await trayManager.setToolTip('tray_manager');
          },
        ),
        const Divider(height: 0),
        ListTile(
          title: const Text('setTitle'),
          trailing: Builder(
            builder: (_) {
              final isRefreshing = _titleRefreshTimer?.isActive ?? false;
              return TextButton(
                onPressed:
                isRefreshing ? _stopTitleRefreshing : _startTitleRefreshing,
                child: Text(isRefreshing ? 'stop refresh' : 'start refresh'),
              );
            },
          ),
          onTap: () async {
            await trayManager.setTitle('tray_manager');
          },
        ),
        const Divider(height: 0),
        ListTile(
          title: const Text('setContextMenu'),
          onTap: () async {
            _menu ??= Menu(
              items: [
                MenuItem(
                  label: 'Look Up "LeanFlutter"',
                ),
                MenuItem(
                  label: 'Search with Google',
                ),
                MenuItem.separator(),
                MenuItem(
                  label: 'Cut',
                ),
                MenuItem(
                  label: 'Copy',
                ),
                MenuItem(
                  label: 'Paste',
                  disabled: true,
                ),
                MenuItem.submenu(
                  label: 'Share',
                  submenu: Menu(
                    items: [
                      MenuItem.checkbox(
                        label: 'Item 1',
                        checked: true,
                        onClick: (menuItem) {
                          if (kDebugMode) {
                            print('click item 1');
                          }
                          menuItem.checked = !(menuItem.checked == true);
                        },
                      ),
                      MenuItem.checkbox(
                        label: 'Item 2',
                        checked: false,
                        onClick: (menuItem) {
                          if (kDebugMode) {
                            print('click item 2');
                          }
                          menuItem.checked = !(menuItem.checked == true);
                        },
                      ),
                    ],
                  ),
                ),
                MenuItem.separator(),
                MenuItem.submenu(
                  label: 'Font',
                  submenu: Menu(
                    items: [
                      MenuItem.checkbox(
                        label: 'Item 1',
                        checked: true,
                        onClick: (menuItem) {
                          if (kDebugMode) {
                            print('click item 1');
                          }
                          menuItem.checked = !(menuItem.checked == true);
                        },
                      ),
                      MenuItem.checkbox(
                        label: 'Item 2',
                        checked: false,
                        onClick: (menuItem) {
                          if (kDebugMode) {
                            print('click item 2');
                          }
                          menuItem.checked = !(menuItem.checked == true);
                        },
                      ),
                      MenuItem.separator(),
                      MenuItem(
                        label: 'Item 3',
                        checked: false,
                      ),
                      MenuItem(
                        label: 'Item 4',
                        checked: false,
                      ),
                      MenuItem(
                        label: 'Item 5',
                        checked: false,
                      ),
                    ],
                  ),
                ),
                MenuItem.submenu(
                  label: 'Speech',
                  submenu: Menu(
                    items: [
                      MenuItem(
                        label: 'Item 1',
                      ),
                      MenuItem(
                        label: 'Item 2',
                      ),
                    ],
                  ),
                ),
              ],
            );
            await trayManager.setContextMenu(_menu!);
          },
        ),
        const Divider(height: 0),
        ValueListenableBuilder(
          valueListenable: shouldForegroundOnContextMenu,
          builder: (context, bool bringToForeground, Widget? child) {
            return ListTile(
              title: const Text('popUpContextMenu'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Should bring app to foreground'),
                  Switch(
                    value: bringToForeground,
                    onChanged: (value) {
                      shouldForegroundOnContextMenu.value = !bringToForeground;
                    },
                  ),
                ],
              ),
              onTap: () async {
                await trayManager.popUpContextMenu(
                  bringAppToFront: shouldForegroundOnContextMenu.value,
                );
              },
            );
          },
        ),
        const Divider(height: 0),
        ListTile(
          title: const Text('getBounds'),
          onTap: () async {
            Rect? bounds = await trayManager.getBounds();
            if (bounds != null) {
              Size size = bounds.size;
              Offset origin = bounds.topLeft;
              BotToast.showText(
                text: '${size.toString()}\n${origin.toString()}',
              );
            }
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
      ),
      body: _buildBody(context),
    );
  }

  @override
  void onTrayIconMouseDown() {
    if (kDebugMode) {
      print('onTrayIconMouseDown');
    }
    trayManager.popUpContextMenu(
      bringAppToFront: shouldForegroundOnContextMenu.value,
    );
  }

  @override
  void onTrayIconMouseUp() {
    if (kDebugMode) {
      print('onTrayIconMouseUp');
    }
  }

  @override
  void onTrayIconRightMouseDown() {
    if (kDebugMode) {
      print('onTrayIconRightMouseDown');
    }
    // trayManager.popUpContextMenu();
  }

  @override
  void onTrayIconRightMouseUp() {
    if (kDebugMode) {
      print('onTrayIconRightMouseUp');
    }
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (kDebugMode) {
      print(menuItem.toJson());
    }
    BotToast.showText(
      text: '${menuItem.toJson()}',
    );
  }
}
