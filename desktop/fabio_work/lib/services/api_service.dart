import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/order.dart';

class ApiService {
  static const String _baseUrl = 'http://localhost:3000';

  Future<OrdersPage> fetchOrders({
    int page = 0,
    int size = 15,
    String sort = 'desc',
    String? status,
    String? codigoCliente,
    String? productId,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'size': size.toString(),
      'sort': sort,
    };

    if (status != null && status.isNotEmpty) params['status'] = status;
    if (codigoCliente != null && codigoCliente.isNotEmpty) params['codigoCliente'] = codigoCliente;
    if (productId != null && productId.isNotEmpty) params['productId'] = productId;

    final uri = Uri.parse('$_baseUrl/orders').replace(queryParameters: params);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return OrdersPage.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to load orders: ${response.statusCode}');
  }

  Future<Order?> fetchOrderByUuid(String uuid) async {
    final response = await http.get(Uri.parse('$_baseUrl/orders/$uuid'));

    if (response.statusCode == 200) {
      return Order.fromJson(jsonDecode(response.body));
    }
    if (response.statusCode == 404) return null;
    throw Exception('Failed to load order: ${response.statusCode}');
  }
}
