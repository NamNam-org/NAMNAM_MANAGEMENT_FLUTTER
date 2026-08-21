import 'package:namnam/core/Utility/Preferences.dart';
import 'package:namnam/model/merchant_item.dart';
import 'package:namnam/model/merchant_request.dart';
import 'package:namnam/model/request/update_merchant_status_request.dart';
import 'package:namnam/model/response/ApiResponse.dart';
import 'package:namnam/model/response/Status.dart';
import 'package:namnam/network/ApiEndPoints.dart';
import 'package:namnam/network/NetworkApiService.dart';
import 'package:namnam/network/services/merchants_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MerchantsServiceImpl implements MerchantsService {
  final NetworkApiService _networkApiService = NetworkApiService();

  @override
  Future<ApiResponse<List<MerchantItem>>> getMerchants({int? limit, int? offset, String? q}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefProvider = PrefProvider(prefs);
      final accessToken = prefProvider.getAccessToken();

      if (accessToken.isEmpty) {
        return ApiResponse(Status.ERROR, null, 'Missing access token. Please log in.');
      }

      final Map<String, dynamic> queryParams = {
        'limit': '',
        'offset':  '',
        'q': null,
      };

      final response = await _networkApiService.fetchData(
        ApiEndPoints.merchants,
        queryParams,
        accessToken,
      );

      if (response.status == Status.COMPLETED) {
        // New API shape: data contains items list and pagination
        final data = response.data;
        if (data is Map && data['items'] is List) {
          final merchants = (data['items'] as List)
              .map((item) => MerchantItem.fromJson(item))
              .toList();
          return ApiResponse(Status.COMPLETED, merchants, response.message);
        }
        return ApiResponse(Status.ERROR, null, 'Invalid response format: Expected data.items List');
      }

      return ApiResponse(Status.ERROR, null, response.message ?? 'Failed to fetch merchants');
    } catch (e) {
      return ApiResponse(Status.ERROR, null, 'Failed to fetch merchants: $e');
    }
  }

  @override
  Future<ApiResponse<List<MerchantRequest>>> getMerchantRequests({
    int? merchantId,
    String? status,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefProvider = PrefProvider(prefs);
      final accessToken = prefProvider.getAccessToken();

      if (accessToken.isEmpty) {
        return ApiResponse(Status.ERROR, null, 'Missing access token. Please log in.');
      }

      // Only send params that carry a value: an empty string or null is
      // serialised by Uri as a bare valueless key (`?status`), which the API
      // would have to parse as an empty filter.
      final Map<String, dynamic> queryParams = {
        if (merchantId != null) 'merchantId': merchantId.toString(),
        if (status != null && status.isNotEmpty) 'status': status,
      };

      final response = await _networkApiService.fetchData(
        ApiEndPoints.merchantRequests,
        queryParams,
        accessToken,
      );

      if (response.status != Status.COMPLETED) {
        return ApiResponse(
          Status.ERROR,
          null,
          response.message ?? 'Failed to fetch merchant requests',
        );
      }

      final items = _extractRequestItems(response.data);
      if (items == null) {
        return ApiResponse(
          Status.ERROR,
          null,
          'Invalid response format: could not find a merchant requests list',
        );
      }

      final requests = items
          .whereType<Map>()
          .map((item) => MerchantRequest.fromJson(Map<String, dynamic>.from(item)))
          // When a merchantId was asked for, the server is expected to honour
          // it, but an API that ignores unknown query params would hand back
          // every merchant's requests. Drop rows that name a different
          // merchant; rows without a merchantId are kept since they can't be
          // attributed either way.
          .where((request) =>
              merchantId == null ||
              request.merchantId == null ||
              request.merchantId == merchantId)
          .toList();

      return ApiResponse(Status.COMPLETED, requests, response.message);
    } catch (e) {
      return ApiResponse(Status.ERROR, null, 'Failed to fetch merchant requests: $e');
    }
  }

  @override
  Future<ApiResponse<bool>> updateMerchantStatus(
    UpdateMerchantStatusRequest request,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefProvider = PrefProvider(prefs);
      final accessToken = prefProvider.getAccessToken();

      if (accessToken.isEmpty) {
        return ApiResponse(Status.ERROR, null, 'Missing access token. Please log in.');
      }

      final response = await _networkApiService.patchResponse(
        ApiEndPoints.updateMerchantStatus(request.merchantId),
        request.toJson(),
        accessToken,
      );

      if (response.status == Status.COMPLETED) {
        return ApiResponse(Status.COMPLETED, true, response.message);
      }

      if (response.message?.toLowerCase().contains('unauthorized') == true) {
        return ApiResponse(
          Status.ERROR,
          null,
          'Authentication failed. Please log in again.',
        );
      }

      return ApiResponse(
        Status.ERROR,
        null,
        response.message ?? 'Failed to update merchant status',
      );
    } catch (e) {
      // patchResponse throws FetchDataException on timeout, connectivity loss,
      // or a body it can't decode.
      return ApiResponse(Status.ERROR, null, 'Failed to update merchant status: $e');
    }
  }

  /// This endpoint returns `data` as a bare list. The map branch is a cheap
  /// safety net in case it later grows the paginated `items` envelope that
  /// `GET merchants` already uses.
  List<dynamic>? _extractRequestItems(dynamic data) {
    if (data is List) return data;

    if (data is Map) {
      for (final key in const ['items', 'requests']) {
        final value = data[key];
        if (value is List) return value;
      }
    }

    return null;
  }
}


