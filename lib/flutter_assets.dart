library flutter_assets;

import 'dart:io';

class FlutterAssets {
  /// 前缀设置
  static const String dirStr = "  /// directory: ";
  static const String startStr = "  static const ";

  static refresh() async {
    /// 项目图片资源目录
    String imagePath = "${Uri.base.path}assets/images/";

    String className = "AppImages";

    /// 项目中引用图片文件的类 文件路径
    String resPath = "${Uri.base.path}lib/app_res/app_image.dart";

    Directory projectDir = Directory(imagePath);
    Stream<FileSystemEntity> dir =
        projectDir.list(recursive: true, followLinks: false);

    List<String> imgPathList = []; // 图片路径集合
    Set<String> imgNameSet = {}; // 图片名称集合
    String basePath = "assets/images";

    /// 拼接头部
    StringBuffer sb = StringBuffer();
    sb.write("class $className {\n");
    sb.write("${startStr}basePath = \"$basePath\";\n\n");
    // String lastDirName = "";

    // 递归子目录
    await for (final entity in dir) {
      String imgPath = entity.path.split("/images/").last;
      if (imgPath.endsWith("png") ||
          imgPath.endsWith("PNG") ||
          imgPath.endsWith("jpg") ||
          imgPath.endsWith("JPG") ||
          imgPath.endsWith("gif") ||
          imgPath.endsWith("GIF") ||
          imgPath.endsWith("jpeg") ||
          imgPath.endsWith("JPEG") ||
          imgPath.endsWith("json")) {
        String imgName = imgPath.split("/").last.split(".").first;
        imgName = convertToCamelCase(imgName);

        if (imgNameSet.contains(imgName)) {
          print("图片命重复：$imgPath");
          continue;
        } else {
          if (imgPath.split("/").length > 1) {
            String firstDirName = imgPath.split("/").first;
            String noteDirName = dirStr + imgPath.split("/").first;
            if (!imgNameSet.contains(firstDirName)) {
              imgNameSet.add(firstDirName); // 记录目录注释名称(去重)
              imgPathList.add(noteDirName); // 添加目录注释
            }
          }

          String imgStr = "$startStr$imgName = \"\$basePath/$imgPath\";";

          /// 一行超过80个字符从等号处换行
          if (imgStr.length > 80) {
            // 代码格式化占两个空格
            imgStr = "$startStr$imgName =\n      \"\$basePath/$imgPath\";";
          }
          imgNameSet.add(imgName); // 记录图片名称(去重)
          imgPathList.add(imgStr); // 添加图片路径
        }
      }
    }

    /// 拼接内容
    for (var element in imgPathList) {
      if (element.startsWith("  ///")) {
        sb.writeln();
      }
      sb.write("$element\n");
    }

    /// 拼接尾部
    sb.write("}");

    // print(sb.toString());

    var appImagesFile = File(resPath);
    await appImagesFile.writeAsString(sb.toString());
    print("\n图片命名写入完成 (共${imgNameSet.length}张)");
  }

  /// 下划线转驼峰
  static String convertToCamelCase(String input) {
    List<String> words = input.split('_');
    String camelCase = '';
    for (int i = 0; i < words.length; i++) {
      String word = words[i];
      if (i > 0) {
        // 首字母大写
        word = word[0].toUpperCase() + word.substring(1);
      }
      camelCase += word;
    }
    return camelCase;
  }
}
