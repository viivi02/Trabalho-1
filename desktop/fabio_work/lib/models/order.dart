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
      uuid: json['uuid'] ?? '',
      createdAt: json['created_at'],
      channel: json['channel'],
      total: (json['total'] ?? 0).toDouble(),
      status: json['status'],
      customer: json['customer'] != null ? Customer.fromJson(json['customer']) : null,
      seller: json['seller'] != null ? Seller.fromJson(json['seller']) : null,
      items: (json['items'] as List? ?? []).map((e) => OrderItem.fromJson(e)).toList(),
      shipment: json['shipment'] != null ? Shipment.fromJson(json['shipment']) : null,
      payment: json['payment'] != null ? Payment.fromJson(json['payment']) : null,
      metadata: json['metadata'] != null ? OrderMetadata.fromJson(json['metadata']) : null,
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
      id: json['id'] ?? 0,
      name: json['name'],
      email: json['email'],
      document: json['document'],
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
      id: json['id'] ?? 0,
      name: json['name'],
      city: json['city'],
      state: json['state'],
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
    return OrderItem(
      id: json['id'] ?? 0,
      productId: json['product_id'],
      productName: json['product_name'],
      unitPrice: (json['unit_price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 0,
      total: (json['total'] ?? 0).toDouble(),
      category: json['category'] != null ? Category.fromJson(json['category']) : null,
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
      id: json['id'] ?? '',
      name: json['name'],
      subCategory: json['sub_category'] != null ? SubCategory.fromJson(json['sub_category']) : null,
    );
  }
}

class SubCategory {
  final String id;
  final String? name;

  SubCategory({required this.id, this.name});

  factory SubCategory.fromJson(Map<String, dynamic> json) {
    return SubCategory(id: json['id'] ?? '', name: json['name']);
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
      carrier: json['carrier'],
      service: json['service'],
      status: json['status'],
      trackingCode: json['tracking_code'],
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
      method: json['method'],
      status: json['status'],
      transactionId: json['transaction_id'],
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
      source: json['source'],
      userAgent: json['user_agent'],
      ipAddress: json['ip_address'],
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
      content: (json['content'] as List? ?? []).map((e) => Order.fromJson(e)).toList(),
      page: json['page'] ?? 0,
      size: json['size'] ?? 20,
      totalElements: json['totalElements'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
    );
  }
}
