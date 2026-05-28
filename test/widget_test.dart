import 'package:audiobooks/theme/audiobook_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('theme builder returns light and dark Material 3 themes', () {
    final light = AudiobookTheme.light();
    final dark = AudiobookTheme.dark();
    expect(light.useMaterial3, isTrue);
    expect(dark.useMaterial3, isTrue);
    expect(light.brightness, isNot(equals(dark.brightness)));
  });
}
