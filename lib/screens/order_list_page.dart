import 'dart:convert';
import 'package:cafe/screens/garson.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class OrderListPage extends StatefulWidget {
  const OrderListPage({Key? key}) : super(key: key);

  @override
  _OrderListPageState createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
  List orders = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    setState(() {
      loading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://192.168.88.155/myapi/get_orders.php'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            orders = data;
            loading = false;
          });
        }
      } else {
        throw Exception('API hatası: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Siparişler alınırken bir hata oluştu: $e')),
        );
        setState(() {
          loading = false;
        });
      }
    }
  }

  void navigateToWaitorPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WaiterPage()),
    );
  }

  void deleteOrder(int orderId) {
    // Silme işlemi için onay dialogu
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Sipariş Sil - ID: $orderId'),
          content: const Text('Bu siparişi silmek istediğinize emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hayır'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  final response = await http.delete(
                    Uri.parse('http://192.168.88.155/myapi/delete_order.php?OrderID=$orderId'),
                  );

                  if (response.statusCode == 200) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sipariş başarıyla silindi.')),
                      );
                      fetchOrders(); // Listeyi güncelle
                    }
                  } else {
                    throw Exception('Silme API hatası: ${response.statusCode}');
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Sipariş silinirken bir hata oluştu: $e')),
                    );
                  }
                }
              },
              child: const Text('Evet'),
            ),
          ],
        );
      },
    );
  }

  // formatDate metodunun tanımlanması
  String formatDate(String rawDate) {
    if (rawDate.isEmpty) return 'Tarih bulunamadı';
    try {
      DateTime parsedDate = DateTime.parse(rawDate);

      // Tarihi manuel olarak formatla
      String day = parsedDate.day.toString().padLeft(2, '0');
      String month = parsedDate.month.toString().padLeft(2, '0');
      String year = parsedDate.year.toString();
      String hour = parsedDate.hour.toString().padLeft(2, '0');
      String minute = parsedDate.minute.toString().padLeft(2, '0');

      return '$day/$month/$year $hour:$minute'; // Örnek format: 28/12/2024 17:04
    } catch (e) {
      return 'Geçersiz tarih';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Siparişler'),
      ),
      body: Column(
        children: [
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : orders.isEmpty
                    ? const Center(child: Text('Henüz sipariş yok.'))
                    : ListView.builder(
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          String formattedDate = formatDate(order['OrderDate']['date']);
                          String totalPrice = order['TotalPrice'] != null
                              ? '₺${order['TotalPrice']}'
                              : 'Fiyat bulunamadı';

                          return Card(
                            margin: const EdgeInsets.all(8.0),
                            child: ExpansionTile(
                              title: Text('Sipariş ID: ${order['OrderID']}'),
                              subtitle: Text(
                                'Toplam: $totalPrice - Tarih: $formattedDate',
                              ),
                              children: [
                                ...(order['Products'] as List).map((product) {
                                  return ListTile(
                                    title: Text(product['ProductName'] ?? 'Ürün adı yok'),
                                    subtitle: Text(
                                      'Adet: ${product['Quantity']} - Toplam: ₺${product['ProductTotal']}',
                                    ),
                                    trailing: ElevatedButton(
                                      onPressed: () {
                                        // Güncelleme için UpdateOrderPage sayfasına yönlendirme
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => UpdateOrderPage(
                                              orderId: order['OrderID'],
                                              productId: product['ProductID'], // Ürün ID'sini alıyoruz
                                              currentQuantity: product['Quantity'].toString(),
                                            ),
                                          ),
                                        );
                                      },
                                      child: const Text('Güncelle'),
                                    ),
                                  );
                                }).toList(),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () => deleteOrder(order['OrderID']),
                                      child: const Text('Sil'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: navigateToWaitorPage,
                  child: const Text('Sipariş Ekle'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class UpdateOrderPage extends StatefulWidget {
  final int orderId;
  final int productId;
  final String currentQuantity;

  const UpdateOrderPage({
    Key? key,
    required this.orderId,
    required this.productId,
    required this.currentQuantity,
  }) : super(key: key);

  @override
  _UpdateOrderPageState createState() => _UpdateOrderPageState();
}

class _UpdateOrderPageState extends State<UpdateOrderPage> {
  final TextEditingController quantityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    quantityController.text = widget.currentQuantity; // Başlangıç değeri olarak mevcut miktarı göster
  }

  // Güncelleme işlemi
  Future<void> updateOrder() async {
  try {
    final response = await http.get(
      Uri.parse(
        'http://192.168.88.155/myapi/update_order.php?OrderID=${widget.orderId}&ProductID=${widget.productId}&Quantity=${quantityController.text}',
      ),
    );

    if (response.statusCode == 200) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sipariş başarıyla güncellendi.')),
        );
        Navigator.pop(context); // Güncellemeyi tamamladıktan sonra geri dön
      }
    } else {
      throw Exception('Güncelleme API hatası: ${response.statusCode}');
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Güncellenirken hata oluştu: $e')),
      );
    }
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Siparişi Güncelle'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Yeni Adet'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: updateOrder,
              child: const Text('Güncelle'),
            ),
          ],
        ),
      ),
    );
  }
}
