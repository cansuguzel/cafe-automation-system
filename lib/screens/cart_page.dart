import 'dart:convert';
import 'package:cafe/screens/payment_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CartPage extends StatefulWidget {
  final Map<int, int> cart; // Sepetteki ürünlerin ID ve miktarlarını tutan map
  final List products; // Ürünlerin listesini tutan liste
  final int tableId; // Masa ID'si

  const CartPage({
    Key? key,
    required this.cart,
    required this.products,
    required this.tableId,
  }) : super(key: key);

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  double totalPrice = 0.0; // Toplam fiyatı saklamak için
  bool isLoading = false; // Yükleniyor durumunu kontrol eden değişken

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _calculateTotalPrice(); // Toplam fiyatı hesapla
  }

  // Sepetteki toplam fiyatı hesaplayan fonksiyon
  void _calculateTotalPrice() {
    double total = 0.0;

    // Sepetteki her ürünü kontrol et
    widget.cart.forEach((productId, quantity) {
      // Ürün bilgilerini ürün listesinde bul
      final product = widget.products.firstWhere(
        (product) => product['ProductID'] == productId,
        orElse: () => null,
      );

      // Ürün varsa toplam fiyatı hesapla
      if (product != null && product['Price'] != null) {
        total += (product['Price'] * quantity);
      }
    });

    // Toplam fiyatı state'e aktar
    setState(() {
      totalPrice = total;
    });
  }

  Future<void> _submitOrder() async {
  try {
    setState(() {
      isLoading = true; // Yükleniyor durumunu başlat
    });

    // Sepetteki tüm siparişleri bir liste halinde hazırla
    List<Map<String, dynamic>> orderItems = [];

    widget.cart.forEach((productId, quantity) {
      final product = widget.products.firstWhere(
        (product) => product['ProductID'] == productId,
        orElse: () => null,
      );

      if (product != null) {
        orderItems.add({
          'ProductID': productId,
          'Quantity': quantity,
        });
      }
    });

    // OrderItems'ı JSON formatına dönüştür
    String orderItemsJson = json.encode(orderItems);
    print('Gönderilen OrderItems JSON: $orderItemsJson');

    // POST isteğini gönder
    final response = await http.post(
      Uri.parse('http://192.168.88.155/myapi/add_order.php'),
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        'TableID': widget.tableId,
        'OrderItems': orderItemsJson,
      }),
    );
    print('Sunucudan Gelen Yanıt: ${response.body}');

    // Hata olsa bile PaymentPage'e yönlendir
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => PaymentPage()),
    );
  } catch (e) {
    // Hata mesajını yalnızca konsola yazdır
    print("Hata: $e");

    // Her durumda PaymentPage'e yönlendir
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => PaymentPage()),
    );
  } finally {
    setState(() {
      isLoading = false; // Yükleniyor durumunu bitir
    });
  }
}

  @override
  Widget build(BuildContext context) {
    // Sepetteki ürünleri göstermek için ürün bilgilerini cart ile eşleştir
    final cartItems = widget.products.where((product) => widget.cart.keys.contains(product['ProductID'])).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sepet'),
      ),
      body: Column(
        children: [
          // Sepet ürünlerinin listesi
          Expanded(
            child: ListView.builder(
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final product = cartItems[index];
                final quantity = widget.cart[product['ProductID']] ?? 0;

                return ListTile(
                  title: Text(product['ProductName']),
                  subtitle: Text('₺${product['Price']} x $quantity'),
                  trailing: Text('Toplam: ₺${product['Price'] * quantity}'),
                );
              },
            ),
          ),

          // Toplam fiyatı gösteren bölüm
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  'Toplam Fiyat: ₺$totalPrice', // Hesaplanan toplam fiyat
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: isLoading ? null : _submitOrder, // Yükleniyor durumunda butona basılamaz
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Siparişi Onayla'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
