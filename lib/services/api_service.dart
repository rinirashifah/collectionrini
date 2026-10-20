import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;
import '../models/category.dart';
import '../models/collection_item.dart';
import '../models/dashboard_data.dart';
import '../models/location_history.dart';
import '../models/laundry_history.dart';
import '../models/storage_location.dart';
import 'storage_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  Future<Map<String, String>> _getHeaders() async {
    final apiKey = await StorageService.getApiKey();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-API-Key': apiKey,
    };
  }

  Future<String> _getUrl(String endpoint) async {
    String baseUrl = await StorageService.getBaseUrl();
    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }
    return '$baseUrl$endpoint';
  }

  // --- HEALTH CHECK ---
  Future<bool> checkHealth([String? testUrl, String? testKey]) async {
    try {
      String url = testUrl ?? await _getUrl('/health');
      if (url.endsWith('/')) {
        url = url.substring(0, url.length - 1);
      }
      final target = url.endsWith('/health') ? url : '$url/health';
      final response = await http.get(
        Uri.parse(target),
        headers: {
          'Accept': 'application/json',
          if (testKey != null) 'X-API-Key': testKey,
        },
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // --- DASHBOARD ---
  Future<DashboardData> getDashboard() async {
    final url = await _getUrl('/api/v1/dashboard');
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return DashboardData.fromJson(json['data'] ?? {});
    } else {
      final json = jsonDecode(response.body);
      throw Exception(json['error'] ?? 'Gagal memuat data dashboard');
    }
  }

  // --- ITEMS ---
  Future<List<CollectionItem>> getItems({
    String? search,
    String? categoryId,
    String? status,
    String? locationId,
    String? color,
    String? brand,
  }) async {
    final queryParams = <String, String>{};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (categoryId != null && categoryId.isNotEmpty) queryParams['category_id'] = categoryId;
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    if (locationId != null && locationId.isNotEmpty) queryParams['location_id'] = locationId;
    if (color != null && color.isNotEmpty) queryParams['color'] = color;
    if (brand != null && brand.isNotEmpty) queryParams['brand'] = brand;

    String urlStr = await _getUrl('/api/v1/items');
    final uri = Uri.parse(urlStr).replace(queryParameters: queryParams.isEmpty ? null : queryParams);
    final headers = await _getHeaders();
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List list = json['data'] ?? [];
      return list.map((item) => CollectionItem.fromJson(item)).toList();
    } else {
      final json = jsonDecode(response.body);
      throw Exception(json['error'] ?? 'Gagal memuat koleksi');
    }
  }

  Future<Map<String, dynamic>> getItemDetail(String id) async {
    final url = await _getUrl('/api/v1/items/$id');
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final data = json['data'] ?? {};
      final item = CollectionItem.fromJson(data['item']);

      List<LocationHistory> locHistories = [];
      if (data['location_histories'] != null) {
        locHistories = (data['location_histories'] as List)
            .map((e) => LocationHistory.fromJson(e))
            .toList();
      }

      List<LaundryHistory> laundryHistories = [];
      if (data['laundry_histories'] != null) {
        laundryHistories = (data['laundry_histories'] as List)
            .map((e) => LaundryHistory.fromJson(e))
            .toList();
      }

      return {
        'item': item,
        'location_histories': locHistories,
        'laundry_histories': laundryHistories,
      };
    } else {
      final json = jsonDecode(response.body);
      throw Exception(json['error'] ?? 'Gagal memuat detail barang');
    }
  }

  Future<CollectionItem> createItem(Map<String, dynamic> data) async {
    final url = await _getUrl('/api/v1/items');
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(data),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return CollectionItem.fromJson(json['data']);
    } else {
      final json = jsonDecode(response.body);
      throw Exception(json['error'] ?? 'Gagal menambahkan barang');
    }
  }

  Future<CollectionItem> updateItem(String id, Map<String, dynamic> data) async {
    final url = await _getUrl('/api/v1/items/$id');
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return CollectionItem.fromJson(json['data']);
    } else {
      final json = jsonDecode(response.body);
      throw Exception(json['error'] ?? 'Gagal memperbarui barang');
    }
  }

  Future<void> deleteItem(String id) async {
    final url = await _getUrl('/api/v1/items/$id');
    final headers = await _getHeaders();
    final response = await http.delete(Uri.parse(url), headers: headers);

    if (response.statusCode != 200) {
      final json = jsonDecode(response.body);
      throw Exception(json['error'] ?? 'Gagal menghapus barang');
    }
  }

  // --- STATUS & LAUNDRY ACTIONS ---
  Future<CollectionItem> updateStatus(String id, String status, {String? newLocationId, String? notes}) async {
    final url = await _getUrl('/api/v1/items/$id/status');
    final headers = await _getHeaders();
    final response = await http.patch(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode({
        'status': status,
        if (newLocationId != null) 'new_location_id': newLocationId,
        if (notes != null) 'notes': notes,
      }),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return CollectionItem.fromJson(json['data']);
    } else {
      final json = jsonDecode(response.body);
      throw Exception(json['error'] ?? 'Gagal mengubah status');
    }
  }

  Future<CollectionItem> startLaundry(String id, {String? laundryLocationId, String? notes}) async {
    final url = await _getUrl('/api/v1/items/$id/laundry');
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode({
        if (laundryLocationId != null) 'laundry_location_id': laundryLocationId,
        if (notes != null) 'notes': notes,
      }),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return CollectionItem.fromJson(json['data']);
    } else {
      final json = jsonDecode(response.body);
      throw Exception(json['error'] ?? 'Gagal memasukkan ke laundry');
    }
  }

  Future<CollectionItem> completeLaundry(String id, {String? dryingLocationId, String? notes}) async {
    final url = await _getUrl('/api/v1/items/$id/laundry/complete');
    final headers = await _getHeaders();
    final response = await http.patch(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode({
        if (dryingLocationId != null) 'drying_location_id': dryingLocationId,
        if (notes != null) 'notes': notes,
      }),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return CollectionItem.fromJson(json['data']);
    } else {
      final json = jsonDecode(response.body);
      throw Exception(json['error'] ?? 'Gagal menyelesaikan laundry');
    }
  }

  Future<CollectionItem> storeItem(String id, String targetLocationId, {String? positionDetail, String? notes}) async {
    final url = await _getUrl('/api/v1/items/$id/store');
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode({
        'target_location_id': targetLocationId,
        if (positionDetail != null) 'position_detail': positionDetail,
        if (notes != null) 'notes': notes,
      }),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return CollectionItem.fromJson(json['data']);
    } else {
      final json = jsonDecode(response.body);
      throw Exception(json['error'] ?? 'Gagal menyimpan barang ke lemari');
    }
  }

  Future<CollectionItem> moveLocation(String id, String newLocationId, {String? positionDetail, String? notes}) async {
    final url = await _getUrl('/api/v1/items/$id/move');
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode({
        'new_location_id': newLocationId,
        if (positionDetail != null) 'position_detail': positionDetail,
        if (notes != null) 'notes': notes,
      }),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return CollectionItem.fromJson(json['data']);
    } else {
      final json = jsonDecode(response.body);
      throw Exception(json['error'] ?? 'Gagal memindahkan lokasi');
    }
  }

  // --- CATEGORIES ---
  Future<List<Category>> getCategories() async {
    final url = await _getUrl('/api/v1/categories');
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List list = json['data'] ?? [];
      return list.map((item) => Category.fromJson(item)).toList();
    } else {
      final json = jsonDecode(response.body);
      throw Exception(json['error'] ?? 'Gagal memuat kategori');
    }
  }

  Future<Category> createCategory(String name) async {
    final url = await _getUrl('/api/v1/categories');
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode({'name': name}),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return Category.fromJson(json['data']);
    } else {
      final json = jsonDecode(response.body);
      throw Exception(json['error'] ?? 'Gagal menambahkan kategori');
    }
  }

  Future<void> deleteCategory(String id) async {
    final url = await _getUrl('/api/v1/categories/$id');
    final headers = await _getHeaders();
    final response = await http.delete(Uri.parse(url), headers: headers);

    if (response.statusCode != 200) {
      final json = jsonDecode(response.body);
      throw Exception(json['error'] ?? 'Gagal menghapus kategori');
    }
  }

  // --- STORAGE LOCATIONS ---
  Future<List<StorageLocation>> getLocations() async {
    final url = await _getUrl('/api/v1/locations');
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List list = json['data'] ?? [];
      return list.map((item) => StorageLocation.fromJson(item)).toList();
    } else {
      final json = jsonDecode(response.body);
      throw Exception(json['error'] ?? 'Gagal memuat lokasi');
    }
  }

  Future<List<StorageLocation>> getLocationTree() async {
    final url = await _getUrl('/api/v1/locations/tree');
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List list = json['data'] ?? [];
      return list.map((item) => StorageLocation.fromJson(item)).toList();
    } else {
      final json = jsonDecode(response.body);
      throw Exception(json['error'] ?? 'Gagal memuat pohon lokasi');
    }
  }

  Future<Map<String, dynamic>> getLocationDetail(String id) async {
    final url = await _getUrl('/api/v1/locations/$id');
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final data = json['data'] ?? {};
      final loc = StorageLocation.fromJson(data['location']);

      List<StorageLocation> breadcrumbs = [];
      if (data['breadcrumbs'] != null) {
        breadcrumbs = (data['breadcrumbs'] as List)
            .map((e) => StorageLocation.fromJson(e))
            .toList();
      }

      List<StorageLocation> children = [];
      if (data['children'] != null) {
        children = (data['children'] as List)
            .map((e) => StorageLocation.fromJson(e))
            .toList();
      }

      return {
        'location': loc,
        'breadcrumbs': breadcrumbs,
        'children': children,
      };
    } else {
      final json = jsonDecode(response.body);
      throw Exception(json['error'] ?? 'Gagal memuat detail lokasi');
    }
  }

  Future<List<CollectionItem>> getLocationItems(String id) async {
    final url = await _getUrl('/api/v1/locations/$id/items');
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List list = json['data'] ?? [];
      return list.map((item) => CollectionItem.fromJson(item)).toList();
    } else {
      final json = jsonDecode(response.body);
      throw Exception(json['error'] ?? 'Gagal memuat barang di lokasi ini');
    }
  }

  Future<StorageLocation> createLocation(Map<String, dynamic> data) async {
    final url = await _getUrl('/api/v1/locations');
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(data),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return StorageLocation.fromJson(json['data']);
    } else {
      final json = jsonDecode(response.body);
      throw Exception(json['error'] ?? 'Gagal menambahkan lokasi');
    }
  }

  Future<void> deleteLocation(String id) async {
    final url = await _getUrl('/api/v1/locations/$id');
    final headers = await _getHeaders();
    final response = await http.delete(Uri.parse(url), headers: headers);

    if (response.statusCode != 200) {
      final json = jsonDecode(response.body);
      throw Exception(json['error'] ?? 'Gagal menghapus lokasi');
    }
  }

  // --- IMAGE UPLOAD ---
  Future<String> uploadImage(String filePath) async {
    final url = await _getUrl('/api/v1/upload');
    final apiKey = await StorageService.getApiKey();

    final request = http.MultipartRequest('POST', Uri.parse(url));
    request.headers['X-API-Key'] = apiKey;

    final fileExt = path.extension(filePath).toLowerCase().replaceAll('.', '');
    String mediaSubtype = 'jpeg';
    if (fileExt == 'png') mediaSubtype = 'png';
    if (fileExt == 'webp') mediaSubtype = 'webp';

    request.files.add(await http.MultipartFile.fromPath(
      'image',
      filePath,
      contentType: MediaType('image', mediaSubtype),
    ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['url'] ?? '';
    } else {
      final json = jsonDecode(response.body);
      throw Exception(json['error'] ?? 'Gagal mengunggah foto');
    }
  }

  // --- SEED SAMPLE DATA ---
  Future<void> seedSampleData() async {
    final url = await _getUrl('/api/v1/seed-sample-data');
    final headers = await _getHeaders();
    final response = await http.post(Uri.parse(url), headers: headers);

    if (response.statusCode != 200) {
      final json = jsonDecode(response.body);
      throw Exception(json['error'] ?? 'Gagal mengisi data contoh');
    }
  }
}
