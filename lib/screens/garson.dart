import 'dart:convert';
import 'package:cafe/screens/order.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class WaiterPage extends StatefulWidget {
  const WaiterPage({super.key});

  @override
  State<WaiterPage> createState() => _WaiterPageState();
}

class _WaiterPageState extends State<WaiterPage> {
  List tables = [];
  bool isLoading = true;
  Map<String, dynamic>? selectedTable;

  @override
  void initState() {
    super.initState();
    fetchTables();
  }

 Future<void> fetchTables() async {
  final url = Uri.parse('http://192.168.88.155/myapi/get_tables.php');
  try {
    final response = await http.get(url).timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (mounted) {
        setState(() {
          tables = data;
          isLoading = false; // Yükleme tamamlandı
        });
      }
    } else {
      print('Server error: ${response.statusCode}');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        showError('Sunucu hatası: ${response.statusCode}');
      }
    }
  } catch (e) {
    print('Error: $e');
    if (mounted) {
      setState(() {
        isLoading = false;
      });
      showError('Bağlantı hatası: $e');
    }
  }
}



  void showError(String message) {
    // context'in hala geçerli olduğundan emin oluyorum
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Masalar'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16.0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: tables.length,
                    itemBuilder: (context, index) {
                      final table = tables[index];
                      final tableName = table['TableName'] ?? 'Bilinmeyen Masa';
                      final isSelected = selectedTable == table;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedTable = table;
                          });
                        },
                        child: Card(
                          color: isSelected ? Colors.orange : Colors.lightBlueAccent,
                          child: Center(
                            child: Text(
                              tableName,
                              style: const TextStyle(fontSize: 18, color: Colors.white),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                ElevatedButton(
                  onPressed: selectedTable == null
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrderPage(
                                table: selectedTable!,
                              ),
                            ),
                          );
                        },
                  child: const Text('Sipariş Al'),
                ),
              ],
            ),
    );
  }
}
