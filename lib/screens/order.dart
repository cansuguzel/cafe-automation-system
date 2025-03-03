import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'cart_page.dart'; 

class OrderPage extends StatefulWidget {
  final Map<String, dynamic> table;

  const OrderPage({super.key, required this.table});

  @override
  _OrderPageState createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  List categories = [];
  List products = [];
  List filteredProducts = [];
  Map<int, int> cart = {}; // Sepetteki ürünlerin ID ve miktarlarını tutar
  int selectedCategoryID = 1; // Varsayılan kategori ID
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() {
      loading = true;
    });

    try {
      final categoryResponse = await http.get(Uri.parse('http://192.168.88.155/myapi/get_categories.php'));
      final productResponse = await http.get(Uri.parse('http://192.168.88.155/myapi/get_products.php'));

      if (categoryResponse.statusCode == 200 && productResponse.statusCode == 200) {
        final categoryData = json.decode(categoryResponse.body);
        final productData = json.decode(productResponse.body);

        setState(() {
          categories = categoryData;
          products = productData;
          filteredProducts = products.where((product) => product['CategoryID'] == selectedCategoryID).toList();
          loading = false;
        });
      } else {
        showError('Veri alınırken bir hata oluştu.');
      }
    } catch (e) {
      showError('Bağlantı hatası: $e');
    }
  }

  void filterProductsByCategory(int categoryID) {
    setState(() {
      selectedCategoryID = categoryID;
      filteredProducts = products.where((product) => product['CategoryID'] == categoryID).toList();
    });
  }

  void updateCart(int productId, int stock, bool increment) {
    setState(() {
      final currentQuantity = cart[productId] ?? 0;

      if (increment && currentQuantity < stock) {
        cart[productId] = currentQuantity + 1;
      } else if (!increment && currentQuantity > 0) {
        cart[productId] = currentQuantity - 1;
        if (cart[productId] == 0) {
          cart.remove(productId); // Eğer miktar 0 olursa ürünü sepetten çıkar
        }
      }
    });
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Text('Sipariş Ekle'),
            const SizedBox(width: 16),
            Text(
              ' ${widget.table['TableName']}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Kategori Listesi
                  SizedBox(
                    height: 60,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        return GestureDetector(
                          onTap: () => filterProductsByCategory(category['CategoryID']),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: selectedCategoryID == category['CategoryID']
                                  ? Colors.blue
                                  : Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                category['CategoryName'],
                                style: TextStyle(
                                  color: selectedCategoryID == category['CategoryID']
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Ürünler Listesi
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1,
                      ),
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = filteredProducts[index];
                        return Card(
                          elevation: 4,
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  product['ProductName'],
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text('₺${product['Price']}'),
                                const SizedBox(height: 8),
                                Text('Stok: ${product['StockQuantity']}'),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove, color: Colors.red),
                                      onPressed: () {
                                        updateCart(product['ProductID'], product['StockQuantity'], false);
                                      },
                                    ),
                                    Text(
                                      '${cart[product['ProductID']] ?? 0}',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add, color: Colors.green),
                                      onPressed: () {
                                        updateCart(product['ProductID'], product['StockQuantity'], true);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Sepete Git Butonu
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CartPage(
                                cart: cart,
                                products: products,
                                tableId: widget.table['TableID'], 
                              ),
                            ),
                          );
                        },
                        child: const Text('Sepete Git'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
