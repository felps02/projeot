import 'dart:convert';
import 'package:http/http.dart' as http;
import 'storage_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final StorageService _storage = StorageService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<ApiResponse> get(String url, {Map<String, String>? queryParams}) async {
    try {
      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers).timeout(
        const Duration(seconds: 30),
      );
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        statusCode: 0,
        message: _getErrorMessage(e),
      );
    }
  }

  Future<ApiResponse> post(String url, {Map<String, dynamic>? body}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 30));
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        statusCode: 0,
        message: _getErrorMessage(e),
      );
    }
  }

  Future<ApiResponse> put(String url, {Map<String, dynamic>? body}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 30));
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        statusCode: 0,
        message: _getErrorMessage(e),
      );
    }
  }

  Future<ApiResponse> delete(String url) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse(url),
        headers: headers,
      ).timeout(const Duration(seconds: 30));
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        statusCode: 0,
        message: _getErrorMessage(e),
      );
    }
  }

  ApiResponse _handleResponse(http.Response response) {
    final body = response.body.isNotEmpty
        ? jsonDecode(response.body)
        : null;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ApiResponse(
        success: true,
        statusCode: response.statusCode,
        data: body,
      );
    }

    String message = 'Erro desconhecido';
    if (body is Map && body.containsKey('message')) {
      message = body['message'];
    } else if (body is Map && body.containsKey('error')) {
      message = body['error'];
    } else {
      message = _getStatusMessage(response.statusCode);
    }

    return ApiResponse(
      success: false,
      statusCode: response.statusCode,
      message: message,
      data: body,
    );
  }

  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('SocketException') ||
        error.toString().contains('Connection refused')) {
      return 'Sem conexao com o servidor. Verifique sua internet.';
    }
    if (error.toString().contains('TimeoutException')) {
      return 'A requisicao expirou. Tente novamente.';
    }
    return 'Erro de conexao. Tente novamente mais tarde.';
  }

  String _getStatusMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Requisicao invalida.';
      case 401:
        return 'Sessao expirada. Faca login novamente.';
      case 403:
        return 'Voce nao tem permissao para esta acao.';
      case 404:
        return 'Recurso nao encontrado.';
      case 409:
        return 'Conflito com dados existentes.';
      case 422:
        return 'Dados invalidos. Verifique os campos.';
      case 500:
        return 'Erro interno do servidor.';
      default:
        return 'Erro ($statusCode). Tente novamente.';
    }
  }
}

class ApiResponse {
  final bool success;
  final int statusCode;
  final String? message;
  final dynamic data;

  ApiResponse({
    required this.success,
    required this.statusCode,
    this.message,
    this.data,
  });
}
