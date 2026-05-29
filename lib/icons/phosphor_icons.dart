// Phosphor icons as plain const IconData — compatible with Flutter's final
// IconData and fully tree-shakeable. The 'Phosphor' font asset ships with the
// flutter_phosphor_icons package; we deliberately do NOT import its Dart (which
// subclasses IconData and no longer compiles).
import 'package:flutter/widgets.dart';

class PhosphorIcons {
  PhosphorIcons._();
  static const _f = 'Phosphor';
  static const _p = 'flutter_phosphor_icons';
  static const IconData play = IconData(0xf52b, fontFamily: _f, fontPackage: _p);
  static const IconData pause = IconData(0xf509, fontFamily: _f, fontPackage: _p);
  static const IconData arrowsClockwise = IconData(0xf2a1, fontFamily: _f, fontPackage: _p);
  static const IconData bookOpen = IconData(0xf2e6, fontFamily: _f, fontPackage: _p);
  static const IconData books = IconData(0xf2eb, fontFamily: _f, fontPackage: _p);
  static const IconData booksFill = IconData(0xfb19, fontFamily: _f, fontPackage: _p);
  static const IconData trashSimple = IconData(0xf603, fontFamily: _f, fontPackage: _p);
  static const IconData heart = IconData(0xf460, fontFamily: _f, fontPackage: _p);
  static const IconData heartFill = IconData(0xfc8f, fontFamily: _f, fontPackage: _p);
  static const IconData checkCircle = IconData(0xf33f, fontFamily: _f, fontPackage: _p);
  static const IconData cloudSlash = IconData(0xf35e, fontFamily: _f, fontPackage: _p);
  static const IconData x = IconData(0xf642, fontFamily: _f, fontPackage: _p);
  static const IconData caretRight = IconData(0xf31c, fontFamily: _f, fontPackage: _p);
  static const IconData caretDown = IconData(0xf31a, fontFamily: _f, fontPackage: _p);
  static const IconData timer = IconData(0xf5f3, fontFamily: _f, fontPackage: _p);
  static const IconData stopCircle = IconData(0xf5b9, fontFamily: _f, fontPackage: _p);
  static const IconData star = IconData(0xf5b4, fontFamily: _f, fontPackage: _p);
  static const IconData gauge = IconData(0xf429, fontFamily: _f, fontPackage: _p);
  static const IconData skipBack = IconData(0xf586, fontFamily: _f, fontPackage: _p);
  static const IconData skipForward = IconData(0xf588, fontFamily: _f, fontPackage: _p);
  static const IconData shareNetwork = IconData(0xf56e, fontFamily: _f, fontPackage: _p);
  static const IconData gearSix = IconData(0xf42b, fontFamily: _f, fontPackage: _p);
  static const IconData magnifyingGlass = IconData(0xf4a8, fontFamily: _f, fontPackage: _p);
  static const IconData hardDrives = IconData(0xf45a, fontFamily: _f, fontPackage: _p);
  static const IconData arrowCounterClockwise = IconData(0xf268, fontFamily: _f, fontPackage: _p);
  static const IconData arrowClockwise = IconData(0xf267, fontFamily: _f, fontPackage: _p);
  static const IconData playCircle = IconData(0xf52c, fontFamily: _f, fontPackage: _p);
  static const IconData playCircleFill = IconData(0xfd59, fontFamily: _f, fontPackage: _p);
  static const IconData listBullets = IconData(0xf498, fontFamily: _f, fontPackage: _p);
  static const IconData info = IconData(0xf478, fontFamily: _f, fontPackage: _p);
  static const IconData house = IconData(0xf470, fontFamily: _f, fontPackage: _p);
  static const IconData houseFill = IconData(0xfc9e, fontFamily: _f, fontPackage: _p);
  static const IconData clockCounterClockwise = IconData(0xf354, fontFamily: _f, fontPackage: _p);
  static const IconData equalizer = IconData(0xf3c1, fontFamily: _f, fontPackage: _p);
  static const IconData downloadSimple = IconData(0xf3b2, fontFamily: _f, fontPackage: _p);
  static const IconData xCircle = IconData(0xf643, fontFamily: _f, fontPackage: _p);
  static const IconData bookmarkSimple = IconData(0xf2e8, fontFamily: _f, fontPackage: _p);
  static const IconData bookmarkSimpleFill = IconData(0xfb16, fontFamily: _f, fontPackage: _p);
  static const IconData moon = IconData(0xf4c4, fontFamily: _f, fontPackage: _p);
  static const IconData arrowLeft = IconData(0xf282, fontFamily: _f, fontPackage: _p);
  static const IconData squaresFour = IconData(0xf5af, fontFamily: _f, fontPackage: _p);
}
