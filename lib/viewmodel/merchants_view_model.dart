import 'package:flutter/material.dart';
import 'package:namnam/model/merchant.dart';
import 'package:namnam/model/merchant_item.dart';
import 'package:namnam/model/merchant_request.dart';
import 'package:namnam/model/request/update_merchant_status_request.dart';
import 'package:namnam/model/response/Status.dart';
import 'package:namnam/network/services/merchants_service.dart';
import 'package:namnam/network/services/merchants_service_impl.dart';

class MerchantsViewModel extends ChangeNotifier {
  List<MerchantItem> _merchants = [];
  bool _isLoading = false;
  String? _errorMessage;
  final MerchantsService _merchantsService = MerchantsServiceImpl();

  // Requests panel state, kept separate from the merchants list state so
  // loading requests never blanks out the table behind the dialog.
  List<MerchantRequest> _merchantRequests = [];
  bool _isLoadingRequests = false;
  String? _requestsErrorMessage;

  List<MerchantItem> get merchants => _merchants;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Approve/reject state, again kept apart: a failed update must not replace
  // the loaded requests with an error view.
  bool _isUpdatingStatus = false;
  String? _updateErrorMessage;

  List<MerchantRequest> get merchantRequests => _merchantRequests;
  bool get isLoadingRequests => _isLoadingRequests;
  String? get requestsErrorMessage => _requestsErrorMessage;

  bool get isUpdatingStatus => _isUpdatingStatus;
  String? get updateErrorMessage => _updateErrorMessage;

  // Analytics getters
  int get totalMerchants => _merchants.length;
  // These metrics don't exist on new API items; keep simple total for now
  int get activeMerchants => 0;
  int get inactiveMerchants => 0;
  double get averageRating => 0.0;
  int get totalOrders => 0;
  double get totalRevenue => 0.0;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  Future<void> fetchMerchants({int? limit, int? offset, String? q}) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _merchantsService.getMerchants(
        limit: limit,
        offset: offset,
        q: q,
      );

      if (response.status == Status.COMPLETED && response.data != null) {
        _merchants = response.data!;
        _setError(null);
      } else {
        _merchants = [];
        _setError(response.message ?? 'Failed to fetch merchants');
      }
    } catch (e) {
      _setError('Failed to fetch merchants: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Loads merchant requests. Both filters are optional: [merchantId] narrows
  /// to one merchant, [status] to one state. The requests dialog calls this
  /// with neither and shows whatever the API returns.
  Future<void> fetchMerchantRequests({int? merchantId, String? status}) async {
    _merchantRequests = [];
    _requestsErrorMessage = null;
    _isLoadingRequests = true;
    notifyListeners();

    try {
      final response = await _merchantsService.getMerchantRequests(
        merchantId: merchantId,
        status: status,
      );

      if (response.status == Status.COMPLETED && response.data != null) {
        _merchantRequests = response.data!;
      } else {
        _requestsErrorMessage =
            response.message ?? 'Failed to fetch merchant requests';
      }
    } catch (e) {
      _requestsErrorMessage = 'Failed to fetch merchant requests: $e';
    } finally {
      _isLoadingRequests = false;
      notifyListeners();
    }
  }

  /// Approves or rejects a request by patching the merchant's status, then
  /// reloads the panel so the new status is reflected. Returns whether the
  /// update succeeded; the caller surfaces the outcome.
  Future<bool> updateMerchantStatus({
    required int merchantId,
    required String status,
    required int zoneId,
  }) async {
    _isUpdatingStatus = true;
    _updateErrorMessage = null;
    notifyListeners();

    try {
      final response = await _merchantsService.updateMerchantStatus(
        UpdateMerchantStatusRequest(
          merchantId: merchantId,
          status: status,
          zoneId: zoneId,
        ),
      );

      if (response.status == Status.COMPLETED) {
        // fetchMerchantRequests flips the loading flag itself, so release this
        // one first to avoid the buttons staying disabled.
        _isUpdatingStatus = false;
        await fetchMerchantRequests();
        return true;
      }

      _updateErrorMessage =
          response.message ?? 'Failed to update the merchant request';
      return false;
    } catch (e) {
      _updateErrorMessage = 'Failed to update the merchant request: $e';
      return false;
    } finally {
      _isUpdatingStatus = false;
      notifyListeners();
    }
  }

  /// Drops the loaded requests, so a reopened dialog starts clean.
  void clearMerchantRequests() {
    _merchantRequests = [];
    _requestsErrorMessage = null;
    _isLoadingRequests = false;
    notifyListeners();
  }

  void clearError() {
    _setError(null);
  }
}





