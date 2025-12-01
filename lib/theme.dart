import 'package:flutter/material.dart';

final ThemeData light = ThemeData(

  brightness: Brightness.light,
  primaryColor: Colors.blue,
  scaffoldBackgroundColor: Colors.white,

);

final ThemeData dark = ThemeData(

    brightness: Brightness.dark,
    primaryColor: Colors.green,
    scaffoldBackgroundColor: Colors.grey[900]

);

final ThemeData matrix = ThemeData(

  brightness: Brightness.dark,
  scaffoldBackgroundColor: Colors.black,
  canvasColor: Colors.black,

  colorScheme: ColorScheme.dark(
    primary: Colors.greenAccent[700]!, // neon green
    secondary: Colors.greenAccent[700]!,
    surface: Colors.grey[900]!,
    background: Colors.black,
    onPrimary: Colors.black,
    onSecondary: Colors.black,
    onSurface: Colors.greenAccent,
    onBackground: Colors.greenAccent,
    error: Colors.redAccent,
    onError: Colors.black,
  ),

  iconTheme: const IconThemeData(color: Colors.greenAccent),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.black,
    foregroundColor: Colors.greenAccent,
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.greenAccent[700]!,
      foregroundColor: Colors.black,
    ),
  ),


);