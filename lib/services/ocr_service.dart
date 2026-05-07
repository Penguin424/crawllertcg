import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class OCRService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  Future<String?> recognizeTextFromImage(XFile image) async {
    try {
      final inputImage = InputImage.fromFilePath(image.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      if (recognizedText.text.isEmpty) {
        return null;
      }

      // Extract card name from recognized text
      // This is a basic implementation - you might want to add more sophisticated
      // logic to extract the card name specifically
      final lines = recognizedText.blocks
          .map((block) => block.text)
          .where((text) => text.trim().isNotEmpty)
          .toList();

      if (lines.isEmpty) return null;

      // Return the first non-empty line as the card name
      // You might want to implement more sophisticated logic here
      return lines.first.trim();
    } catch (e) {
      debugPrint('Error recognizing text: $e');
      return null;
    }
  }

  Future<List<String>> extractAllText(XFile image) async {
    try {
      final inputImage = InputImage.fromFilePath(image.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      return recognizedText.blocks
          .map((block) => block.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('Error extracting text: $e');
      return [];
    }
  }

  /// Crops an image to the specified rectangle and returns a new XFile
  /// [image] - The original image
  /// [cropRect] - Rectangle defining the crop area (x, y, width, height as percentages 0-1)
  Future<XFile?> cropImageToRectangle(
    XFile image, {
    required double x,
    required double y,
    required double width,
    required double height,
  }) async {
    try {
      // Read the image file
      final imageBytes = await image.readAsBytes();
      final originalImage = img.decodeImage(imageBytes);

      if (originalImage == null) {
        debugPrint('Failed to decode image');
        return null;
      }

      // Calculate pixel coordinates from percentages
      final cropX = (originalImage.width * x).round();
      final cropY = (originalImage.height * y).round();
      final cropWidth = (originalImage.width * width).round();
      final cropHeight = (originalImage.height * height).round();

      // Crop the image
      final croppedImage = img.copyCrop(
        originalImage,
        x: cropX,
        y: cropY,
        width: cropWidth,
        height: cropHeight,
      );

      // Save the cropped image to a temporary file
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final croppedPath = path.join(tempDir.path, 'cropped_$timestamp.jpg');

      final croppedFile = File(croppedPath);
      await croppedFile.writeAsBytes(img.encodeJpg(croppedImage));

      return XFile(croppedPath);
    } catch (e) {
      debugPrint('Error cropping image: $e');
      return null;
    }
  }

  /// Extracts all text from a cropped area of the image
  Future<List<String>> extractTextFromArea(
    XFile image, {
    required double x,
    required double y,
    required double width,
    required double height,
  }) async {
    final croppedImage = await cropImageToRectangle(
      image,
      x: x,
      y: y,
      width: width,
      height: height,
    );

    if (croppedImage == null) {
      return [];
    }

    return extractAllText(croppedImage);
  }

  void dispose() {
    _textRecognizer.close();
  }
}
