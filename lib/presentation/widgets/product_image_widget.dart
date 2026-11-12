import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ProductImageWidget extends StatelessWidget {
  final String imagePath;
  final double width;
  final double height;
  final double borderRadius;
  final BoxFit fit;

  const ProductImageWidget({
    super.key,
    required this.imagePath,
    this.width = 50,
    this.height = 50,
    this.borderRadius = 8,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (imagePath.trim().isEmpty) {
      return _buildPlaceholder();
    }

    Widget content;

    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      content = Image.network(
        imagePath,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      );
    } else if (kIsWeb) {
      content = Image.network(
        imagePath,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      );
    } else {
      final file = File(imagePath);
      if (file.existsSync()) {
        content = Image.file(
          file,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => _buildPlaceholder(),
        );
      } else {
        return _buildPlaceholder();
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: content,
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Icon(
        Icons.inventory_2_outlined,
        size: width * 0.5,
        color: Colors.grey.shade400,
      ),
    );
  }
}
