/// Body for `PATCH merchants/{merchantId}/status`, used to approve or reject
/// a merchant request. [merchantId] goes in the path, not the body.
class UpdateMerchantStatusRequest {
  static const String approved = 'approved';
  static const String rejected = 'rejected';

  final int merchantId;
  final String status;
  final int zoneId;

  UpdateMerchantStatusRequest({
    required this.merchantId,
    required this.status,
    required this.zoneId,
  });

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'zoneId': zoneId,
    };
  }
}
