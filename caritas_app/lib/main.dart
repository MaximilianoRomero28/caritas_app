import 'package:flutter/material.dart';
import 'package:caritas_app/productos_screen.dart';
import 'package:caritas_app/finanzas_screen.dart';
import 'package:caritas_app/familias_screen.dart';


void main() {
  runApp(const CaritasApp());
}

class CaritasApp extends StatelessWidget {
  const CaritasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Cáritas Stock",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A),
          primary: const Color(0xFF1E3A8A),
          secondary: const Color(0xFF108981),
          surface: const Color(0xFFF8FAFC)
        ),
        fontFamily: 'Roboto',
      ),
      home: const MainLayout(),
    );
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

   final List<Widget> _screens = [
    const ProductosScreen(),
    const FinanzasScreen(),
    const FamiliasScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Productos',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Finanzas',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_alt_outlined),
            selectedIcon: Icon(Icons.people_alt),
            label: 'Familias',
          ),
        ],
      ),
    );
  }
}