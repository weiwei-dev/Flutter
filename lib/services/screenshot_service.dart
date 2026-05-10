import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:gal/gal.dart';
import 'dart:io';

class ScreenshotService {
  static final ScreenshotService instance =
      ScreenshotService._privateConstructor();

  ScreenshotService._privateConstructor();

  // 截取指定Widget的截图
  Future<Uint8List?> captureWidget(GlobalKey key) async {
    try {
      final RenderObject? boundary = key.currentContext?.findRenderObject();
      if (boundary is RenderRepaintBoundary) {
        final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
        final ByteData? byteData = await image.toByteData(
          format: ui.ImageByteFormat.png,
        );
        return byteData?.buffer.asUint8List();
      }
      return null;
    } catch (e) {
      debugPrint('Error capturing screenshot: $e');
      return null;
    }
  }

  // 保存截图到本地
  Future<String?> saveScreenshot(Uint8List imageBytes, String filename) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/screenshots';
      await Directory(path).create(recursive: true);
      final filePath = '$path/$filename.png';
      final file = File(filePath);
      await file.writeAsBytes(imageBytes);
      return filePath;
    } catch (e) {
      debugPrint('Error saving screenshot: $e');
      return null;
    }
  }

  // 拼接多个截图
  Future<Uint8List?> stitchScreenshots(List<Uint8List> imageBytesList) async {
    try {
      if (imageBytesList.isEmpty) return null;

      // 加载所有图片
      List<img.Image> images = [];
      for (var bytes in imageBytesList) {
        images.add(img.decodeImage(bytes)!);
      }

      // 计算总高度
      int totalHeight = images.fold(0, (sum, image) => sum + image.height);
      int width = images[0].width;

      // 创建新图片
      img.Image result = img.Image(width: width, height: totalHeight);

      // 拼接图片
      int currentHeight = 0;
      for (var image in images) {
        for (int y = 0; y < image.height; y++) {
          for (int x = 0; x < image.width; x++) {
            result.setPixel(x, currentHeight + y, image.getPixel(x, y));
          }
        }
        currentHeight += image.height;
      }

      // 转换为Uint8List
      return img.encodePng(result);
    } catch (e) {
      debugPrint('Error stitching screenshots: $e');
      return null;
    }
  }

  // 保存截图到相册
  Future<bool> saveToGallery(Uint8List imageBytes, {String? fileName}) async {
    try {
      // 检查权限
      final hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) {
        final granted = await Gal.requestAccess(toAlbum: true);
        if (!granted) {
          debugPrint('Gallery permission denied');
          return false;
        }
      }

      // 先将图片保存到临时文件
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
        '${tempDir.path}/${fileName ?? 'screenshot_${DateTime.now().millisecondsSinceEpoch}'}.png',
      );
      await tempFile.writeAsBytes(imageBytes);

      // 保存到相册
      await Gal.putImage(tempFile.path, album: '水果采购');

      debugPrint('Screenshot saved to gallery: ${tempFile.path}');
      return true;
    } on GalException catch (e) {
      debugPrint('Error saving screenshot to gallery: ${e.type}');
      return false;
    } catch (e) {
      debugPrint('Error saving screenshot to gallery: $e');
      return false;
    }
  }

  // 获取所有截图
  Future<List<File>> getScreenshots() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/screenshots';
      final dir = Directory(path);
      if (!await dir.exists()) return [];
      final files = await dir
          .list()
          .where((file) => file.path.endsWith('.png'))
          .toList();
      return files.map((file) => File(file.path)).toList();
    } catch (e) {
      debugPrint('Error getting screenshots: $e');
      return [];
    }
  }
}
