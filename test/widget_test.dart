import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexiread/core/constants/app_strings.dart';
import 'package:lexiread/features/settings/presentation/controllers/settings_controller.dart';
import 'package:lexiread/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('LexiRead smoke test - verify action cards render',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const LexiReadApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Pastikan 3 kartu aksi utama tampil di layar beranda
    expect(find.text(AppStrings.actionCameraTitle), findsOneWidget);
    expect(find.text(AppStrings.actionUploadTitle), findsOneWidget);
    expect(find.text(AppStrings.actionPasteTitle), findsOneWidget);
  });
}
