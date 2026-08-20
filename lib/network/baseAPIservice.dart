import 'package:namnam/model/response/ApiResponse.dart';

abstract class BaseApiService {
  final String baseUrl = "https://managmement-api.onrender.com/api/";
  Future<ApiResponse> postResponse(
    String url,
    Map<String, dynamic> json,
    String? token,
  );
  Future<ApiResponse> patchResponse(
    String url,
    Map<String, dynamic> json,
    String? token,
  );
  Future<ApiResponse> deleteResponse(
    String url,
    String? token,
  );
  Future<ApiResponse> fetchData(
    String url,
    Map<String, dynamic> json,
    String? token,
  );
}
