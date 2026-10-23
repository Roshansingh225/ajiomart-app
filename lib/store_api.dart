import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models.dart';

class AjiStoreApi extends ChangeNotifier {
  AjiStoreApi(this.client);

  final SupabaseClient client;
  StreamSubscription<AuthState>? _authSubscription;
  SharedPreferences? _preferences;

  AjiUser? user;
  List<ShopProduct> products = [];
  List<AjiOrder> orders = [];
  List<AjiUser> customers = [];
  List<CartLine> cart = [];
  Set<String> wishlistIds = {};
  bool loading = true;
  bool productsLoading = false;
  bool cartLoading = false;
  bool ordersLoading = false;
  String error = '';

  double get cartSubtotal => cart.fold(0, (sum, item) => sum + item.lineTotal);
  int get cartCount => cart.fold(0, (sum, item) => sum + item.quantity);
  List<ShopProduct> get wishlist =>
      products.where((p) => wishlistIds.contains(p.id)).toList();

  Future<void> initialize() async {
    _preferences = await SharedPreferences.getInstance();
    wishlistIds =
        (_preferences?.getStringList('ajiomart-wishlist') ?? []).toSet();
    _authSubscription =
        client.auth.onAuthStateChange.listen((_) => _loadUser());
    await _loadUser();
  }

  Future<void> _loadUser() async {
    final authUser = client.auth.currentUser;
    if (authUser == null) {
      user = null;
      cart = [];
      orders = [];
      customers = [];
      loading = false;
      notifyListeners();
      await refreshProducts();
      return;
    }

    try {
      final profile = await client
          .from('profiles')
          .select()
          .eq('id', authUser.id)
          .maybeSingle();
      user = AjiUser.fromAuth(authUser.toJson(), profile);
      loading = false;
      notifyListeners();
      await Future.wait([refreshProducts(), refreshCart(), refreshOrders()]);
      if (user?.isAdmin == true) await refreshCustomers();
    } catch (e) {
      user = AjiUser.fromAuth(authUser.toJson(), null);
      error = _friendlyError(e);
      loading = false;
      notifyListeners();
      await refreshProducts();
    }
  }

  Future<void> refreshProducts() async {
    productsLoading = true;
    notifyListeners();
    try {
      final rows = await client
          .from('products')
          .select()
          .order('created_at', ascending: false);
      products = (rows as List)
          .map((row) => ShopProduct.fromJson(Map<String, dynamic>.from(row)))
          .toList();
      error = '';
    } catch (e) {
      error = _friendlyError(e);
    } finally {
      productsLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshCart() async {
    final currentUser = user;
    if (currentUser == null) {
      cart = [];
      return;
    }
    cartLoading = true;
    notifyListeners();
    try {
      final rows = await client
          .from('cart_items')
          .select(
              'product_id, selected_color, selected_size, quantity, product:products(*)')
          .eq('user_id', currentUser.id)
          .order('created_at', ascending: true);
      final loaded = <CartLine>[];
      for (final value in rows as List) {
        final row = Map<String, dynamic>.from(value);
        final linkedProduct = row['product'];
        if (linkedProduct is! Map) continue;
        final product =
            ShopProduct.fromJson(Map<String, dynamic>.from(linkedProduct));
        loaded.add(CartLine(
          product: product,
          color: '${row['selected_color'] ?? ''}',
          size: '${row['selected_size'] ?? ''}',
          quantity: int.tryParse('${row['quantity']}') ?? 1,
        ));
      }
      cart = loaded;
      error = '';
    } catch (e) {
      error = _friendlyError(e);
    } finally {
      cartLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshOrders() async {
    if (user == null) {
      orders = [];
      return;
    }
    ordersLoading = true;
    notifyListeners();
    try {
      final rows = await client
          .from('orders')
          .select('*, order_items(*)')
          .order('created_at', ascending: false);
      orders = (rows as List)
          .map((row) => AjiOrder.fromJson(Map<String, dynamic>.from(row)))
          .toList();
    } catch (e) {
      error = _friendlyError(e);
    } finally {
      ordersLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshCustomers() async {
    try {
      final rows = await client
          .from('profiles')
          .select('id, name, email, phone, role')
          .order('created_at', ascending: false);
      customers = (rows as List).map((row) {
        final profile = Map<String, dynamic>.from(row);
        return AjiUser(
          id: '${profile['id'] ?? ''}',
          name: '${profile['name'] ?? ''}',
          email: '${profile['email'] ?? ''}',
          phone: '${profile['phone'] ?? ''}',
          role: '${profile['role'] ?? 'customer'}',
        );
      }).toList();
      notifyListeners();
    } catch (_) {
      // Customer counts are an optional overview metric; RLS remains authoritative.
    }
  }

  Future<void> signIn(String email, String password) async {
    await client.auth.signInWithPassword(
        email: email.trim().toLowerCase(), password: password);
    await _loadUser();
  }

  Future<bool> signUp(
      {required String name,
      required String email,
      required String phone,
      required String password}) async {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    final normalized = digits.startsWith('91') && digits.length == 12
        ? digits.substring(2)
        : digits;
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(normalized)) {
      throw const FormatException(
          'Enter a valid 10 digit Indian mobile number.');
    }
    final response = await client.auth.signUp(
      email: email.trim().toLowerCase(),
      password: password,
      data: {'name': name.trim(), 'phone': '+91$normalized'},
    );
    if (response.session != null) await _loadUser();
    return response.session != null;
  }

  Future<void> signOut() async {
    await client.auth.signOut(scope: SignOutScope.local);
    user = null;
    cart = [];
    orders = [];
    customers = [];
    notifyListeners();
  }

  Future<void> deleteAccountSession() async {
    await signOut();
  }

  Future<void> toggleWishlist(String productId) async {
    if (wishlistIds.contains(productId)) {
      wishlistIds.remove(productId);
    } else {
      wishlistIds.add(productId);
    }
    await _preferences?.setStringList(
        'ajiomart-wishlist', wishlistIds.toList());
    notifyListeners();
  }

  Future<void> addToCart(ShopProduct product,
      {required String color, required String size}) async {
    final currentUser = user;
    if (currentUser == null) {
      throw const FormatException('Sign in to save items to your cart.');
    }
    final available =
        products.where((item) => item.id == product.id).firstOrNull?.stock ??
            product.stock;
    final inCart = cart
        .where((line) => line.product.id == product.id)
        .fold<int>(0, (sum, line) => sum + line.quantity);
    if (!product.active || available < 1 || inCart >= available) {
      throw const FormatException(
          'This item is out of stock or your cart already has the available quantity.');
    }
    final existing = cart
        .where((line) => line.key == '${product.id}-$size-$color')
        .firstOrNull;
    final nextQuantity = (existing?.quantity ?? 0) + 1;
    await client.from('cart_items').upsert({
      'user_id': currentUser.id,
      'product_id': product.id,
      'selected_size': size,
      'selected_color': color,
      'quantity': nextQuantity,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id,product_id,selected_size,selected_color');
    await refreshCart();
  }

  Future<void> setCartQuantity(CartLine line, int quantity) async {
    final currentUser = user;
    if (currentUser == null) return;
    if (quantity <= 0) {
      await client
          .from('cart_items')
          .delete()
          .eq('user_id', currentUser.id)
          .eq('product_id', line.product.id)
          .eq('selected_size', line.size)
          .eq('selected_color', line.color);
    } else {
      final otherQuantity = cart
          .where((item) =>
              item.product.id == line.product.id && item.key != line.key)
          .fold<int>(0, (sum, item) => sum + item.quantity);
      final product =
          products.where((item) => item.id == line.product.id).firstOrNull;
      if (product == null || otherQuantity + quantity > product.stock) {
        throw FormatException('Only ${product?.stock ?? 0} left in stock.');
      }
      await client.from('cart_items').upsert({
        'user_id': currentUser.id,
        'product_id': line.product.id,
        'selected_size': line.size,
        'selected_color': line.color,
        'quantity': quantity,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'user_id,product_id,selected_size,selected_color');
    }
    await refreshCart();
  }

  Future<void> clearCart() async {
    if (user != null) {
      await client.from('cart_items').delete().eq('user_id', user!.id);
    }
    cart = [];
    notifyListeners();
  }

  Future<AjiOrder> placeCodOrder(Map<String, String> shipping) async {
    final currentUser = user;
    if (currentUser == null) {
      throw const FormatException('Sign in to place your order.');
    }
    if (cart.isEmpty) throw const FormatException('Your cart is empty.');
    final result = await client.rpc('place_order', params: {
      'p_customer_name': shipping['customerName'],
      'p_customer_phone': shipping['customerPhone'],
      'p_address_line1': shipping['addressLine1'],
      'p_address_line2': shipping['addressLine2']?.isEmpty == true
          ? null
          : shipping['addressLine2'],
      'p_city': shipping['city'],
      'p_state': shipping['state'],
      'p_postal_code': shipping['postalCode'],
      'p_landmark':
          shipping['landmark']?.isEmpty == true ? null : shipping['landmark'],
      'p_payment_method': 'Cash on Delivery',
      'p_items': cart
          .map((line) => {
                'product_id': line.product.id,
                'quantity': line.quantity,
                'selected_color': line.color,
                'selected_size': line.size,
              })
          .toList(),
    });
    final payload = Map<String, dynamic>.from(result as Map);
    final orderJson = Map<String, dynamic>.from(payload['order'] as Map);
    orderJson['order_items'] = payload['order_items'] ?? [];
    final order = AjiOrder.fromJson(orderJson);
    await Future.wait([refreshProducts(), refreshCart(), refreshOrders()]);
    return order;
  }

  Future<Map<String, dynamic>> startOnlinePayment(
      Map<String, String> shipping) async {
    final result =
        await client.functions.invoke('create-razorpay-order', body: {
      'shipping': {
        'customerName': shipping['customerName'],
        'customerPhone': shipping['customerPhone'],
        'addressLine1': shipping['addressLine1'],
        'addressLine2': shipping['addressLine2'],
        'city': shipping['city'],
        'state': shipping['state'],
        'postalCode': shipping['postalCode'],
        'landmark': shipping['landmark'],
      },
      'items': cart
          .map((line) => {
                'id': line.product.id,
                'quantity': line.quantity,
                'color': line.color,
                'size': line.size,
              })
          .toList(),
    });
    if (result.data is Map && (result.data as Map)['error'] != null) {
      throw FormatException('${(result.data as Map)['error']}');
    }
    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<AjiOrder> verifyOnlinePayment(Map<String, dynamic> payment) async {
    final response =
        await client.functions.invoke('verify-razorpay-payment', body: payment);
    if (response.data is Map && (response.data as Map)['error'] != null) {
      throw FormatException('${(response.data as Map)['error']}');
    }
    final result = Map<String, dynamic>.from(response.data as Map);
    final orderJson = Map<String, dynamic>.from(result['order'] as Map);
    orderJson['order_items'] = result['order_items'] ?? [];
    final order = AjiOrder.fromJson(orderJson);
    await Future.wait([refreshProducts(), refreshCart(), refreshOrders()]);
    return order;
  }

  Future<void> saveProduct({
    String? id,
    required String name,
    required String category,
    required double price,
    required double originalPrice,
    required int stock,
    required double rating,
    required String badge,
    required List<String> colors,
    required List<String> sizes,
    required String description,
    required String hsnCode,
    required List<String> existingImageUrls,
    required List<XFile> newImages,
  }) async {
    if (existingImageUrls.length + newImages.length == 0) {
      throw const FormatException('Add at least one product image.');
    }
    if (existingImageUrls.length + newImages.length > 6) {
      throw const FormatException('Choose no more than 6 product images.');
    }
    final productId = id ?? _makeId();
    final uploadedUrls = <String>[];
    final storage = client.storage.from('product-images');
    for (final image in newImages) {
      final bytes = await image.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) {
        throw const FormatException(
            'Each product image must be 5 MB or smaller.');
      }
      final extension = image.name.contains('.')
          ? image.name.split('.').last.toLowerCase()
          : 'jpg';
      final path = '$productId/${_makeId()}.$extension';
      await storage.uploadBinary(path, Uint8List.fromList(bytes),
          fileOptions: FileOptions(
              contentType: lookupMimeType(image.name) ?? 'image/jpeg'));
      uploadedUrls.add(storage.getPublicUrl(path));
    }
    final imageUrls = [...existingImageUrls, ...uploadedUrls];
    final slug = name
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final product = ShopProduct(
      id: productId,
      slug: slug.isEmpty ? _makeId() : slug,
      name: name.trim(),
      category: category,
      price: price,
      originalPrice: originalPrice,
      stock: stock,
      rating: rating,
      badge: badge.trim(),
      colors: colors,
      sizes: sizes,
      imageUrls: imageUrls,
      description: description.trim(),
      hsnCode: hsnCode,
      active: true,
    );
    if (id == null) {
      await client.from('products').insert(product.toDatabase());
    } else {
      await client.from('products').update(product.toDatabase()).eq('id', id);
    }
    await refreshProducts();
  }

  Future<void> deleteProduct(String id) async {
    await client.from('products').delete().eq('id', id);
    await refreshProducts();
  }

  Future<void> updateOrder(String orderId, Map<String, dynamic> updates) async {
    final payload = <String, dynamic>{};
    if (updates.containsKey('status')) payload['status'] = updates['status'];
    if (updates.containsKey('courierPartner')) {
      payload['courier_partner'] = updates['courierPartner'];
    }
    if (updates.containsKey('trackingNumber')) {
      payload['tracking_number'] = _nullIfEmpty(updates['trackingNumber']);
    }
    if (updates.containsKey('trackingUrl')) {
      payload['tracking_url'] = _nullIfEmpty(updates['trackingUrl']);
    }
    if (updates.containsKey('trackingNote')) {
      payload['tracking_note'] = updates['trackingNote'];
    }
    if (updates.containsKey('packageWeightG')) {
      payload['package_weight_g'] = _intOrNull(updates['packageWeightG']);
    }
    if (updates.containsKey('packageLengthCm')) {
      payload['package_length_cm'] = _doubleOrNull(updates['packageLengthCm']);
    }
    if (updates.containsKey('packageWidthCm')) {
      payload['package_width_cm'] = _doubleOrNull(updates['packageWidthCm']);
    }
    if (updates.containsKey('packageHeightCm')) {
      payload['package_height_cm'] = _doubleOrNull(updates['packageHeightCm']);
    }
    if (updates.containsKey('eWaybill')) {
      payload['e_waybill'] = _nullIfEmpty(updates['eWaybill']);
    }
    await client.from('orders').update(payload).eq('id', orderId);
    await refreshOrders();
  }

  Future<void> deleteOrder(String id) async {
    await client.from('orders').delete().eq('id', id);
    await refreshOrders();
  }

  Future<Map<String, dynamic>> createDelhiveryShipment(String orderId) async {
    final response = await client.functions
        .invoke('delhivery-create-shipment', body: {'orderId': orderId});
    if (response.data is Map && (response.data as Map)['error'] != null) {
      throw FormatException('${(response.data as Map)['error']}');
    }
    await refreshOrders();
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> refreshDelhiveryTracking(String orderId) async {
    final response = await client.functions
        .invoke('delhivery-track-shipment', body: {'orderId': orderId});
    if (response.data is Map && (response.data as Map)['error'] != null) {
      throw FormatException('${(response.data as Map)['error']}');
    }
    await refreshOrders();
    return Map<String, dynamic>.from(response.data as Map);
  }

  static String _makeId() =>
      '${DateTime.now().microsecondsSinceEpoch}-${DateTime.now().millisecondsSinceEpoch % 997}';
  static dynamic _nullIfEmpty(dynamic value) =>
      value == null || value.toString().trim().isEmpty ? null : value;
  static int? _intOrNull(dynamic value) => int.tryParse('${value ?? ''}');
  static double? _doubleOrNull(dynamic value) =>
      double.tryParse('${value ?? ''}');

  static String _friendlyError(Object error) {
    if (error is PostgrestException) return error.message;
    if (error is AuthException) return error.message;
    if (error is FunctionException) {
      final details = error.details;
      if (details is Map && details['error'] != null) {
        return '${details['error']}';
      }
      return error.reasonPhrase ?? 'The server request failed.';
    }
    return error.toString().replaceFirst('Exception: ', '');
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

extension FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
