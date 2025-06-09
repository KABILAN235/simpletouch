import 'package:flutter/material.dart';
import 'package:simpletouch/models/ac.dart';

Map<Brightness, ThemeData> getThemesForACMode(
  ACMode? mode,
  ThemeData baseLightTheme,
  ThemeData baseDarkTheme,
) {
  ThemeData themeFor(Brightness brightness, ThemeData baseTheme) {
    switch (mode) {
      case ACMode.cool:
        return baseTheme.copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blueAccent,
            brightness: brightness,
          ),
        );
      case ACMode.heat:
        return baseTheme.copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.orangeAccent,
            brightness: brightness,
          ),
        );
      case ACMode.dry:
        return baseTheme.copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.lightBlueAccent,
            brightness: brightness,
          ),
        );
      case ACMode.fan:
        return baseTheme.copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.greenAccent,
            brightness: brightness,
          ),
        );
      case ACMode.auto:
        return baseTheme.copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.indigoAccent,
            brightness: brightness,
          ),
        );
      default:
        return baseTheme;
    }
  }

  return {
    Brightness.light: themeFor(Brightness.light, baseLightTheme),
    Brightness.dark: themeFor(Brightness.dark, baseDarkTheme),
  };
}
