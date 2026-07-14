import 'dart:io';

import 'package:dio/dio.dart';
import 'package:lendflow/core/error/exceptions.dart';
import 'package:lendflow/core/network/api_endpoints.dart';
import 'package:lendflow/features/documents/data/models/kyc_document_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote data source for KYC document operations using Supabase Storage.
///
/// Handles file uploads, listing, signed URL generation, and deletion
/// for borrower KYC documents stored in a private Supabase storage bucket.
class DocumentRemoteDataSource {
  final SupabaseClient _supabaseClient;
  final Dio _dio;

  /// The Supabase storage bucket name for KYC documents.
  static const _bucketName = 'kyc-documents';

  DocumentRemoteDataSource({
    required SupabaseClient supabaseClient,
    required Dio dio,
  })  : _supabaseClient = supabaseClient,
        _dio = dio;

  /// Upload a KYC document file to Supabase Storage.
  ///
  /// The file is stored in a path structured as:
  /// `{borrowerId}/{documentType}/{timestamp}_{filename}`
  ///
  /// Returns the created [KycDocumentModel] with the storage path.
  Future<KycDocumentModel> upload({
    required String borrowerId,
    required String documentType,
    required File file,
    required String fileName,
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      // Generate a unique storage path
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = '$borrowerId/$documentType/${timestamp}_$fileName';

      // Upload to Supabase Storage
      await _supabaseClient.storage.from(_bucketName).upload(
            storagePath,
            file,
            fileOptions: FileOptions(
              upsert: false,
              contentType: _contentType(fileName),
            ),
          );

      // Create a record in the documents table via the API
      final response = await _dio.post(
        ApiEndpoints.uploadsDocument,
        data: {
          'borrower_id': borrowerId,
          'document_type': documentType,
          'file_url': storagePath,
          'file_name': fileName,
        },
      );

      return KycDocumentModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    } on StorageException catch (e) {
      throw ServerException(
        message: 'Failed to upload document: ${e.message}',
        statusCode: e.statusCode,
      );
    } catch (e) {
      throw ServerException(
        message: 'Upload failed: ${e.toString()}',
      );
    }
  }

  /// List all KYC documents for a borrower.
  Future<List<KycDocumentModel>> list({
    required String borrowerId,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.uploadsDocument,
        queryParameters: {'borrower_id': borrowerId},
      );

      final data = response.data;
      if (data is List) {
        return data
            .map((json) =>
                KycDocumentModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      final documents = data['documents'] as List<dynamic>? ?? [];
      return documents
          .map((json) =>
              KycDocumentModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Generate a signed URL for secure document access.
  ///
  /// The signed URL expires after [expiresIn] seconds (default: 1 hour).
  /// This ensures that private documents are only accessible to
  /// authorized users with a time-limited URL.
  Future<String> getSignedUrl({
    required String filePath,
    int expiresIn = 3600,
  }) async {
    try {
      final signedUrl = await _supabaseClient.storage
          .from(_bucketName)
          .createSignedUrl(filePath, expiresIn);

      return signedUrl;
    } on StorageException catch (e) {
      throw ServerException(
        message: 'Failed to generate signed URL: ${e.message}',
        statusCode: e.statusCode,
      );
    }
  }

  /// Delete a KYC document from storage and the database.
  Future<void> delete({
    required String documentId,
    required String filePath,
  }) async {
    try {
      // Delete from Supabase Storage
      await _supabaseClient.storage
          .from(_bucketName)
          .remove([filePath]);

      // Delete the database record
      await _dio.delete(
        '${ApiEndpoints.uploadsDocument}/$documentId',
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    } on StorageException catch (e) {
      throw ServerException(
        message: 'Failed to delete document: ${e.message}',
        statusCode: e.statusCode,
      );
    }
  }

  /// Determine the content type based on the file extension.
  String _contentType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'gif' => 'image/gif',
      'pdf' => 'application/pdf',
      'webp' => 'image/webp',
      _ => 'application/octet-stream',
    };
  }

  // ── Private helpers ─────────────────────────────────────────────

  /// Map a [DioException] to the appropriate [AppException] subtype.
  AppException _mapDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const NetworkException(
          message: 'Connection timed out. Please try again.',
          isTimeout: true,
        );
      case DioExceptionType.connectionError:
        return const NetworkException(
          message: 'No internet connection. Please check your network.',
          isConnectionRefused: true,
        );
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 401) {
          return const AuthException(
            message: 'Session expired. Please sign in again.',
            tokenExpired: true,
            requiresReAuth: true,
          );
        }
        if (statusCode == 413) {
          return const ValidationException(
            message: 'File size exceeds the maximum allowed limit.',
          );
        }
        if (statusCode == 400 || statusCode == 422) {
          final data = e.response?.data;
          final fieldErrors = <String, String>{};
          if (data is Map<String, dynamic>) {
            final errors = data['errors'] as Map<String, dynamic>?;
            if (errors != null) {
              errors.forEach((key, value) {
                fieldErrors[key] = value.toString();
              });
            }
          }
          return ValidationException(
            message: data?['message'] as String? ?? 'Validation error.',
            statusCode: statusCode,
            fieldErrors: fieldErrors,
          );
        }
        return ServerException(
          message: 'Server error occurred. Please try again later.',
          statusCode: statusCode,
          responseBody: e.response?.data,
        );
      case DioExceptionType.cancel:
        return const NetworkException(message: 'Request was cancelled.');
      case DioExceptionType.badCertificate:
        return const NetworkException(
          message: 'Certificate verification failed.',
        );
      case DioExceptionType.unknown:
        return NetworkException(
          message: e.message ?? 'An unexpected error occurred.',
        );
    }
  }
}
