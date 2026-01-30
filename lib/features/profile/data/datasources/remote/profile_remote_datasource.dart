import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_sync_new/core/api/api_client.dart';
import 'package:play_sync_new/core/api/api_endpoints.dart';
import 'package:play_sync_new/features/profile/data/datasources/profile_datasource.dart';
import 'package:play_sync_new/features/profile/data/models/profile_response_model.dart';

final profileRemoteDatasourceProvider = Provider<ProfileRemoteDataSource>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return ProfileRemoteDataSource(apiClient: apiClient);
});

/// Remote data source for profile - Handles API calls
class ProfileRemoteDataSource implements IProfileDataSource {
  final ApiClient _apiClient;

  ProfileRemoteDataSource({required ApiClient apiClient}) : _apiClient = apiClient;

  /// ========== GET PROFILE ==========
  @override
  Future<ProfileResponseModel> getProfile() async {
    try {
      debugPrint('[PROFILE API] Getting profile');
      debugPrint('[PROFILE API] Endpoint: ${ApiEndpoints.baseUrl}${ApiEndpoints.getProfile}');

      final response = await _apiClient.get(ApiEndpoints.getProfile);

      debugPrint('[PROFILE API] Response: ${response.data}');
      return ProfileResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// ========== UPDATE PROFILE ==========
  @override
  Future<ProfileResponseModel> updateProfile(
    Map<String, dynamic> profileData, {
    XFile? profilePicture,
  }) async {
    try {
      debugPrint('[PROFILE API] Updating profile: $profileData');
      debugPrint('[PROFILE API] Has profile picture: ${profilePicture != null}');
      debugPrint('[PROFILE API] Endpoint: ${ApiEndpoints.baseUrl}${ApiEndpoints.updateProfile}');

      Response response;

      // If profile picture is provided, send as multipart/form-data
      if (profilePicture != null) {
        final FormData formData = FormData();

        // Add all text fields
        profileData.forEach((key, value) {
          if (value != null && value.toString().isNotEmpty) {
            formData.fields.add(MapEntry(key, value.toString()));
          }
        });

        // Add profile picture
        if (kIsWeb) {
          final bytes = await profilePicture.readAsBytes();
          formData.files.add(MapEntry(
            'profilePicture',
            MultipartFile.fromBytes(bytes, filename: profilePicture.name),
          ));
        } else {
          formData.files.add(MapEntry(
            'profilePicture',
            await MultipartFile.fromFile(
              profilePicture.path,
              filename: profilePicture.name,
            ),
          ));
        }

        debugPrint('[PROFILE API] Sending as multipart/form-data');
        response = await _apiClient.put(
          ApiEndpoints.updateProfile,
          data: formData,
        );
      } else {
        // Send as regular JSON
        debugPrint('[PROFILE API] Sending as JSON');
        response = await _apiClient.put(
          ApiEndpoints.updateProfile,
          data: profileData,
        );
      }

      debugPrint('[PROFILE API] Response: ${response.data}');
      return ProfileResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// ========== UPLOAD PROFILE PICTURE ==========
  @override
  Future<String> uploadProfilePicture(XFile image) async {
    try {
      debugPrint('[PROFILE API] Uploading profile picture: ${image.name}');
      
      final FormData formData = FormData();
      
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        formData.files.add(MapEntry(
          'file',
          MultipartFile.fromBytes(bytes, filename: image.name),
        ));
      } else {
        formData.files.add(MapEntry(
          'file',
          await MultipartFile.fromFile(image.path, filename: image.name),
        ));
      }

      final response = await _apiClient.post(
        ApiEndpoints.uploadProfilePicture,
        data: formData,
      );

      debugPrint('[PROFILE API] Response: ${response.data}');
      
      // Extract the image URL from response
      final imageUrl = response.data['data']?['profilePicture'] ?? 
                      response.data['profilePicture'] ?? 
                      response.data['avatar'] ??
                      response.data['url'] ??
                      '';
      
      String finalUrl = imageUrl;
      if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
        finalUrl = '${ApiEndpoints.imageBaseUrl}${imageUrl.startsWith('/') ? '' : '/'}$imageUrl';
      }
      
      return finalUrl;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// ========== UPLOAD COVER PICTURE ==========
  @override
  Future<String> uploadCoverPicture(XFile image) async {
    try {
      debugPrint('[PROFILE API] Uploading cover picture: ${image.name}');
      
      final FormData formData = FormData();
      
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        formData.files.add(MapEntry(
          'file',
          MultipartFile.fromBytes(bytes, filename: image.name),
        ));
      } else {
        formData.files.add(MapEntry(
          'file',
          await MultipartFile.fromFile(image.path, filename: image.name),
        ));
      }

      final response = await _apiClient.post(
        ApiEndpoints.uploadCoverPicture,
        data: formData,
      );

      String imageUrl = response.data['url'] ?? '';
      if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
        imageUrl = '${ApiEndpoints.imageBaseUrl}${imageUrl.startsWith('/') ? '' : '/'}$imageUrl';
      }
      return imageUrl;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// ========== UPLOAD GALLERY PICTURES ==========
  @override
  Future<List<String>> uploadGalleryPictures(List<XFile> images) async {
    try {
      debugPrint('[PROFILE API] Uploading ${images.length} gallery pictures');
      
      final FormData formData = FormData();
      
      for (var image in images) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          formData.files.add(MapEntry(
            'files',
            MultipartFile.fromBytes(bytes, filename: image.name),
          ));
        } else {
          formData.files.add(MapEntry(
            'files',
            await MultipartFile.fromFile(image.path, filename: image.name),
          ));
        }
      }

      final response = await _apiClient.post(
        ApiEndpoints.uploadGalleryPictures,
        data: formData,
      );

      final List<dynamic> urls = response.data['urls'] ?? [];
      return urls.map((e) {
        String url = e.toString();
        if (url.isNotEmpty && !url.startsWith('http')) {
          url = '${ApiEndpoints.imageBaseUrl}${url.startsWith('/') ? '' : '/'}$url';
        }
        return url;
      }).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// ========== DELETE PROFILE PICTURE ==========
  @override
  Future<bool> deleteProfilePicture() async {
    try {
      debugPrint('[PROFILE API] Deleting profile picture');
      debugPrint('[PROFILE API] Endpoint: ${ApiEndpoints.baseUrl}${ApiEndpoints.deleteProfilePicture}');

      await _apiClient.delete(ApiEndpoints.deleteProfilePicture);

      debugPrint('[PROFILE API] Profile picture deleted successfully');
      return true;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Handle Dio errors and return meaningful exception
  Exception _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('Connection timeout. Please try again.');

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final responseData = e.response?.data;
        debugPrint('[PROFILE API ERROR] Status: $statusCode, Response: $responseData');
        
        final message = (responseData is Map)
            ? (responseData['message'] ?? responseData['error'] ?? 'Unknown error')
            : responseData?.toString() ?? 'Unknown error';

        switch (statusCode) {
          case 400:
            return Exception('Bad request: $message');
          case 401:
            return Exception('Unauthorized. Please login again.');
          case 403:
            return Exception('Access denied');
          case 404:
            return Exception('Profile not found');
          case 413:
            return Exception('File too large');
          case 422:
            return Exception('Validation error: $message');
          case 500:
            return Exception('Server error: $message');
          default:
            return Exception('Error: $message');
        }

      case DioExceptionType.connectionError:
        return Exception('No internet connection');

      case DioExceptionType.cancel:
        return Exception('Request cancelled');

      default:
        return Exception('Something went wrong');
    }
  }
}
