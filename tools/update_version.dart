import 'dart:io';

/// 自动更新 pubspec.yaml 版本号
/// 规则：修订号+1，构建号+1
/// 例如：1.0.0+1 → 1.0.1+2

void main(List<String> args) {
  final noUpdate = args.contains('--no-update');
  final pubspecFile = File('pubspec.yaml');

  if (!pubspecFile.existsSync()) {
    stderr.writeln('错误: 找不到 pubspec.yaml 文件');
    exit(1);
  }

  var content = pubspecFile.readAsStringSync();

  // 正则匹配版本号：version: x.x.x+x
  final versionPattern = RegExp(r'version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)');
  final match = versionPattern.firstMatch(content);

  if (match == null) {
    stderr.writeln('错误: 无法在 pubspec.yaml 中找到有效的版本号格式 (例如: version: 1.0.0+1)');
    exit(1);
  }

  final major = match.group(1)!;
  final minor = match.group(2)!;
  final patch = int.parse(match.group(3)!);
  final build = int.parse(match.group(4)!);

  final oldVersion = '$major.$minor.$patch+$build';

  if (noUpdate) {
    stdout.writeln('跳过版本号更新，当前版本: $oldVersion');
    exit(0);
  }

  // 更新版本号：修订号+1，构建号+1
  final newPatch = patch + 1;
  final newBuild = build + 1;
  final newVersion = '$major.$minor.$newPatch+$newBuild';

  // 替换版本号
  content = content.replaceFirst(versionPattern, 'version: $newVersion');

  // 写入文件
  pubspecFile.writeAsStringSync(content);

  stdout.writeln('版本号已更新: $oldVersion → $newVersion');
  stdout.writeln('  修订号: $patch → $newPatch (+1)');
  stdout.writeln('  构建号: $build → $newBuild (+1)');
}
