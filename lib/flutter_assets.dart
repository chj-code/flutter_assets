library flutter_assets;

import 'dart:io';

class FlutterAssets {
  /// prefix
  static const String dirStr = "  /// directory: ";
  static const String startStr = "  static const ";
  static const String dividerStr =
      "\n--------------------------------------------------------------------------------------------\n\n";

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
      print("❌No image files found, please check the image path.$dividerStr");
      return;
    }

    List<String> imgPathList = []; // 图片路径集合
    Set<String> imgNameSet = {}; // 图片名称集合
    List<String> repeatImgList = [];

    print("Start reading (开始读取)\n\n");

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
    print("Read success (读取成功)\n\n");
    var appImagesFile = File(resPath);
    bool isExistFile = await appImagesFile.exists();
    if (isExistFile == false) {
      print("Start create file $codeName.dart (创建dart文件)\n\n");
      await appImagesFile.create(recursive: true);
      print("Create file success (文件创建成功)\n\n");
    } else {
      /// 对比文件内容
      var oldFileString = await appImagesFile.readAsString();
      var oldLines = oldFileString.split("\n");
      var newLines = sb.toString().split("\n");
      final oldSet = Set<String>.from(oldLines);
      final newSet = Set<String>.from(newLines);
      final addedLines = newSet.difference(oldSet);

      if (addedLines.isNotEmpty) {
        print('🟢 Newly added image (新增的图片) 🟢');
        addedLines.forEach(print);
        print(dividerStr);
      }else{
        print('🟢 No new images added (没有新增的图片) 🟢');
        print(dividerStr);
      }

      if (repeatImgList.isNotEmpty) {
        print('🔴 Repeatedly named images (重复命名的图片) 🔴');
        repeatImgList.forEach(print);
        print(dividerStr);
      }
    }

    print("Start writing (开始写入)\n\n");
    await appImagesFile.writeAsString(sb.toString());
    print("✅ Write success (写入成功) ✅\n$dividerStr\n\n");
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
