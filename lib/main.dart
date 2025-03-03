import 'package:cafe/screens/order_list_page.dart';
import 'package:cafe/screens/report_page.dart';
import 'package:cafe/screens/stock_management_page.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Demli Kod Cafe',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demli Kod Cafe'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                // sipariş listesinin bulunduğu sayfaya yönlendirme
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const OrderListPage()),
                );
              },
              child: const Text('Garson'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Admin sayfasına yönlendirme
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminPage()),
                );
              },
              child: const Text('Admin'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // kasadaki ödeme sayfası (şimdilik boş)
              },
              child: const Text('Kasa'),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kafe Yönetimi'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                   Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ReportPage()),
                );
              },
              child: const Text('Raporlar'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => StockPage()),
             ); },
              child: const Text('Stok Yönetimi'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Rezervasyonlar sayfası (şimdilik boş)
              },
              child: const Text('Rezervasyonlar'),
            ),
          ],
        ),
      ),
    );
  }
}
