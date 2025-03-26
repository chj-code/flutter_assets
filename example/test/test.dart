import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_assets/flutter_assets.dart';

void main() {
  /// Refresh Assets
  test('RefreshAssets', () async {
    await FlutterAssets.refresh(generateUnused: true);
  });

  /// Check Unused Assets
  test('CheckUnusedAssets', () async {
    await FlutterAssets.checkUnused();
  });
}
