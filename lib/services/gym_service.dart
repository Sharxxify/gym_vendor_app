import 'dart:convert';
import 'dart:typed_data';
import 'package:book_my_fit_vendor/core/utils/logs_utility.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../core/network/api_client.dart';

class GymService {
  /// Upload images/videos using customer backend endpoints.
  ///
  /// Images: POST http://13.49.66.20:5000/api/v1/upload/image
  /// Videos : POST http://13.49.66.20:5000/api/v1/upload/video
  ///
  /// For other file types (e.g. PDFs), we keep using the legacy presign endpoint.
  Future<Map<String, dynamic>> uploadFilePresign({
    required Object file, // Accept both File and XFile types
    required String purpose,
  }) async {
    try {
      // Extract filename: XFile has .name, anything else use toString split
      String fileName;
      if (file is XFile) {
        fileName = file.name;
      } else {
        fileName = file.toString().split('/').last.split('\\').last;
      }
      final extension = fileName.split('.').last.toLowerCase();

      // Determine content type
      String contentType;
      final isImage = ['jpg', 'jpeg', 'png'].contains(extension);
      final isVideo = [
        'mp4',
        'mov',
        'mkv',
        'avi',
        'webm',
        '3gp',
      ].contains(extension);
      final purposeLower = purpose.toLowerCase();
      final bool isVideoByPurpose = purposeLower.contains('video');
      final bool isImageByPurpose =
          purposeLower.contains('image') || purposeLower.contains('picture');

      final bool finalIsVideo = isVideo || isVideoByPurpose;
      final bool finalIsImage = isImage || isImageByPurpose;

      if (['jpg', 'jpeg'].contains(extension)) {
        contentType = 'image/jpeg';
      } else if (extension == 'png') {
        contentType = 'image/png';
      } else if (finalIsVideo) {
        // Keep mapping simple; backend can also inspect bytes.
        if (extension == 'mp4') contentType = 'video/mp4';
        else if (extension == 'webm') contentType = 'video/webm';
        else if (extension == 'mov') contentType = 'video/quicktime';
        else if (extension == 'mkv') contentType = 'video/x-matroska';
        else if (extension == 'avi') contentType = 'video/x-msvideo';
        else contentType = 'application/octet-stream';
      } else if (extension == 'pdf') {
        contentType = 'application/pdf';
      } else if (extension == 'txt') {
        contentType = 'text/plain';
      } else {
        contentType = 'application/octet-stream';
      }

      debugPrint('📤 Uploading file: $fileName ($purpose)');
      debugPrint('📤 Content-Type: $contentType');

      // Get auth token
      final token = await ApiClient.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No authentication token found',
        };
      }

      // Read file bytes
      final Uint8List fileBytes;
      if (file is XFile) {
        fileBytes = await file.readAsBytes();
      } else {
        // Assume it's a File from dart:io
        fileBytes = await (file as dynamic).readAsBytes();
      }
      debugPrint('📤 File size: ${fileBytes.length} bytes');

      // Choose upload endpoint:
      // - Images/videos go to customer backend (port 5000)
      // - Other file types (pdf/txt) keep legacy presign flow
      final String url = finalIsVideo
          ? 'http://13.60.180.100:5000/api/v1/upload/video'
          : (finalIsImage
              ? 'http://13.60.180.100:5000/api/v1/upload/image'
              : 'http://13.60.180.100:3000/api/v1/uploads/presign');

      // Headers matching curl command
      final headers = <String, String>{
        'Authorization': 'Bearer $token',
        'Content-Type': contentType,
        'x-file-name': fileName,
        'x-purpose': purpose,
      };

      // For PDF files, use raw bytes instead of JSON body
      if (extension == 'pdf') {
        debugPrint('📄 Using raw bytes for PDF upload');
        
        // Use application/pdf content type for PDF raw bytes
        final pdfHeaders = <String, String>{
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/pdf',
          'x-file-name': fileName,  // Required header
          'x-purpose': purpose,     // Required header
        };
        
        debugPrint('📤 PDF Upload Request: $url');
        debugPrint('📤 PDF Headers: $pdfHeaders');

        // Send PDF bytes as body (--data-binary equivalent)
        final response = await http.post(
          Uri.parse(url),
          headers: pdfHeaders,
          body: fileBytes,
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw Exception('PDF upload request timed out');
          },
        );

        debugPrint('📥 PDF Response Status: ${response.statusCode}');
        debugPrint('📥 PDF Response Body: ${response.body}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          final responseData = jsonDecode(response.body);
          
          if (responseData['success'] == true && responseData['data'] != null) {
            final data = responseData['data'];
            debugPrint('✅ PDF uploaded successfully: ${data['view_url']}');
            return {
              'success': true,
              'view_url': data['view_url'] ?? data['s3_url'],
              'file_name': data['file_name'],
              'file_key': data['file_key'],
              'purpose': purpose,
            };
          } else {
            debugPrint('❌ PDF upload failed: ${responseData['message']}');
            return {
              'success': false,
              'message': responseData['message'] ?? 'Failed to upload PDF',
            };
          }
        } else if (response.statusCode == 204) {
          debugPrint('⚠️ PDF upload returned 204 No Content - this might be a presign endpoint');
          debugPrint('⚠️ Response body: ${response.body}');
          // 204 No Content might be valid for some presign endpoints
          // Try to parse any response body or handle as success
          if (response.body.isNotEmpty) {
            try {
              final responseData = jsonDecode(response.body);
              if (responseData['success'] == true && responseData['data'] != null) {
                final data = responseData['data'];
                debugPrint('✅ PDF uploaded successfully (204): ${data['view_url']}');
                return {
                  'success': true,
                  'view_url': data['view_url'] ?? data['s3_url'],
                  'file_name': data['file_name'],
                  'file_key': data['file_key'],
                  'purpose': purpose,
                };
              }
            } catch (e) {
              debugPrint('⚠️ Could not parse 204 response body: $e');
            }
          }
          // If no body or parsing fails, treat as pending/partial success
          debugPrint('⚠️ PDF upload status: 204 No Content (presign endpoint)');
          return {
            'success': true,
            'message': 'Upload initiated (presign endpoint)',
            'status': 'pending',
          };
        } else {
          String errorMessage = 'Request failed with status ${response.statusCode}';
          try {
            final data = jsonDecode(response.body);
            errorMessage = data['message'] ?? errorMessage;
          } catch (_) {}
          
          debugPrint('❌ PDF upload error: $errorMessage');
          return {
            'success': false,
            'message': errorMessage,
          };
        }
      }

      debugPrint('📤 POST Request: $url');
      debugPrint('📤 Headers: $headers');

      // Send file bytes as body (--data-binary equivalent)
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: fileBytes,
      );

      debugPrint('📥 Response Status: ${response.statusCode}');
      debugPrint('📥 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);

        // New image/video format:
        // { success: true, message: "...", data: { url, file_key, file_name, mime_type, type } }
        if (responseData['success'] == true && responseData['data'] != null) {
          final data = responseData['data'];
          final viewUrl = data['url'] ?? data['view_url'] ?? data['s3_url'];

          return {
            'success': viewUrl != null,
            'view_url': viewUrl,
            'file_name': data['file_name'],
            'file_key': data['file_key'],
            'mime_type': data['mime_type'],
            'type': data['type'],
          };
        }

        // Legacy presign format fallback:
        // { success: true, data: { view_url, ... } } OR { success: true, upload: { s3_url, ... } }
        if (responseData['success'] == true && responseData['upload'] != null) {
          final upload = responseData['upload'];
          return {
            'success': true,
            'view_url': upload['s3_url'] ?? upload['view_url'],
            'file_name': upload['file_name'],
            'purpose': upload['purpose'],
            'expires_in': upload['expires_in'],
          };
        }

        // Legacy presign format fallback (older /api/v1/uploads/presign variants)
        if (responseData['success'] == true && responseData['data'] != null) {
          final data = responseData['data'];
          return {
            'success': true,
            'view_url': data['view_url'] ?? data['s3_url'],
            'file_name': data['file_name'],
            'file_key': data['file_key'],
          };
        }

        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to upload file',
        };
      } else {
        String errorMessage =
            'Request failed with status ${response.statusCode}';
        try {
          final data = jsonDecode(response.body);
          errorMessage = data['message'] ?? errorMessage;
        } catch (_) {}

        return {
          'success': false,
          'message': errorMessage,
        };
      }
    } catch (e) {
      debugPrint('❌ Upload error: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  /// Upload file and return view URL
  Future<String?> uploadFile(dynamic file, String purpose) async {
    final result = await uploadFilePresign(file: file, purpose: purpose);

    if (result['success'] == true && result['view_url'] != null) {
      debugPrint('✅ File uploaded successfully: ${result['view_url']}');
      return result['view_url'] as String;
    } else {
      debugPrint('❌ Failed to upload file: ${result['message']}');
      return null;
    }
  }

  /// Get presigned URL for file upload to S3 (legacy method, kept for compatibility)
  /// Uses JSON body approach
  Future<Map<String, dynamic>> getPresignedUrl({
    required String fileName,
    required String fileType,
    required String purpose,
  }) async {
    debugPrint('📤 Getting presigned URL for: $fileName ($purpose)');

    try {
      final token = await ApiClient.getToken();

      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final body = {
        'files': {
          'file_name': fileName,
          'file_type': fileType,
          'purpose': purpose,
        }
      };

      final url = '${ApiClient.baseUrl}/api/v1/uploads/presign';

      debugPrint('📤 POST Request: $url');
      debugPrint('📤 Body: $body');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      debugPrint('📥 Response Status: ${response.statusCode}');
      debugPrint('📥 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['upload'] != null) {
          final upload = data['upload'];
          return {
            'success': true,
            's3_url': upload['s3_url'],
            'expires_in': upload['expires_in'],
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Failed to get upload URL',
          };
        }
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ??
              'Request failed with status ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('❌ Error getting presigned URL: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  /// Create Gym Profile (Initial Setup)
  /// POST /api/v1/gym/create
  /// Auth: Authorization: Bearer <jwt token>
  Future<Map<String, dynamic>> createGymProfile(
      Map<String, dynamic> gymData) async {
    debugPrint('🏢 Creating gym profile...');

    // Print FULL log in terminal
    LogUtils.printFull('📦 Gym Data:\n${jsonEncode(gymData)}');

    /// Save FULL log to file - DISABLED FOR WEB (crashes path_provider)
    // await LogUtils.saveToFile('gym_logs.json', gymData);

    final response = await ApiClient.post('/api/v1/gym/create', body: gymData);

    debugPrint('📥 Create Gym Profile Response: ${response.data}');

    if (response.success && response.data != null) {
      final gymId = response.data!['gym_id'];
      if (gymId != null) {
        await ApiClient.saveGymId(gymId);
        // Mark user as no longer new
        await ApiClient.saveIsNewUser(false);
      }

      return {
        'success': true,
        'gym_id': gymId,
        'message':
            response.data!['message'] ?? 'Gym profile created successfully',
        'status': response.data!['status'] ?? 'pending_verification',
        'data': response.data,
      };
    } else {
      return {
        'success': false,
        'message': response.message ?? 'Failed to create gym profile',
        'errors': response.data?['errors'],
      };
    }
  }

  /// Get Gym Profile
  /// GET /api/v1/gym/profile
  /// Auth: Authorization: Bearer <jwt token>
  Future<Map<String, dynamic>> getGymProfile() async {
    debugPrint('📥 Fetching gym profile...');

    final response = await ApiClient.get('/api/v1/gym/profile');

    debugPrint('📥 Get Gym Profile Response: ${response.data}');

    if (response.success && response.data != null) {
      // Save gym_id if present in response
      if (response.data!['gym_id'] != null) {
        await ApiClient.saveGymId(response.data!['gym_id']);
      }

      return {
        'success': true,
        'data': response.data,
      };
    } else {
      return {
        'success': false,
        'message': response.message ?? 'Failed to fetch gym profile',
      };
    }
  }

  /// Update Gym Profile
  /// PATCH /api/v1/gym/profile
  /// Auth: Authorization: Bearer <jwt token>
  Future<Map<String, dynamic>> updateGymProfile(
      Map<String, dynamic> updateData) async {
    debugPrint('📝 Updating gym profile...');
    LogUtils.printFull('📦 Full Update Payload:\n${jsonEncode(updateData)}');

    final response =
        await ApiClient.patch('/api/v1/gym/profile', body: updateData);

    debugPrint('📥 Update Gym Profile Response: ${response.data}');

    if (response.success) {
      return {
        'success': true,
        'message':
            response.data?['message'] ?? 'Gym profile updated successfully',
        'data': response.data,
      };
    } else {
      return {
        'success': false,
        'message': response.message ?? 'Failed to update gym profile',
        'errors': response.data?['errors'],
      };
    }
  }

  /// Check if gym profile exists
  Future<bool> hasGymProfile() async {
    final gymId = await ApiClient.getGymId();
    return gymId != null && gymId.isNotEmpty;
  }
}
