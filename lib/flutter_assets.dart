library flutter_assets;

import 'dart:io';

class FlutterAssets {
  /// prefix
  static const String dirStr = "  /// directory: ";
  static const String startStr = "  static const ";
  static const String dividerStr =
      "\n--------------------------------------------------------------------------------------------\n\n";

  /// projectPath: 项目路径，自动读取项目根目录
  /// imagePath: 资源资源存放路径, 默认使用 assets/images
  /// codePath: 代码生成路径, 默认使用 lib/app_res
  /// codeName: 代码生成文件名称，默认使用 app_image
  /// className: 生成的类名，默认使用 AppImages
  /// maxLineLength: 代码单行最大长度 默认80
  /// lengthSort: 是否按名字长短排序 默认false ，按字母排序
  static refreshImages({
    String projectPath = "",
    String imagePath = "assets/images",
    String codePath = "lib/app_res",
    String codeName = "app_image",
    String className = "AppImages",
    int maxLineLength = 80,
    bool sortByLength = false,
  }) async {
    // path
    if (projectPath.isEmpty) projectPath = Directory.current.path;
    if (className.isEmpty) className = "AppImages";
    String imageUri = "$projectPath/$imagePath";
    String resPath = "$projectPath/$codePath/$codeName.dart";

    print("生成资源路径 (assets path)");
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

    Map<String, List<String>> filePathMap = {
      'ZZnoDirFileList': [],
    };

    Set<String> imgNameSet = {}; // 资源名称集合
    List<String> repeatImgList = [];

    print("🟣 开始读取（Start reading）\n\n");

    /// 拼接头部
    StringBuffer sb = StringBuffer();
    sb.write("class $className {\n");
    sb.write("${startStr}basePath = \"$imagePath\";\n");

    /// 递归子目录
    await for (final entity in dir) {
      if (entity is! File) continue;
      String imgPath = entity.path.split("$imagePath/").last;

      if (imgPath.split("/").last.split(".").length >= 2) {
        String imgName = imgPath.split("/").last.split(".").first;
        imgName = convertToCamelCase(imgName);
        if (imgName.isNotEmpty) {
          if (imgNameSet.contains(imgName)) {
            repeatImgList.add(imgPath);
            continue;
          } else {
            String imgStr = "$startStr$imgName = \"\$basePath/$imgPath\";";
            if (imgStr.length > maxLineLength) {
              imgStr = "$startStr$imgName =\n      \"\$basePath/$imgPath\";";
            }
            if (imgPath.split("/").length > 1) {
              String firstDirName = imgPath.split("/").first;
              // String noteDirName = dirStr + imgPath.split("/").first;
              if (!imgNameSet.contains(firstDirName)) {
                imgNameSet.add(firstDirName); // 记录目录注释名称(去重)
              }
              if (!filePathMap.keys.contains(firstDirName)) {
                filePathMap[firstDirName] = [];
              }
              imgNameSet.add(imgName);
              filePathMap[firstDirName]!.add(imgStr);
            } else {
              imgNameSet.add(imgName);
              filePathMap['ZZnoDirFileList']!.add(imgStr);
            }
          }
        }
      }
    }

    filePathMap.removeWhere((key, value) => value.isEmpty);

    for (var key in filePathMap.keys) {
      sb.writeln();
      if (filePathMap[key]!.isNotEmpty) {
        if (key != 'ZZnoDirFileList') {
          sb.write("$dirStr$key\n");
        } else {
          sb.write("$dirStr$imagePath\n");
        }
        if (sortByLength) {
          filePathMap[key]!
              .sort((key1, key2) => key1.length.compareTo(key2.length));
        } else {
          filePathMap[key]!.sort((key1, key2) => key1
              .replaceAll(startStr, '')
              .compareTo(key2.replaceAll(startStr, '')));
        }

        for (var element in filePathMap[key]!) {
          sb.write("$element\n");
        }
      }
    }

    /// 拼接尾部
    sb.write("}");

    var appImagesFile = File(resPath);
    bool isExistFile = await appImagesFile.exists();
    print("✅ 读取成功（Read success）\n\n");
    if (isExistFile == false) {
      print("🟣 创建dart文件$codeName.dart（Create dart file）\n\n");
      await appImagesFile.create(recursive: true);
      print("$codeName.dart创建成功（Create success）\n\n");

      print("🟢 开始写入（Start writing）\n\n");
      await appImagesFile.writeAsString(sb.toString());
      print("✅ 写入成功（Write success）\n$dividerStr\n");
    } else {
      /// 对比文件内容
      var oldFileString = await appImagesFile.readAsString();

      if (oldFileString != sb.toString()) {
        var oldLines = oldFileString.split("\n");
        var newLines = sb.toString().split("\n");
        final oldSet = Set<String>.from(oldLines);
        final newSet = Set<String>.from(newLines);
        final addedLines = newSet.difference(oldSet);

        if (addedLines.isNotEmpty) {
          print('🟣 资源发生改变（Images changed）');
          addedLines.forEach(print);
          print(dividerStr);
          print("🟢 开始写入（Start writing）\n\n");
          await appImagesFile.writeAsString(sb.toString());
          print("✅ 写入成功（Write success）\n$dividerStr\n");
        } else {
          print('🟣 资源发生变化（Images changed）');
          print("🟢 开始写入（Start writing）\n\n");
          await appImagesFile.writeAsString(sb.toString());
          print("✅ 写入成功（Write success）\n$dividerStr\n");
        }
      } else {
        print('🟢 资源未改变（Unchanged images）');
        print(dividerStr);
      }

      if (repeatImgList.isNotEmpty) {
        print('🔴 资源重复命名 (Repeatedly named images) ');
        repeatImgList.forEach(print);
        print(dividerStr);
      }
    }
    print('✅ 执行成功 （Success）');
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
      if (i > 0 && word.isNotEmpty) {
        // 首字母大写
        word = word[0].toUpperCase() + word.substring(1);
      }
      camelCase += word;
    }
    return camelCase;
  }
}
