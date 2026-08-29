import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

/// 图片处理工具：压缩并持久化保存到应用目录
class ImageUtils {
  /// 最大宽度，超过则等比缩放
  static const int _maxWidth = 1200;

  /// JPEG 压缩质量
  static const int _quality = 80;

  /// 把拍摄/选择的图片压缩后保存到应用持久化目录，返回保存后的 File。
  /// Web 平台直接返回原文件（不做本地持久化）。
  static Future<File?> compressAndSaveImage(File sourceFile) async {
    if (kIsWeb) return sourceFile;

    try {
      final bytes = await sourceFile.readAsBytes();
      final original = img.decodeImage(bytes);
      if (original == null) return null;

      // 等比缩放，限制最大宽度
      img.Image target = original;
      if (original.width > _maxWidth) {
        target = img.copyResize(original, width: _maxWidth);
      }

      // JPEG 压缩
      final compressed = img.encodeJpg(target, quality: _quality);

      // 保存到应用 documents 目录下的 fruit_images 文件夹
      final dir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${dir.path}/fruit_images');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final random = Random().nextInt(100000).toString().padLeft(5, '0');
      final fileName = '${timestamp}_$random.jpg';
      final savedFile = File('${imagesDir.path}/$fileName');
      await savedFile.writeAsBytes(compressed);

      return savedFile;
    } catch (e) {
      debugPrint('Error compressing and saving image: $e');
      return null;
    }
  }
}
