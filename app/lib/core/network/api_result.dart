import 'package:dio/dio.dart';

import '../error/failures.dart';
import '../error/result.dart';

Future<Result<T>> captureApi<T>(Future<T> Function() call) async {
  try {
    return Ok(await call());
  } on DioException catch (error) {
    final body = error.response?.data;
    if (body is Map<String, dynamic>) {
      final message = body['message']?.toString() ?? 'La requête a échoué.';
      final code = body['error']?.toString();
      final details = body['details'];
      final fields = <String, String>{};
      if (details is Map<String, dynamic>) {
        final fieldErrors = details['fieldErrors'];
        if (fieldErrors is Map<String, dynamic>) {
          for (final entry in fieldErrors.entries) {
            final value = entry.value;
            if (value is List && value.isNotEmpty) {
              fields[entry.key] = value.first.toString();
            }
          }
        }
      }
      if (code == 'MATRICULE_TAKEN') fields['matricule'] = message;
      if (code == 'EMAIL_TAKEN') fields['email'] = message;
      if (fields.isNotEmpty ||
          error.response?.statusCode == 400 ||
          error.response?.statusCode == 422) {
        return Err(ValidationFailure(message, fields: fields, code: code));
      }
      return Err(ServerFailure(message, code: code));
    }
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return const Err(NetworkFailure());
    }
    return Err(ServerFailure(error.message ?? 'La requête a échoué.'));
  } catch (_) {
    return const Err(UnknownFailure());
  }
}
