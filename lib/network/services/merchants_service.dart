import 'package:namnam/model/merchant_item.dart';
import 'package:namnam/model/merchant_request.dart';
import 'package:namnam/model/request/update_merchant_status_request.dart';
import 'package:namnam/model/response/ApiResponse.dart';

abstract class MerchantsService {
  Future<ApiResponse<List<MerchantItem>>> getMerchants({int? limit, int? offset, String? q});

  /// Merchant requests across every merchant. Passing [merchantId] narrows the
  /// result to one merchant, and [status] to a single state (`pending`,
  /// `approved`, ...); omitting both leaves the filtering to the API.
  Future<ApiResponse<List<MerchantRequest>>> getMerchantRequests({
    int? merchantId,
    String? status,
  });

  /// Approves or rejects a merchant request by patching the merchant's status.
  Future<ApiResponse<bool>> updateMerchantStatus(
    UpdateMerchantStatusRequest request,
  );
}
