import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path_helper;

class ProgressMultipartRequest extends http.MultipartRequest {
  final void Function(int bytesUploaded, int totalBytes) onProgress;

  ProgressMultipartRequest(
    super.method,
    super.url, {
    required this.onProgress,
  });

  @override
  http.ByteStream finalize() {
    final byteStream = super.finalize();
    final total = contentLength;
    int bytesUploaded = 0;

    final transformer = StreamTransformer<List<int>, List<int>>.fromHandlers(
      handleData: (data, sink) {
        bytesUploaded += data.length;
        onProgress(bytesUploaded, total);
        sink.add(data);
      },
    );

    return http.ByteStream(byteStream.transform(transformer));
  }
}

class CloudinaryService {
  static const String _cloudName = String.fromEnvironment('CLOUDINARY_CLOUD_NAME', defaultValue: 'dsbchkcbb');
  static const String _uploadPreset = String.fromEnvironment('CLOUDINARY_UPLOAD_PRESET', defaultValue: 'eduzio_preset');
  static const String _apiKey = String.fromEnvironment('CLOUDINARY_API_KEY', defaultValue: '699218753457135');
  static const String _apiSecret = String.fromEnvironment('CLOUDINARY_API_SECRET', defaultValue: 'Q-0kt7dtflzOKzyrgeeSyFXY4m8');

  /// Compress image bytes using the pure-Dart image package
  Future<Uint8List> _compressImage(Uint8List bytes) async {
    return compute((Uint8List data) {
      final decoded = img.decodeImage(data);
      if (decoded == null) return data;
      
      // Limit size to max width 1200px
      img.Image resized = decoded;
      if (decoded.width > 1200) {
        resized = img.copyResize(decoded, width: 1200);
      }
      return Uint8List.fromList(img.encodeJpg(resized, quality: 80));
    }, bytes);
  }

  /// Upload file using bytes (fully web compatible)
  Future<String> uploadFileBytes({
    required Uint8List bytes,
    required String fileName,
    required String folder,
    required void Function(double progress) onProgress,
    http.Client? client,
  }) async {
    final httpClient = client ?? http.Client();
    try {
      final extension = path_helper.extension(fileName).toLowerCase();
      final isImage = ['.jpg', '.jpeg', '.png', '.webp'].contains(extension);
      final resourceType = isImage ? 'image' : 'raw';

      Uint8List fileBytes = bytes;
      if (isImage) {
        // Compress images before upload
        fileBytes = await _compressImage(fileBytes);
      }

      final url = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/$resourceType/upload');
      final request = ProgressMultipartRequest(
        'POST',
        url,
        onProgress: (uploaded, total) {
          final progressPercent = total > 0 ? (uploaded / total) : 0.0;
          onProgress(progressPercent);
        },
      );

      request.fields['upload_preset'] = _uploadPreset;
      request.fields['folder'] = folder;

      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
      );
      request.files.add(multipartFile);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        return decoded['secure_url'] as String;
      } else {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        final errorMsg = decoded['error']?['message'] as String? ?? 'Cloudinary upload failed';
        throw Exception(errorMsg);
      }
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }

  /// Upload file to Cloudinary with progress monitoring (reads bytes natively)
  Future<String> uploadFile({
    required String filePath,
    required String fileName,
    required String folder,
    required void Function(double progress) onProgress,
    http.Client? client,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File not found at path: $filePath');
    }
    final bytes = await file.readAsBytes();
    return uploadFileBytes(
      bytes: bytes,
      fileName: fileName,
      folder: folder,
      onProgress: onProgress,
      client: client,
    );
  }

  /// Signed deletion of files from Cloudinary
  Future<void> deleteFile(String fileUrl) async {
    if (_apiKey.isEmpty || _apiSecret.isEmpty) {
      debugPrint('Cloudinary credentials missing, skipping Cloudinary deletion.');
      return;
    }

    try {
      final publicId = _extractPublicId(fileUrl);
      if (publicId == null) return;

      final isRaw = fileUrl.contains('/raw/');
      final resourceType = isRaw ? 'raw' : 'image';
      
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final signature = _generateSignature(publicId, timestamp);

      final url = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/$resourceType/destroy');
      final response = await http.post(url, body: {
        'public_id': publicId,
        'api_key': _apiKey,
        'timestamp': timestamp.toString(),
        'signature': signature,
      });

      if (response.statusCode != 200) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        final errorMsg = decoded['error']?['message'] as String? ?? 'Cloudinary delete failed';
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint('Cloudinary deletion failed: $e');
      rethrow;
    }
  }

  String? _extractPublicId(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      final uploadIndex = segments.indexOf('upload');
      if (uploadIndex == -1 || uploadIndex + 2 >= segments.length) return null;
      
      // Public ID includes folder path and filename without extension
      final idSegments = segments.sublist(uploadIndex + 2);
      final lastSegment = idSegments.last;
      final dotIndex = lastSegment.lastIndexOf('.');
      if (dotIndex != -1) {
        idSegments[idSegments.length - 1] = lastSegment.substring(0, dotIndex);
      }
      return idSegments.join('/');
    } catch (_) {
      return null;
    }
  }

  String _generateSignature(String publicId, int timestamp) {
    final payload = 'public_id=$publicId&timestamp=$timestamp$_apiSecret';
    return sha1.convert(utf8.encode(payload)).toString();
  }
}
