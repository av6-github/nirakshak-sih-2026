import 'dart:io' show Platform;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;

  static String get getBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080';
    }
    // Automatically use the computer's local Wi-Fi IP address for wireless app usage!
    // Both phone and PC must be on the same Wi-Fi network.
    return 'http://192.168.29.65:8080';
  }

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: getBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 300), // Increased to 5 mins for slow CPU OCR
        headers: {'Content-Type': 'application/json'},
      ),
    );
  }

  Future<Map<String, dynamic>> checkHealth() async {
    try {
      final response = await dio.get('/health');
      return response.data;
    } catch (e) {
      return {'status': 'offline', 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> uploadScanImage(String filePath, {String? backFilePath, String? topFilePath, String? bottomFilePath, String? userId}) async {
    final map = <String, dynamic>{
      'file': await MultipartFile.fromFile(filePath, filename: 'package_scan.jpg'),
    };
    if (userId != null) {
      map['user_id'] = userId;
    }
    if (backFilePath != null) {
      map['back_file'] = await MultipartFile.fromFile(backFilePath, filename: 'package_scan_back.jpg');
    }
    if (topFilePath != null) {
      map['top_file'] = await MultipartFile.fromFile(topFilePath, filename: 'package_scan_top.jpg');
    }
    if (bottomFilePath != null) {
      map['bottom_file'] = await MultipartFile.fromFile(bottomFilePath, filename: 'package_scan_bottom.jpg');
    }
    final formData = FormData.fromMap(map);
    final response = await dio.post('/scans', data: formData);
    return response.data;
  }

  Future<Map<String, dynamic>> processScan(String scanId) async {
    final response = await dio.post('/scans/$scanId/process');
    return response.data;
  }

  Future<List<dynamic>> fetchReviewQueue() async {
    final response = await dio.get('/reviews/queue');
    return response.data;
  }

  Future<Map<String, dynamic>> submitReview(String scanId, String reviewerId, String decision, String? notes) async {
    final response = await dio.post('/reviews', data: {
      'scan_id': scanId,
      'reviewer_id': reviewerId,
      'decision': decision,
      'notes': notes,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> fileComplaint(
      String citizenId, double paidPrice, double printedMrp, String shopkeeperName, String shopAddress, String description,
      {String? receiptPath, String? productPath}) async {
    final map = <String, dynamic>{
      'citizen_id': citizenId,
      'paid_price': paidPrice,
      'printed_mrp': printedMrp,
      'shopkeeper_name': shopkeeperName,
      'shop_address': shopAddress,
      'description': description,
    };
    if (receiptPath != null) {
      map['receipt_image'] = await MultipartFile.fromFile(receiptPath, filename: 'receipt.jpg');
    }
    if (productPath != null) {
      map['product_image'] = await MultipartFile.fromFile(productPath, filename: 'product.jpg');
    }
    
    final formData = FormData.fromMap(map);
    final response = await dio.post('/complaints', data: formData);
    return response.data;
  }
  Future<Map<String, dynamic>> fetchCitizenHistory(String userId) async {
    final response = await dio.get('/users/$userId/history');
    return response.data;
  }

  Future<List<dynamic>> fetchComplaints() async {
    final response = await dio.get('/complaints');
    return response.data;
  }

  Future<Map<String, dynamic>> reviewComplaint(String complaintId, String officerId, String status, String? notes) async {
    final response = await dio.patch('/complaints/$complaintId/review', data: {
      'officer_id': officerId,
      'status': status,
      'resolution_notes': notes,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> fetchManufacturerHistory(String name) async {
    final response = await dio.get('/manufacturers/$name/history');
    return response.data;
  }

  Future<List<dynamic>> fetchManufacturerRatings() async {
    final response = await dio.get('/manufacturers/ratings');
    return response.data;
  }

  Future<Map<String, dynamic>> rateManufacturer(String name, String officerId, String rating, String? notes) async {
    final response = await dio.post('/manufacturers/$name/rate', data: {
      'officer_id': officerId,
      'rating': rating,
      'notes': notes,
    });
    return response.data;
  }
}
