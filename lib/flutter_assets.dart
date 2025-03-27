library flutter_assets;

import 'dart:io';

enum UnusedAssetsHandling {
  /// only print unused resources
  log,

  /// annotate unused resources code
  annotation,

  /// move unused resources to the specified folder
  moveToUnusedFolder,

  ///❗️❗️❗️Delete unused resources, please be careful❗️❗️❗️
  delete,
}

/// Assets code generation and management
class FlutterAssets {
  /// prefix
  static const String dirStr = "  /// directory: ";
  static const String startStr = "  static const ";
  static const String dividerStr =
      "\n--------------------------------------------------------------------------------------------\n\n";
  static const String unusedAssetsPath = "unused";
  static const int maxLineLength = 300;

  ///
  /// projectPath: Default auto read project root path
  ///
  /// imagePath: Resource file path， Default use：assets/images
  ///
  /// codePath:  Code file generation path， Default use：lib/app_res
  ///
  /// codeName: Code file generation name， Default use：app_image
  ///
  /// className: Generated class name， Default use：AppImages
  ///
  /// sortByLength: Sort by name length defaults to false, sort by letter
  ///
  /// generateUnused: Generate unused resources, default false
  ///
  static generate({
    String projectPath = "",
    String imagePath = "assets/images",
    String codePath = "lib/app_res",
    String codeName = "app_image",
    String className = "AppImages",
    bool sortByLength = false,
    bool generateUnused = false,
  }) async {
    // path
    if (projectPath.isEmpty) projectPath = Directory.current.path;
    if (className.isEmpty) className = "AppImages";
    String imageUri = "$projectPath/$imagePath";
    String resPath = "$projectPath/$codePath/$codeName.dart";

    print(
        "🔥 generate assets path info：\n  - ClassName: $className \n  - ImagePath: $imageUri \n  - CodePath:  $resPath \n$dividerStr");

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

    Map<String, List<String>> filePathMap = {'ZZnoDirFileList': []};

    Set<String> imgNameSet = {}; // 资源名称集合
    List<String> repeatImgList = [];

    print("🟣 start reading \n\n");

    /// Splicing the head together
    StringBuffer sb = StringBuffer();
    sb.write("class $className {\n");
    sb.write("${startStr}basePath = \"$imagePath\";\n");

    /// Recurse subdirectories
    await for (final entity in dir) {
      if (entity is! File) continue;
      String imgPath = entity.path.split("$imagePath/").last;
      if (!generateUnused && imgPath.startsWith(unusedAssetsPath)) {
        continue;
      }
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

    sb.write("}");

    var appImagesFile = File(resPath);
    bool isExistFile = await appImagesFile.exists();
    print("✅ read success \n\n");
    if (isExistFile == false) {
      print("🟣 create dart file: $codeName.dart \n\n");
      await appImagesFile.create(recursive: true);
      print("✅ $codeName.dart create success \n\n");

      print("🟢 start writing \n\n");
      await appImagesFile.writeAsString(sb.toString());
      print("✅ write success \n$dividerStr\n");
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
          print('🟣 assets have not changed');
          for (var element in addedLines) {
            print("  - $element");
          }
          print(dividerStr);
          print("🟢 start writing \n\n");
          await appImagesFile.writeAsString(sb.toString());
          print("✅ write success \n$dividerStr\n");
        } else {
          print('🟣 assets changed');
          print("🟢 start writing \n\n");
          await appImagesFile.writeAsString(sb.toString());
          print("✅ write success \n$dividerStr\n");
        }
      } else {
        print('🟢 assets unchanged');
        print(dividerStr);
      }

      if (repeatImgList.isNotEmpty) {
        print('⁉️ duplicate naming of assets');
        for (var element in repeatImgList) {
          print("⚠️ -$element");
        }
        print(dividerStr);
      }
    }
    print(
        '✅✅ generate and refresh success ✅✅\n\n------------- end -------------');
  }

  ///
  /// projectPath: Default auto read project root path
  ///
  /// imagePath: Resource file path， Default use：assets/images
  ///
  /// codePath:  Code file generation path， Default use：lib/app_res
  ///
  /// codeName: Code file generation name， Default use：app_image
  ///
  /// className: Generated class name， Default use：AppImages
  ///
  /// excludedPaths: To exclude unprocessed file paths (relative to the project root directory)  Default use：[]
  ///
  /// excludedNamePrefix：To exclude the prefix of the file name (The name prefix must be use FlutterAssets.generated())  Default use：[]
  /// ```dart
  ///  // sample
  ///  await FlutterAssets.checkUnused(excludedNamePrefix: ['iconArrow']);
  /// ```
  ///
  /// excludedFileSuffix：To exclude the suffix of the file  Default use：[]
  /// ```dart
  ///  // sample
  ///  await FlutterAssets.checkUnused(excludedFileSuffix: ['txt']);
  /// ```
  ///
  /// unusedAssetsHandling: Unused resources processing method  Default use：log
  ///
  static checkUnused({
    String projectPath = "",
    String imagePath = "assets/images",
    String codePath = "lib/app_res",
    String codeName = "app_image",
    String className = "AppImages",
    List<String> excludedPaths = const [],
    List<String> excludedNamePrefix = const [],
    List<String> excludedFileSuffix = const [],
    UnusedAssetsHandling unusedAssetsHandling = UnusedAssetsHandling.log,
  }) async {
    print(
        '\n\n🔥 check unused resources \n\n------------- start -------------\n\n');

    /// 从文件中提取 AppImages 常量
    Map<String, String> extractAppImagesConstants(String filePath) {
      final file = File(filePath);
      if (!file.existsSync()) {
        print('❗ codeName not found : $filePath');
        exit(1);
      }

      final content = file.readAsStringSync();
      final regex = RegExp(r'static const (\w+)\s*=\s*"\$basePath\/([^"]+)"');
      final matches = regex.allMatches(content);

      final result = <String, String>{};
      for (var match in matches) {
        final name = match.group(1)!;
        final relativePath = match.group(2)!;
        final fullPath = '$imagePath/$relativePath';
        result[name] = fullPath;
      }
      return result;
    }

    /// 要排除的文件路径（相对于项目根目录）
    final tempExcludedPaths = <String>[
      '$codePath/$codeName.dart',
      ...excludedPaths,
    ];

    final appImagesFilePath = '$codePath/$codeName.dart';

    final imageConstants = extractAppImagesConstants(appImagesFilePath);
    final usedConstants = <String>{};

    if (unusedAssetsHandling == UnusedAssetsHandling.moveToUnusedFolder) {
      if (!Directory('$imagePath/$unusedAssetsPath').existsSync()) {
        Directory('$imagePath/$unusedAssetsPath').createSync(recursive: true);
      }
    }

    // 获取 lib 下所有 Dart 文件（排除指定）
    final dartFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) =>
            f.path.endsWith('.dart') &&
            f.path != appImagesFilePath &&
            !tempExcludedPaths.any((exclude) => f.path.contains(exclude)))
        .toList();

    for (var file in dartFiles) {
      final content = file.readAsStringSync();
      for (var constName in imageConstants.keys) {
        if (content.contains('AppImages.$constName')) {
          usedConstants.add(constName);
        }
      }
    }

    final unusedConstants = imageConstants.keys
        .where((constName) => !usedConstants.contains(constName))
        .toSet();

    if (unusedConstants.isEmpty) {
      print('✅ all images are used');
      return;
    }

    print('🚧 start processing unused resources...');
    final appImagesFile = File(appImagesFilePath);
    final lines = appImagesFile.readAsLinesSync();
    final updatedLines = <String>[];

    for (var line in lines) {
      final trimmed = line.trim();
      final match =
          RegExp(r'static const (\w+)\s*=\s*"[^"]+";').firstMatch(trimmed);
      if (match != null) {
        final constName = match.group(1)!;
        if (excludedNamePrefix.isNotEmpty &&
            excludedNamePrefix
                .any((element) => constName.startsWith(element))) {
          updatedLines.add(line);
          continue;
        }

        if (excludedFileSuffix.isNotEmpty &&
            excludedFileSuffix
                .any((element) => trimmed.endsWith('$element";'))) {
          updatedLines.add(line);
          continue;
        }

        if (unusedConstants.contains(constName)) {
          switch (unusedAssetsHandling) {
            case UnusedAssetsHandling.log:
              updatedLines.add(line);
              print('⚠️ unused assets:$line');
              break;

            case UnusedAssetsHandling.annotation:
              if (!line.trimLeft().startsWith('//')) {
                print('📝 annotation resources: $constName');
                updatedLines.add('// $line');
              } else {
                updatedLines.add(line);
              }
              break;

            case UnusedAssetsHandling.moveToUnusedFolder:
              // 处理图片资源
              final assetPath = imageConstants[constName]!;
              if (assetPath.startsWith("$imagePath/$unusedAssetsPath")) {
                continue;
              }
              final file = File(assetPath);
              if (file.existsSync()) {
                try {
                  final fileName = assetPath.split('/').last;
                  final targetPath = '$imagePath/$unusedAssetsPath/$fileName';
                  file.renameSync(targetPath);
                  print('📦 moved to $targetPath');
                } catch (e) {
                  print('⚠️ moved failed: $assetPath\n$e');
                }
              }
              break;

            case UnusedAssetsHandling.delete:
              // 处理图片资源
              final assetPath = imageConstants[constName]!;
              final file = File(assetPath);
              if (file.existsSync()) {
                try {
                  file.deleteSync();
                  print('🗑️ delete resources: $assetPath');
                } catch (e) {
                  print('⚠️ delete failed: $assetPath\n$e');
                }
              }
              break;
          }
        } else {
          updatedLines.add(line);
        }
      } else {
        updatedLines.add(line);
      }
    }

    appImagesFile.writeAsStringSync(updatedLines.join('\n'));
    print('✅✅ check unused finish ✅✅\n\n------------- end -------------');
  }

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
