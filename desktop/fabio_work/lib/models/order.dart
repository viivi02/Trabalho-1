/// O JSON da API vem do Node/`pg`: BIGINT e alguns inteiros podem chegar como [String].
/// Helpers evitam: type 'String' is not a subtype of type 'int'.
int _readInt(dynamic value, [int fallback = 0]) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

double _readDouble(dynamic value, [double fallback = 0]) {
  if (value == null) return fallback;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

class Order {
  final String uuid;
  final String? createdAt;
  final String? channel;
  final double total;
  final String? status;
  final Customer? customer;
  final Seller? seller;
  final List<OrderItem> items;
  final Shipment? shipment;
  final Payment? payment;
  final OrderMetadata? metadata;

  Order({
    required this.uuid,
    this.createdAt,
    this.channel,
    required this.total,
    this.status,
    this.customer,
    this.seller,
    required this.items,
    this.shipment,
    this.payment,
    this.metadata,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      uuid: json['uuid']?.toString() ?? '',
      createdAt: json['created_at']?.toString(),
      channel: json['channel']?.toString(),
      total: _readDouble(json['total']),
      status: json['status']?.toString(),
      customer: json['customer'] != null
          ? Customer.fromJson(json['customer'] as Map<String, dynamic>)
          : null,
      seller: json['seller'] != null ? Seller.fromJson(json['seller'] as Map<String, dynamic>) : null,
      items: (json['items'] as List? ?? [])
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      shipment: json['shipment'] != null ? Shipment.fromJson(json['shipment'] as Map<String, dynamic>) : null,
      payment: json['payment'] != null ? Payment.fromJson(json['payment'] as Map<String, dynamic>) : null,
      metadata:
          json['metadata'] != null ? OrderMetadata.fromJson(json['metadata'] as Map<String, dynamic>) : null,
    );
  }
}

class Customer {
  final int id;
  final String? name;
  final String? email;
  final String? document;

  Customer({required this.id, this.name, this.email, this.document});

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: _readInt(json['id']),
      name: json['name']?.toString(),
      email: json['email']?.toString(),
      document: json['document']?.toString(),
    );
  }
}

class Seller {
  final int id;
  final String? name;
  final String? city;
  final String? state;

  Seller({required this.id, this.name, this.city, this.state});

  factory Seller.fromJson(Map<String, dynamic> json) {
    return Seller(
      id: _readInt(json['id']),
      name: json['name']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
    );
  }
}

class OrderItem {
  final int id;
  final int? productId;
  final String? productName;
  final double unitPrice;
  final int quantity;
  final double total;
  final Category? category;

  OrderItem({
    required this.id,
    this.productId,
    this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.total,
    this.category,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final pid = json['product_id'];
    return OrderItem(
      id: _readInt(json['id']),
      productId: pid == null ? null : _readInt(pid),
      productName: json['product_name']?.toString(),
      unitPrice: _readDouble(json['unit_price']),
      quantity: _readInt(json['quantity']),
      total: _readDouble(json['total']),
      category: json['category'] != null ? Category.fromJson(json['category'] as Map<String, dynamic>) : null,
    );
  }
}

class Category {
  final String id;
  final String? name;
  final SubCategory? subCategory;

  Category({required this.id, this.name, this.subCategory});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString(),
      subCategory:
          json['sub_category'] != null ? SubCategory.fromJson(json['sub_category'] as Map<String, dynamic>) : null,
    );
  }
}

class SubCategory {
  final String id;
  final String? name;

  SubCategory({required this.id, this.name});

  factory SubCategory.fromJson(Map<String, dynamic> json) {
    return SubCategory(id: json['id']?.toString() ?? '', name: json['name']?.toString());
  }
}

class Shipment {
  final String? carrier;
  final String? service;
  final String? status;
  final String? trackingCode;

  Shipment({this.carrier, this.service, this.status, this.trackingCode});

  factory Shipment.fromJson(Map<String, dynamic> json) {
    return Shipment(
      carrier: json['carrier']?.toString(),
      service: json['service']?.toString(),
      status: json['status']?.toString(),
      trackingCode: json['tracking_code']?.toString(),
    );
  }
}

class Payment {
  final String? method;
  final String? status;
  final String? transactionId;

  Payment({this.method, this.status, this.transactionId});

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      method: json['method']?.toString(),
      status: json['status']?.toString(),
      transactionId: json['transaction_id']?.toString(),
    );
  }
}

class OrderMetadata {
  final String? source;
  final String? userAgent;
  final String? ipAddress;

  OrderMetadata({this.source, this.userAgent, this.ipAddress});

  factory OrderMetadata.fromJson(Map<String, dynamic> json) {
    return OrderMetadata(
      source: json['source']?.toString(),
      userAgent: json['user_agent']?.toString(),
      ipAddress: json['ip_address']?.toString(),
    );
  }
}

class OrdersPage {
  final List<Order> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;

  OrdersPage({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
  });

  factory OrdersPage.fromJson(Map<String, dynamic> json) {
    return OrdersPage(
      content: (json['content'] as List? ?? [])
          .map((e) => Order.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: _readInt(json['page']),
      size: _readInt(json['size'], 20),
      totalElements: _readInt(json['totalElements']),
      totalPages: _readInt(json['totalPages']),
    );
  }
}
