// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:sysui_widgets/icon_slider.dart';

import 'toggle_icon.dart';

// Width and height of the icons
const double _kIconSize = 24.0;

// Image assets
const String _kAirplaneModeInactiveGrey600 =
    'packages/armadillo/res/ic_airplanemode_inactive_grey600.png';
const String _kAirplaneModeActiveBlack =
    'packages/armadillo/res/ic_airplanemode_active_black.png';
const String _kDoNoDisturbOffGrey600 =
    'packages/armadillo/res/ic_do_not_disturb_off_grey600.png';
const String _kDoNoDisturbOnBlack =
    'packages/armadillo/res/ic_do_not_disturb_on_black.png';
const String kScreenLockRotationBlack =
    'packages/armadillo/res/ic_screen_lock_rotation_black.png';
const String kScreenRotationBlack =
    'packages/armadillo/res/ic_screen_rotation_black.png';
const String _kBatteryImageGrey600 =
    'packages/armadillo/res/ic_battery_90_grey600_1x_web_24dp.png';
const String _kMicImageGrey600 =
    'packages/armadillo/res/ic_mic_grey600_1x_web_24dp.png';
const String _kBrightnessHighGrey600 =
    'packages/armadillo/res/ic_brightness_high_grey600.png';
const String _kVolumeUpGrey600 =
    'packages/armadillo/res/ic_volume_up_grey600.png';

const Color _kTurquoise = const Color(0xFF1DE9B6);
const Color _kActiveSliderColor = _kTurquoise;

/// If [QuickSettings size] is wider than this, the contents will be laid out
/// into multiple columns instead of a single column.
const double _kMultiColumnWidthThreshold = 450.0;

class QuickSettingsOverlay extends StatefulWidget {
  final double minimizedNowBarHeight;

  QuickSettingsOverlay({
    Key key,
    this.minimizedNowBarHeight,
  })
      : super(key: key);

  @override
  QuickSettingsOverlayState createState() => new QuickSettingsOverlayState();
}

class QuickSettingsOverlayState extends State<QuickSettingsOverlay>
    with SingleTickerProviderStateMixin {
  double _volumeSliderValue = 0.0;
  double _brightnessSliderValue = 0.0;

  AnimationController _quickSettingsAnimControl;

  @override
  void initState() {
    super.initState();
    _quickSettingsAnimControl = new AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
  }

  void show() {
    setState(() {
      _quickSettingsAnimControl.forward();
    });
  }

  void hide() {
    setState(() {
      _quickSettingsAnimControl.reverse();
    });
  }

  Widget _buildQuickSettingsOverlayContent() => new Align(
        alignment: FractionalOffset.bottomCenter,
        child: new RepaintBoundary(
          child: new Container(
              decoration: new BoxDecoration(
                  backgroundColor: Colors.white.withOpacity(
                    lerpDouble(0.0, 1.0, _quickSettingsAnimControl.value),
                  ),
                  borderRadius: new BorderRadius.circular(
                    4.0,
                  )),
              child: new QuickSettings(
                opacity: lerpDouble(
                  0.0,
                  1.0,
                  _quickSettingsAnimControl.value,
                ),
              )),
        ),
      );

  @override
  Widget build(BuildContext context) => new AnimatedBuilder(
      animation: _quickSettingsAnimControl,
      builder: (BuildContext c, Widget child) {
        return new Offstage(
          offstage:
              _quickSettingsAnimControl.status == AnimationStatus.dismissed,
          child: new Stack(
            children: [
              new Positioned(
                left: 0.0,
                top: 0.0,
                right: 0.0,
                bottom: 0.0,
                child: new IgnorePointer(
                  child: new Container(
                    decoration: new BoxDecoration(
                      backgroundColor: Color.lerp(Colors.transparent,
                          Colors.black87, _quickSettingsAnimControl.value),
                    ),
                  ),
                ),
              ),
              new Positioned(
                left: 0.0,
                top: 0.0,
                right: 0.0,
                bottom: 0.0,
                child: new Offstage(
                  offstage: !(_quickSettingsAnimControl.status ==
                          AnimationStatus.completed ||
                      _quickSettingsAnimControl.status ==
                          AnimationStatus.forward),
                  child: new GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      hide();
                    },
                  ),
                ),
              ),
              new Positioned(
                bottom: lerpDouble(8.0, 8.0 + config.minimizedNowBarHeight,
                    _quickSettingsAnimControl.value),
                left: 8.0,
                right: 8.0,
                child: _buildQuickSettingsOverlayContent(),
              ),
            ],
          ),
        );
      });
}

class QuickSettings extends StatefulWidget {
  final double opacity;

  QuickSettings({this.opacity});

  @override
  _QuickSettingsState createState() => new _QuickSettingsState();
}

class _QuickSettingsState extends State<QuickSettings> {
  double _volumeSliderValue = 0.0;
  double _brightnessSliderValue = 0.0;

  final GlobalKey _kAirplaneModeToggle = new GlobalKey();
  final GlobalKey _kDoNotDisturbModeToggle = new GlobalKey();
  final GlobalKey _kScreenRotationToggle = new GlobalKey();

  Widget _divider({double opacity: 1.0}) {
    return new Divider(
      height: 4.0,
      color: Colors.grey[300].withOpacity(opacity),
    );
  }

  Widget _volumeIconSlider() => new IconSlider(
        value: _volumeSliderValue,
        min: 0.0,
        max: 100.0,
        activeColor: _kActiveSliderColor,
        thumbImage: new AssetImage(_kVolumeUpGrey600),
        onChanged: (double value) {
          setState(() {
            _volumeSliderValue = value;
          });
        },
      );

  Widget _brightnessIconSlider() => new IconSlider(
        value: _brightnessSliderValue,
        min: 0.0,
        max: 100.0,
        activeColor: _kActiveSliderColor,
        thumbImage: new AssetImage(_kBrightnessHighGrey600),
        onChanged: (double value) {
          setState(() {
            _brightnessSliderValue = value;
          });
        },
      );

  Widget _airplaneModeToggleIcon() => new ToggleIcon(
        key: _kAirplaneModeToggle,
        imageList: [
          _kAirplaneModeInactiveGrey600,
          _kAirplaneModeActiveBlack,
        ],
        initialImageIndex: 1,
        width: _kIconSize,
        height: _kIconSize,
      );

  Widget _doNotDisturbToggleIcon() => new ToggleIcon(
        key: _kDoNotDisturbModeToggle,
        imageList: [
          _kDoNoDisturbOnBlack,
          _kDoNoDisturbOffGrey600,
        ],
        initialImageIndex: 0,
        width: _kIconSize,
        height: _kIconSize,
      );

  Widget _screenRotationToggleIcon() => new ToggleIcon(
        key: _kScreenRotationToggle,
        imageList: [
          kScreenLockRotationBlack,
          kScreenRotationBlack,
        ],
        initialImageIndex: 0,
        width: _kIconSize,
        height: _kIconSize,
      );

  Widget _buildForNarrowScreen(BuildContext context) {
    return new Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          new Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: _volumeIconSlider()),
          new Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: _brightnessIconSlider()),
          new Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: _divider()),
          new Row(children: [
            new Flexible(
              flex: 1,
              child: _airplaneModeToggleIcon(),
            ),
            new Flexible(
              flex: 1,
              child: _doNotDisturbToggleIcon(),
            ),
            new Flexible(
              flex: 1,
              child: _screenRotationToggleIcon(),
            ),
          ]),
        ]);
  }

  Widget _buildForWideScreen(BuildContext context) => new Row(children: [
        new Flexible(
          flex: 3,
          child: _volumeIconSlider(),
        ),
        new Flexible(
          flex: 3,
          child: _brightnessIconSlider(),
        ),
        new Flexible(
          flex: 1,
          child: _airplaneModeToggleIcon(),
        ),
        new Flexible(
          flex: 1,
          child: _doNotDisturbToggleIcon(),
        ),
        new Flexible(
          flex: 1,
          child: _screenRotationToggleIcon(),
        ),
      ]);

  @override
  Widget build(BuildContext context) {
    return new Material(
      type: MaterialType.canvas,
      color: Colors.transparent,
      child: new Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          new Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: new LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) =>
                  new Opacity(
                    opacity: config.opacity,
                    child: (constraints.maxWidth > _kMultiColumnWidthThreshold)
                        ? _buildForWideScreen(context)
                        : _buildForNarrowScreen(context),
                  ),
            ),
          ),
          _divider(opacity: config.opacity),
          new GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              print('Make Inline Quick Settings into Story!');
            },
            child: new Container(
              padding: const EdgeInsets.all(16.0),
              child: new Opacity(
                opacity: config.opacity,
                child: new Text(
                  'MORE',
                  textAlign: TextAlign.center,
                  style: new TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
