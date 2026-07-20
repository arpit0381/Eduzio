import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path_helper;

class ProgressMultipartRequest extends http.MultipartRequest {
  final void Function(int bytes, int totalBytes) onProgress;

  ProgressMultipartRequest(
    super.method,
    super.url, {
    required this.onProgress,
  });

  @override
  http.ByteStream finalize() {
    final byteStream = super.finalize();
    final int total = contentLength;
    int bytes = 0;

    final transformer = StreamTransformer<List<int>, List<int>>.fromHandlers(
      handleData: (data, sink) {
        bytes += data.length;
        onProgress(bytes, total);
        sink.add(data);
      },
    );

    return http.ByteStream(byteStream.transform(transformer));
  }
}

class CloudinaryService {
  static const String _cloudName = String.fromEnvironment('CLOUDINARY_CLOUD_NAME', defaultValue: 'dsbchkcbb');
  static const String _apiKey = String.fromEnvironment('CLOUDINARY_API_KEY', defaultValue: '699218753457135');
  static const String _apiSecret = String.fromEnvironment('CLOUDINARY_API_SECRET', defaultValue: 'Q-0kt7dtflzOKzyrgeeSyFXY4m8');

  Future<Uint8List> _compressImage(Uint8List bytes) async {
    return compute((data) {
      final decoded = img.decodeImage(data);
      if (decoded == null) return data;
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

      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      // Include use_filename and unique_filename in signature payload so Cloudinary preserves file extension (.pdf)
      final signaturePayload = 'folder=$folder&timestamp=$timestamp&unique_filename=true&use_filename=true$_apiSecret';
      final signature = sha1.convert(utf8.encode(signaturePayload)).toString();

      request.fields['api_key'] = _apiKey;
      request.fields['timestamp'] = timestamp.toString();
      request.fields['signature'] = signature;
      request.fields['folder'] = folder;
      request.fields['use_filename'] = 'true';
      request.fields['unique_filename'] = 'true';

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

  Future<void> deleteFile(String fileUrl) async {
    try {
      final publicId = _extractPublicId(fileUrl);
      if (publicId == null) return;

      final isRaw = fileUrl.contains('/raw/');
      final resourceType = isRaw ? 'raw' : 'image';

      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final signaturePayload = 'public_id=$publicId&timestamp=$timestamp$_apiSecret';
      final signature = sha1.convert(utf8.encode(signaturePayload)).toString();

      final response = await http.post(
        Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/$resourceType/destroy'),
        body: {
          'public_id': publicId,
          'api_key': _apiKey,
          'timestamp': timestamp.toString(),
          'signature': signature,
        },
      );

      if (response.statusCode != 200) {
        debugPrint('Cloudinary delete failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('Cloudinary delete exception: $e');
    }
  }

  String? _extractPublicId(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      final uploadIndex = segments.indexOf('upload');
      if (uploadIndex == -1 || uploadIndex + 1 >= segments.length) return null;

      List<String> targetSegments = segments.sublist(uploadIndex + 1);
      if (targetSegments.first.startsWith('v') && int.tryParse(targetSegments.first.substring(1)) != null) {
        targetSegments = targetSegments.sublist(1);
      }

      final fullPath = targetSegments.join('/');
      final extension = path_helper.extension(fullPath);
      if (extension.isNotEmpty) {
        return fullPath.substring(0, fullPath.length - extension.length);
      }
      return fullPath;
    } catch (e) {
      return null;
    }
  }
}
