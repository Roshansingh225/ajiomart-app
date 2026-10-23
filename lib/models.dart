import 'package:intl/intl.dart';

const productCategories = [
  'Dresses',
  'Co-ords',
  'Makeup',
  'Skincare',
  'Fragrance',
  'Handbags',
  'Jewellery',
  'Footwear',
  'Accessories',
];

const orderStatuses = [
  'placed',
  'confirmed',
  'packed',
  'shipped',
  'delivered',
  'cancelled',
];

String money(num value) => NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: value % 1 == 0 ? 0 : 2,
    ).format(value);

String prettyStatus(String status) => status
    .split('_')
    .map((part) =>
        part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}')
    .join(' ');

List<String> _strings(dynamic value) =>
    value is List ? value.map((item) => item.toString()).toList() : <String>[];

double _number(dynamic value, [double fallback = 0]) =>
    value == null ? fallback : double.tryParse(value.toString()) ?? fallback;

class ShopProduct {
  const ShopProduct({
    required this.id,
    required this.slug,
    required this.name,
    required this.category,
    required this.price,
    required this.originalPrice,
    required this.stock,
    required this.rating,
    required this.badge,
    required this.colors,
    required this.sizes,
    required this.imageUrls,
    required this.description,
    required this.hsnCode,
    required this.active,
  });

  final String id;
  final String slug;
  final String name;
  final String category;
  final double price;
  final double originalPrice;
  final int stock;
  final double rating;
  final String badge;
  final List<String> colors;
  final List<String> sizes;
  final List<String> imageUrls;
  final String description;
  final String hsnCode;
  final bool active;

  String get imageUrl => imageUrls.isEmpty ? '' : imageUrls.first;

  factory ShopProduct.fromJson(Map<String, dynamic> json) {
    final images = _strings(json['image_urls'] ?? json['imageUrls']);
    return ShopProduct(
      id: '${json['id'] ?? ''}',
      slug: '${json['slug'] ?? ''}',
      name: '${json['name'] ?? ''}',
      category: '${json['category'] ?? 'Accessories'}',
      price: _number(json['price']),
      originalPrice: _number(json['original_price'] ?? json['originalPrice'],
          _number(json['price'])),
      stock: _number(json['stock']).toInt(),
      rating: _number(json['rating'], 4.5),
      badge: '${json['badge'] ?? ''}',
      colors: _strings(json['colors']),
      sizes: _strings(json['sizes']),
      imageUrls: images,
      description: '${json['description'] ?? ''}',
      hsnCode: '${json['hsn_code'] ?? json['hsnCode'] ?? ''}',
      active: json['active'] != false,
    );
  }

  Map<String, dynamic> toDatabase({String? imageUrlsOverride}) => {
        'slug': slug,
        'name': name,
        'category': category,
        'price': price,
        'original_price': originalPrice,
        'stock': stock,
        'rating': rating,
        'badge': badge.isEmpty ? null : badge,
        'colors': colors,
        'sizes': sizes,
        'image_urls':
            imageUrlsOverride == null ? imageUrls : [imageUrlsOverride],
        'description': description,
        'hsn_code': hsnCode,
        'active': active,
      };
}

class CartLine {
  const CartLine({
    required this.product,
    required this.color,
    required this.size,
    required this.quantity,
  });

  final ShopProduct product;
  final String color;
  final String size;
  final int quantity;

  String get key => '${product.id}-$size-$color';
  double get lineTotal => product.price * quantity;

  CartLine copyWith({int? quantity}) => CartLine(
        product: product,
        color: color,
        size: size,
        quantity: quantity ?? this.quantity,
      );
}

class OrderLine {
  const OrderLine({
    required this.id,
    required this.name,
    required this.category,
    required this.color,
    required this.size,
    required this.quantity,
    required this.price,
    required this.imageUrl,
  });

  final String id;
  final String name;
  final String category;
  final String color;
  final String size;
  final int quantity;
  final double price;
  final String imageUrl;

  factory OrderLine.fromJson(Map<String, dynamic> json) => OrderLine(
        id: '${json['id'] ?? json['product_id'] ?? ''}',
        name: '${json['product_name'] ?? json['name'] ?? ''}',
        category: '${json['category'] ?? ''}',
        color: '${json['selected_color'] ?? json['color'] ?? ''}',
        size: '${json['selected_size'] ?? json['size'] ?? ''}',
        quantity: _number(json['quantity']).toInt(),
        price: _number(json['price']),
        imageUrl: '${json['image_url'] ?? json['imageUrl'] ?? ''}',
      );
}

class AjiOrder {
  const AjiOrder({
    required this.id,
    required this.userId,
    required this.customerName,
    required this.customerPhone,
    required this.address,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.codCharges,
    required this.total,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.status,
    required this.courierPartner,
    required this.trackingNumber,
    required this.trackingUrl,
    required this.trackingNote,
    required this.delhiveryStatus,
    required this.trackingEvents,
    required this.packageWeightG,
    required this.packageLengthCm,
    required this.packageWidthCm,
    required this.packageHeightCm,
    required this.eWaybill,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String customerName;
  final String customerPhone;
  final Map<String, dynamic> address;
  final List<OrderLine> items;
  final double subtotal;
  final double discount;
  final double codCharges;
  final double total;
  final String paymentMethod;
  final String paymentStatus;
  final String status;
  final String courierPartner;
  final String trackingNumber;
  final String trackingUrl;
  final String trackingNote;
  final String delhiveryStatus;
  final List<Map<String, dynamic>> trackingEvents;
  final int? packageWeightG;
  final double? packageLengthCm;
  final double? packageWidthCm;
  final double? packageHeightCm;
  final String eWaybill;
  final DateTime? createdAt;

  factory AjiOrder.fromJson(Map<String, dynamic> json) {
    final itemRows =
        json['order_items'] is List ? json['order_items'] as List : const [];
    final rawEvents = json['delhivery_tracking_events'] is List
        ? json['delhivery_tracking_events'] as List
        : const [];
    return AjiOrder(
      id: '${json['id'] ?? ''}',
      userId: '${json['user_id'] ?? ''}',
      customerName: '${json['customer_name'] ?? ''}',
      customerPhone: '${json['customer_phone'] ?? ''}',
      address: {
        'addressLine1': json['address_line1'] ?? '',
        'addressLine2': json['address_line2'] ?? '',
        'landmark': json['landmark'] ?? '',
        'city': json['city'] ?? '',
        'state': json['state'] ?? '',
        'postalCode': json['postal_code'] ?? '',
      },
      items: itemRows
          .whereType<Map>()
          .map((item) => OrderLine.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      subtotal: _number(json['subtotal'] ?? json['total']),
      discount: _number(json['discount']),
      codCharges: _number(json['cod_charges']),
      total: _number(json['total']),
      paymentMethod: '${json['payment_method'] ?? ''}',
      paymentStatus: '${json['payment_status'] ?? 'not_required'}',
      status: '${json['status'] ?? 'placed'}',
      courierPartner: '${json['courier_partner'] ?? 'Ajiomart Express'}',
      trackingNumber: '${json['tracking_number'] ?? ''}',
      trackingUrl: '${json['tracking_url'] ?? ''}',
      trackingNote: '${json['tracking_note'] ?? ''}',
      delhiveryStatus: '${json['delhivery_status'] ?? ''}',
      trackingEvents: rawEvents
          .whereType<Map>()
          .map((event) => Map<String, dynamic>.from(event))
          .toList(),
      packageWeightG: json['package_weight_g'] == null
          ? null
          : _number(json['package_weight_g']).toInt(),
      packageLengthCm: json['package_length_cm'] == null
          ? null
          : _number(json['package_length_cm']),
      packageWidthCm: json['package_width_cm'] == null
          ? null
          : _number(json['package_width_cm']),
      packageHeightCm: json['package_height_cm'] == null
          ? null
          : _number(json['package_height_cm']),
      eWaybill: '${json['e_waybill'] ?? ''}',
      createdAt: DateTime.tryParse('${json['created_at'] ?? ''}')?.toLocal(),
    );
  }
}

class AjiUser {
  const AjiUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;

  bool get isAdmin => role == 'admin';

  factory AjiUser.fromAuth(
          Map<String, dynamic> auth, Map<String, dynamic>? profile) =>
      AjiUser(
        id: '${auth['id'] ?? ''}',
        name:
            '${profile?['name'] ?? (auth['user_metadata'] as Map?)?['name'] ?? ''}',
        email: '${profile?['email'] ?? auth['email'] ?? ''}',
        phone:
            '${profile?['phone'] ?? auth['phone'] ?? (auth['user_metadata'] as Map?)?['phone'] ?? ''}',
        role: '${profile?['role'] ?? 'customer'}',
      );
}
