import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ReportPage extends StatefulWidget {
  @override
  _DailyReportPageState createState() => _DailyReportPageState();
}

class _DailyReportPageState extends State<ReportPage> {
  late Future<List<dynamic>> _dailyReport;
  late Future<List<dynamic>> _dailySummary; // Özet veriler için değişken
  late Future<Map<String, dynamic>> _totalSales; // Toplam satış verisi için değişken
  String _selectedDate = "2025-01-02"; // Varsayılan tarih

  @override
  void initState() {
    super.initState();
    _dailyReport = fetchDailyReport(_selectedDate);
    _dailySummary = fetchDailySummary(_selectedDate); // Özet verileri al
    _totalSales = fetchTotalSales(_selectedDate); // Toplam satış verisini al
  }

  Future<List<dynamic>> fetchDailyReport(String date) async {
    final url = Uri.parse('http://192.168.88.155/myapi/get_daily_report.php'); // PHP API URL'si
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"ReportDate": date}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Veriler alınamadı');
    }
  }

  Future<List<dynamic>> fetchDailySummary(String date) async {
    final url = Uri.parse('http://192.168.88.155/myapi/tbl_daily_reports.php'); // Özet veri API URL'si
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"ReportDate": date}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body); 
    } else {
      throw Exception('Özet verileri alınamadı');
    }
  }

  // Toplam satış verisini al
  Future<Map<String, dynamic>> fetchTotalSales(String date) async {
    final url = Uri.parse('http://192.168.88.155/myapi/get_daily_sales.php'); // Toplam satış API URL'si
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"ReportDate": date}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body); // Toplam satış verisi döner
    } else {
      throw Exception('Toplam satış verisi alınamadı');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Günlük Sipariş Detayları"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Tarih: $_selectedDate",
                  style: TextStyle(fontSize: 16),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Tarih seçici (datepicker)
                    DateTime? selectedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (selectedDate != null) {
                      setState(() {
                        _selectedDate =
                            selectedDate.toIso8601String().split('T')[0];
                        _dailyReport = fetchDailyReport(_selectedDate);
                        _dailySummary = fetchDailySummary(_selectedDate); // Tarih değiştiğinde özet veriyi güncelle
                        _totalSales = fetchTotalSales(_selectedDate); // Tarih değiştiğinde toplam satış verisini güncelle
                      });
                    }
                  },
                  child: Text("Tarih Seç"),
                ),
              ],
            ),
          ),
          // Toplam Satışı Göster
          FutureBuilder<Map<String, dynamic>>(
            future: _totalSales,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Hata: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text('Toplam satış verisi bulunamadı.'));
              } else {
                return Container(
                  padding: const EdgeInsets.all(16.0),
                  color: Colors.lightBlue[100],
                  child: Text(
                    "Toplam Satış: ${snapshot.data!['DailySales']}₺",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                );
              }
            },
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _dailyReport,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Hata: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('Veri bulunamadı.'));
                } else {
                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final report = snapshot.data![index];
                      return ListTile(
                        title: Text(report['ProductName'] ?? 'Ürün Adı Yok'),
                        subtitle: Text("Adet: ${report['TotalQuantity'] ?? 0}"),
                        trailing: Text("Gelir: ${report['TotalIncome']}₺"),
                      );
                    },
                  );
                }
              },
            ),
          ),
          FutureBuilder<List<dynamic>>(
            future: _dailySummary, 
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Hata: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text('Özet verileri alınamadı.'));
              } else {
                final summary = snapshot.data![0]; // API'den gelen ilk veriyi alıyoruz
                return Container(
                  padding: const EdgeInsets.all(16.0),
                  color: Colors.grey[200],
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: [
                      Text("Toplam Sipariş: ${summary['TotalOrders']}"),
                      Text("Toplam Ürün: ${summary['TotalProductsSold']}"),
                    ],
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
