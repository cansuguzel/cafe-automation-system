import 'dart:convert'; 
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PaymentPage extends StatefulWidget {
  const PaymentPage({Key? key}) : super(key: key);

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  int? orderId; 
  double orderTotal = 0.0; // Sipariş toplam tutarı
  String paymentMethod = 'Nakit'; // Ödeme yöntemi varsayılan olarak nakit

  @override
  void initState() {
    super.initState();
    _fetchOrderIdAndTotal(); // Sipariş ID'sini ve toplamını al
  }

  // Siparişin ID'sini ve toplamını al
  Future<void> _fetchOrderIdAndTotal() async {
    try {
      final lastOrderResponse = await http.get(Uri.parse('http://192.168.88.155/myapi/get_last_order.php'));

      if (lastOrderResponse.statusCode == 200) {
        final lastOrderData = json.decode(lastOrderResponse.body);

        if (lastOrderData['orderId'] != null) {
          final fetchedOrderId = lastOrderData['orderId'];

          setState(() {
            orderId = fetchedOrderId; // Sipariş ID'sini güncelle
          });

          // Sonra toplam tutarı al
          final totalResponse = await http.get(
            Uri.parse('http://192.168.88.155/myapi/get_order_total.php?OrderID=$fetchedOrderId'),
          );

          if (totalResponse.statusCode == 200) {
            final totalData = json.decode(totalResponse.body);
            if (totalData['OrderTotal'] != null) {
              setState(() {
                orderTotal = totalData['OrderTotal'].toDouble(); // 'OrderTotal' anahtarını kullanarak tutarı güncelle
              });
            } else {
              throw Exception('Toplam tutar alınamadı.');
            }
          } else {
            throw Exception('Toplam tutar alınamadı.');
          }
        } else {
          throw Exception('Sipariş ID alınamadı.');
        }
      } else {
        throw Exception('Son sipariş alınamadı.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  // Ödeme işlemini başlat
  Future<void> _processPayment() async {
    if (orderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sipariş bilgileri alınamadı.')),
      );
      return;
    }

    try {
      // API'ye ödeme bilgilerini gönder
      final response = await http.post(
        Uri.parse('http://192.168.88.155/myapi/add_payment.php'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'OrderID': orderId,
          'PaymentAmount': orderTotal,
          'PaymentMethod': paymentMethod,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Ödeme başarılıysa, kullanıcıya bildirim göster
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('₺$orderTotal tutarında ödeme alındı.')),
        );

        // Ödeme sonrası önceki sayfaya dön
        Navigator.pop(context);
      } else {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Ödeme işlemi başarısız oldu.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ödeme Sayfası'),
      ),
      body: orderId == null
          ? const Center(child: CircularProgressIndicator()) // Veriler yükleniyor
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Sipariş Toplamı: ₺$orderTotal',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButton<String>(
                  value: paymentMethod,
                  onChanged: (String? newValue) {
                    setState(() {
                      paymentMethod = newValue!;
                    });
                  },
                  items: <String>['Nakit', 'Kredi Karti'].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _processPayment,
                  child: const Text('Ödeme Al'),
                ),
              ],
            ),
    );
  }
}
