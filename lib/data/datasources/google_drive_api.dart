import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:path/path.dart' as p;
import '../../core/constants.dart';

class GoogleDriveApi {
  static drive.DriveApi? _driveApi;

  static Future<drive.DriveApi> _getDriveApi() async {
    if (_driveApi != null) return _driveApi!;
    final credentialsJson = await rootBundle.loadString('assets/credentials.json');
    final credentials = ServiceAccountCredentials.fromJson(json.decode(credentialsJson));
    final scopes = [drive.DriveApi.driveScope];
    final client = await clientViaServiceAccount(credentials, scopes);
    _driveApi = drive.DriveApi(client);
    return _driveApi!;
  }

  /// Sube los bytes de una imagen a la carpeta designada en Google Drive.
  /// Retorna la URL directa para visualización.
  static Future<String> uploadProductImage({
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      final driveApi = await _getDriveApi();
      final skuId = p.basenameWithoutExtension(fileName);

      // 1. Verificar si ya existía una imagen para este SKU y eliminarla
      await _deleteExistingFilesForSku(skuId);

      // 2. Crear metadata del archivo en Drive
      final fileMetadata = drive.File()
        ..name = fileName
        ..parents = [AppConstants.driveFolderId];

      final media = drive.Media(
        Stream.value(bytes),
        bytes.length,
        contentType: _getContentType(fileName),
      );

      final uploadedFile = await driveApi.files.create(
        fileMetadata,
        uploadMedia: media,
        $fields: 'id, name, webViewLink, webContentLink',
      );

      final fileId = uploadedFile.id;
      if (fileId == null) {
        throw Exception('No se pudo obtener el ID del archivo subido a Google Drive.');
      }

      // 3. Hacer el archivo legible públicamente para que la app pueda renderizarlo
      try {
        final permission = drive.Permission()
          ..role = 'reader'
          ..type = 'anyone';
        await driveApi.permissions.create(permission, fileId);
      } catch (_) {
        // En carpetas compartidas públicas, puede heredar los permisos automáticamente
      }

      // 4. Retornar enlace directo optimizado para visualización web/móvil
      return 'https://lh3.googleusercontent.com/d/$fileId';
    } catch (e) {
      throw Exception('Error al subir imagen a Google Drive: $e');
    }
  }

  /// Obtiene un mapa de SKU -> URL de imagen de todos los archivos en la carpeta de Drive
  static Future<Map<String, String>> getAllProductImages() async {
    try {
      final driveApi = await _getDriveApi();
      final query = "'${AppConstants.driveFolderId}' in parents and trashed = false";
      final fileList = await driveApi.files.list(
        q: query,
        $fields: 'files(id, name)',
        pageSize: 1000,
      );

      final Map<String, String> imageMap = {};
      final files = fileList.files ?? [];
      for (final f in files) {
        if (f.id != null && f.name != null) {
          final sku = p.basenameWithoutExtension(f.name!);
          // URL directa de renderizado de Google Drive
          imageMap[sku] = 'https://lh3.googleusercontent.com/d/${f.id}';
        }
      }
      return imageMap;
    } catch (e) {
      return {};
    }
  }

  /// Elimina los archivos asociados a un SKU en la carpeta de Drive
  static Future<void> deleteProductImage(String skuId) async {
    try {
      await _deleteExistingFilesForSku(skuId);
    } catch (e) {
      throw Exception('Error al eliminar imagen de Google Drive: $e');
    }
  }

  static Future<void> _deleteExistingFilesForSku(String skuId) async {
    final driveApi = await _getDriveApi();
    final query = "'${AppConstants.driveFolderId}' in parents and trashed = false";
    final fileList = await driveApi.files.list(
      q: query,
      $fields: 'files(id, name)',
    );

    final files = fileList.files ?? [];
    for (final f in files) {
      if (f.id != null && f.name != null) {
        final currentSku = p.basenameWithoutExtension(f.name!);
        if (currentSku.toLowerCase() == skuId.toLowerCase()) {
          try {
            await driveApi.files.delete(f.id!);
          } catch (_) {}
        }
      }
    }
  }

  static String _getContentType(String fileName) {
    final ext = p.extension(fileName).toLowerCase();
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }
}
