library flutter_assets;

import 'dart:io';

class FlutterAssets {
  /// prefix
  static const String dirStr = "  /// directory: ";
  static const String startStr = "  static const ";
  static const String dividerStr =
      "\n--------------------------------------------------------------------------------------------\n\n";

  /// projectPath: 项目路径，自动读取项目根目录
  /// imagePath: 图片资源存放路径, 默认使用 assets/images
  /// codePath: 代码生成路径, 默认使用 lib/app_res
  /// codeName: 代码生成文件名称，默认使用 app_image
  /// className: 生成的类名，默认使用 AppImages
  /// maxLineLength: 代码单行最大长度 默认80
  static refreshImages({
    String projectPath = "",
    String imagePath = "assets/images",
    String codePath = "lib/app_res",
    String codeName = "app_image",
    String className = "AppImages",
    int maxLineLength = 80,
  }) async {
    // path
    if (projectPath.isEmpty) projectPath = Directory.current.path;
    if (className.isEmpty) className = "AppImages";
    String imageUri = "$projectPath/$imagePath";
    String resPath = "$projectPath/$codePath/$codeName.dart";

    print("ClassName：$className");
    print("ProjecUri：$projectPath");
    print("ImageUri：$imageUri");
    print("CodeUri：$resPath\n$dividerStr");

    // Directory
    Directory projectDir = Directory(imageUri);
    Stream<FileSystemEntity> dir = projectDir.list(
      recursive: true,
      followLinks: false,
    );

    bool isExist = await projectDir.exists();

    if (isExist == false) {
      print("❌ No image files found, please check the image path.$dividerStr");
      return;
    }

    List<String> imgPathList = []; // 图片路径集合
    Set<String> imgNameSet = {}; // 图片名称集合
    List<String> repeatImgList = [];

    print("开始读取（Start reading）\n\n");

    /// 拼接头部
    StringBuffer sb = StringBuffer();
    sb.write("class $className {\n");
    sb.write("${startStr}basePath = \"$imagePath\";\n");

    /// 递归子目录
    await for (final entity in dir) {
      if (entity is! File) continue;
      String imgPath = entity.path.split("$imagePath/").last;
      String imgName = imgPath.split("/").last.split(".").first;
      imgName = convertToCamelCase(imgName);

      if (imgNameSet.contains(imgName)) {
        repeatImgList.add(imgPath);
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
        if (imgStr.length > maxLineLength) {
          imgStr = "$startStr$imgName =\n      \"\$basePath/$imgPath\";";
        }
        imgNameSet.add(imgName);
        imgPathList.add(imgStr);
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
    print("读取成功（Read success）\n\n");
    var appImagesFile = File(resPath);
    bool isExistFile = await appImagesFile.exists();
    if (isExistFile == false) {
      print("创建dart文件$codeName.dart（Create dart file）\n\n");
      await appImagesFile.create(recursive: true);
      print("$codeName.dart创建成功（Create success）\n\n");
    } else {
      /// 对比文件内容
      var oldFileString = await appImagesFile.readAsString();
      var oldLines = oldFileString.split("\n");
      var newLines = sb.toString().split("\n");
      final oldSet = Set<String>.from(oldLines);
      final newSet = Set<String>.from(newLines);
      final addedLines = newSet.difference(oldSet);

      if (addedLines.isNotEmpty) {
        print('🟢 新增的图片（Newly added image）');
        addedLines.forEach(print);
        print(dividerStr);
      } else {
        print('🟢 未新增图片（No new images added）');
        print(dividerStr);
      }

      if (repeatImgList.isNotEmpty) {
        print('🔴 Repeatedly named images (重复命名的图片) ');
        repeatImgList.forEach(print);
        print(dividerStr);
      }
    }

    print("开始写入（Start writing）\n\n");
    await appImagesFile.writeAsString(sb.toString());
    print("✅ 写入成功（Write success）\n$dividerStr\n\n");
  }

  /// 下划线转驼峰
  static String convertToCamelCase(String input) {
    if (input.contains(" ")) input = input.replaceAll(" ", "_");
    if (input.contains("-")) input = input.replaceAll("-", "_");
    List<String> words = [];
    words = input.split('_');
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
