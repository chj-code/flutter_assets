import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_assets/flutter_assets.dart';

void main() {
  test('RefreshAssets', () async {
    /// projectPath: 项目路径，自动读取项目根目录
    /// imagePath: 图片资源存放路径, 默认 assets/images
    /// codePath: 代码生成路径, 默认使用 lib/app_res
    /// codeName: 代码生成文件名称，默认使用 app_image
    /// className: 生成的类名，默认使用 AppImages
    /// maxLineLength: 代码单行最大长度
    FlutterAssets.refreshImages(
      projectPath: "",
      imagePath: "assets/images",
      codePath: "lib/app_res",
      codeName: "app_image",
      className: "AppImages",
      maxLineLength: 80,
    );
  });
}
