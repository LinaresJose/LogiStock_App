import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalImageStorageApi {
  static const String _prefPrefix = 'local_product_img_';

  /// Guarda los bytes de la imagen localmente en el almacenamiento del dispositivo
  /// En Android/iOS/Desktop: Guarda el archivo en ApplicationDocumentsDirectory y persiste la ruta
  /// En Web: Guarda en memoria/SharedPreferences o ruta local
  static Future<String> saveProductImage({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final skuId = p.basenameWithoutExtension(fileName).toUpperCase();

    if (kIsWeb) {
      // En Web no hay sistema de archivos nativo estándar, guardamos la referencia en prefs
      final prefs = await SharedPreferences.getInstance();
      final webKey = '$_prefPrefix$skuId';
      // Guardar nombre / base64
      await prefs.setString(webKey, fileName);
      return fileName;
    }

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(p.join(appDir.path, 'product_images'));
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      // Eliminar imagen anterior del mismo SKU si existía
      await deleteProductImage(skuId);

      final extension = p.extension(fileName).toLowerCase();
      final targetPath = p.join(imagesDir.path, '$skuId$extension');
      final file = File(targetPath);
      await file.writeAsBytes(bytes);

      // Guardar la ruta en SharedPreferences para persistencia rápida
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_prefPrefix$skuId', targetPath);

      return targetPath;
    } catch (e) {
      throw Exception('Error al guardar imagen en el dispositivo: $e');
    }
  }

  /// Obtiene la ruta local de la imagen de un producto por su SKU
  static Future<String?> getProductImagePath(String skuId) async {
    final cleanSku = skuId.trim().toUpperCase();

    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('$_prefPrefix$cleanSku');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPath = prefs.getString('$_prefPrefix$cleanSku');
      if (savedPath != null && await File(savedPath).exists()) {
        return savedPath;
      }

      // Fallback: buscar físicamente en la carpeta por si se reinstaló o migraron datos
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(p.join(appDir.path, 'product_images'));
      if (await imagesDir.exists()) {
        final files = imagesDir.listSync();
        for (final f in files) {
          if (f is File) {
            final fileSku = p.basenameWithoutExtension(f.path).toUpperCase();
            if (fileSku == cleanSku) {
              await prefs.setString('$_prefPrefix$cleanSku', f.path);
              return f.path;
            }
          }
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Devuelve un mapa con todos los SKU y sus rutas locales de imagen
  static Future<Map<String, String>> getAllProductImages() async {
    final Map<String, String> result = {};

    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith(_prefPrefix));
      for (final k in keys) {
        final sku = k.replaceFirst(_prefPrefix, '');
        final val = prefs.getString(k);
        if (val != null) result[sku] = val;
      }
      return result;
    }

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(p.join(appDir.path, 'product_images'));
      if (!await imagesDir.exists()) return {};

      final files = imagesDir.listSync();
      final prefs = await SharedPreferences.getInstance();

      for (final f in files) {
        if (f is File) {
          final sku = p.basenameWithoutExtension(f.path).toUpperCase();
          result[sku] = f.path;
          await prefs.setString('$_prefPrefix$sku', f.path);
        }
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  /// Elimina la imagen local del dispositivo asociada a un SKU
  static Future<void> deleteProductImage(String skuId) async {
    final cleanSku = skuId.trim().toUpperCase();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefPrefix$cleanSku');

    if (!kIsWeb) {
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final imagesDir = Directory(p.join(appDir.path, 'product_images'));
        if (await imagesDir.exists()) {
          final files = imagesDir.listSync();
          for (final f in files) {
            if (f is File) {
              final fileSku = p.basenameWithoutExtension(f.path).toUpperCase();
              if (fileSku == cleanSku) {
                await f.delete();
              }
            }
          }
        }
      } catch (_) {}
    }
  }
}
