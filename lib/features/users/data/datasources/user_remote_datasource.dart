import 'package:dio/dio.dart';
import 'package:lendflow/core/error/exceptions.dart';
import 'package:lendflow/core/network/api_endpoints.dart';
import 'package:lendflow/features/users/data/models/user_management_model.dart';

/// Remote data source for admin user management operations using Dio.
///
/// All user CRUD and admin actions go through the backend API.
/// The Dio instance includes auth and error interceptors.
class UserRemoteDataSource {
  final Dio _dio;

  UserRemoteDataSource({required Dio dio}) : _dio = dio;

  /// List users with optional role filter, search, and pagination.
  ///
  /// Returns a paginated list of [UserManagementModel]s.
  Future<UserListResult> list({
    String? role,
    String? search,
    bool? isActive,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };
      if (role != null && role.isNotEmpty) {
        queryParams['role'] = role;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (isActive != null) {
        queryParams['is_active'] = isActive;
      }

      final response = await _dio.get(
        ApiEndpoints.users,
        queryParameters: queryParams,
      );

      final data = response.data as Map<String, dynamic>;
      final users = (data['users'] as List<dynamic>)
          .map((json) => UserManagementModel.fromJson(json as Map<String, dynamic>))
          .toList();
      final total = data['total'] as int? ?? users.length;

      return UserListResult(users: users, total: total);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Create a new user (admin only).
  ///
  /// Requires email, password, full name, and role assignment.
  Future<UserManagementModel> create({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? phone,
    String? branchId,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.users,
        data: {
          'email': email,
          'password': password,
          'full_name': fullName,
          'role': role,
          if (phone != null) 'phone': phone,
          if (branchId != null) 'branch_id': branchId,
        },
      );
      return UserManagementModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Deactivate a user account (admin only).
  ///
  /// Sets the user's `is_active` flag to `false`.
  /// Requires forced re-authentication before execution.
  Future<UserManagementModel> deactivate(String userId) async {
    try {
      final response = await _dio.patch(
        '${ApiEndpoints.users}/${userId}/deactivate',
      );
      return UserManagementModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Reactivate a deactivated user account (admin only).
  Future<UserManagementModel> reactivate(String userId) async {
    try {
      final response = await _dio.patch(
        '${ApiEndpoints.users}/${userId}/reactivate',
      );
      return UserManagementModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Reset a user's password (admin only).
  ///
  /// Sends a password reset link to the user's email.
  /// Requires forced re-authentication before execution.
  Future<void> resetPassword(String userId) async {
    try {
      await _dio.post(
        '${ApiEndpoints.users}/${userId}/reset-password',
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Force logout a user from all sessions (admin only).
  ///
  /// Revokes all refresh tokens for the given user.
  Future<void> forceLogout(String userId) async {
    try {
      await _dio.post(
        '${ApiEndpoints.users}/${userId}/force-logout',
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Update a user's role (admin only).
  ///
  /// Requires forced re-authentication for role elevation.
  Future<UserManagementModel> updateRole({
    required String userId,
    required String newRole,
  }) async {
    try {
      final response = await _dio.patch(
        '${ApiEndpoints.users}/${userId}/role',
        data: {'role': newRole},
      );
      return UserManagementModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
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
        if (statusCode == 403) {
          return const AuthException(
            message: 'You do not have permission to manage users.',
          );
        }
        if (statusCode == 404) {
          return const ServerException(
            message: 'User not found.',
            statusCode: 404,
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

/// Paginated result for user list queries.
class UserListResult {
  final List<UserManagementModel> users;
  final int total;

  const UserListResult({
    required this.users,
    required this.total,
  });
}
