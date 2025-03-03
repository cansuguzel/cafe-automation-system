import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StockPage extends StatefulWidget {
  @override
  _StockPageState createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  List<dynamic> categories = [];
  List<dynamic> products = [];
  List<dynamic> filteredProducts = [];
  int? selectedCategoryID;
  bool loading = false;

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
      final categoryResponse =
          await http.get(Uri.parse('http://192.168.88.155/myapi/get_categories.php'));
      final productResponse =
          await http.get(Uri.parse('http://192.168.88.155/myapi/get_products.php'));

      if (categoryResponse.statusCode == 200 && productResponse.statusCode == 200) {
        final categoryData = json.decode(categoryResponse.body);
        final productData = json.decode(productResponse.body);

        setState(() {
          categories = categoryData;
          products = productData;
          if (categories.isNotEmpty) {
            selectedCategoryID = categories[0]['CategoryID']; // Varsayılan olarak ilk kategori seçilir.
            filterProductsByCategory(selectedCategoryID!);
          }
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
      filteredProducts =
          products.where((product) => product['CategoryID'] == categoryID).toList();
    });
  }

  void showError(String message) {
    setState(() {
      loading = false;
    });
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Hata"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Tamam"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Stok Yönetimi"),
      ),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Kategori seçimi
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: categories.map((category) {
                      return GestureDetector(
                        onTap: () {
                          filterProductsByCategory(category['CategoryID']);
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          margin: EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: selectedCategoryID == category['CategoryID']
                                ? Colors.blue
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            category['CategoryName'],
                            style: TextStyle(
                              color: selectedCategoryID == category['CategoryID']
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                Expanded(
                  child: filteredProducts.isEmpty
                      ? Center(child: Text("Bu kategoriye ait ürün bulunamadı."))
                      : ListView.builder(
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = filteredProducts[index];
                            return ListTile(
                              title: Text(product['ProductName']),
                              subtitle: Text("Stok: ${product['StockQuantity']}"),
                              trailing: IconButton(
                                icon: Icon(Icons.edit),
                                onPressed: () {
                                  showEditDialog(context, product);
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Yeni ürün ekleme işlemi
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddProductScreen(
               selectedCategoryID: selectedCategoryID, // Seçilen kategori ID'yi gönderiyoruz
            )),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }

  void showEditDialog(BuildContext context, dynamic product) {
    TextEditingController stockController =
        TextEditingController(text: product['StockQuantity'].toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Stok Güncelle"),
          content: TextField(
            controller: stockController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: "Yeni Stok"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("İptal"),
            ),
            ElevatedButton(
              onPressed: () async {
                // Stok güncelleme işlemi
                await updateProductStock(
                    product['ProductID'], int.parse(stockController.text));
                fetchData(); // Verileri güncelle
                Navigator.pop(context);
              },
              child: Text("Kaydet"),
            ),
          ],
        );
      },
    );
  }

  Future<void> updateProductStock(int productId, int newStock) async {
    final url = Uri.parse('http://192.168.88.155/myapi/update_stock.php');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "ProductID": productId,
        "NewStock": newStock,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Stok güncellenemedi');
    }
  }
}
//yeni ürün ekleme sayfası
class AddProductScreen extends StatefulWidget {
  final int? selectedCategoryID; // Seçilen kategori ID'yi parametre olarak al

  AddProductScreen({required this.selectedCategoryID});

  @override
  _AddProductScreenState createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final TextEditingController productNameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController stockQuantityController = TextEditingController();
  bool isLoading = false;

  // Ürün ekleme fonksiyonu
  Future<void> addProduct() async {
    setState(() {
      isLoading = true;
    });

    // API isteği
    final url = Uri.parse('http://192.168.88.155/myapi/add_product.php'); // API URL'i
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "ProductName": productNameController.text,
        "Price": int.parse(priceController.text),
        "StockQuantity": int.parse(stockQuantityController.text),
        "CategoryID": widget.selectedCategoryID, // Parametre olarak gelen kategori ID
      }),
    );

    setState(() {
      isLoading = false;
    });

    // Cevabı kontrol et
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("API Yanıtı: $data");  // API yanıtını konsola yazdır

      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ürün başarıyla eklendi! ID: ${data['ProductID']}")),
        );
        Navigator.pop(context); // Ekranı kapat
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata: ${data['error']}")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("API isteği başarısız.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Yeni Ürün Ekle"),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: productNameController,
                    decoration: InputDecoration(labelText: "Ürün Adı"),
                  ),
                  TextField(
                    controller: priceController,
                    decoration: InputDecoration(labelText: "Fiyat"),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: stockQuantityController,
                    decoration: InputDecoration(labelText: "Stok Miktarı"),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: addProduct,
                    child: Text("Ekle"),
                  ),
                ],
              ),
            ),
    );
  }
}
