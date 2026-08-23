import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Fails if anything under `lib/` imports the frozen Material library.
///
/// ## Why this test exists
///
/// This app is built on `package:material_ui`, the standalone Material
/// library. `package:flutter/material.dart` still exists and still compiles,
/// and its `ThemeData`, `TextTheme` and `Icon` are *different types* with
/// identical names. Importing it somewhere produces errors like "the argument
/// type 'ThemeData' can't be assigned to the parameter type 'ThemeData'",
/// which is among the least helpful messages the analyzer can emit.
///
/// There is no lint for a banned import, so this is the enforcement. If you
/// hit it: change the import to `package:material_ui/material_ui.dart`, or run
/// `dart fix --apply --code=migrate_design_widgets`.
///
/// Third-party packages that still use frozen Material are fine — that is what
/// `MaterialUiCompatibilityBridge` in `lib/main.dart` is for. This test only
/// governs our own source.
void main() {
  test('no file under lib/ imports package:flutter/material.dart', () {
    final offenders = <String>[];

    final lib = Directory('lib');
    for (final entity in lib.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;

      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.contains('package:flutter/material.dart') &&
            line.trimLeft().startsWith(RegExp(r'import|export'))) {
          offenders.add('${entity.path}:${i + 1}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'These files import the frozen Material library. Use\n'
          'package:material_ui/material_ui.dart instead:\n'
          '  ${offenders.join('\n  ')}',
    );
  });
}
