import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_assets/flutter_assets.dart';

void main() {
  test('RefreshAssets', () async {
     await FlutterAssets.refreshImages();
  });
}