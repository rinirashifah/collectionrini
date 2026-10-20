import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/collection_provider.dart';
import '../providers/laundry_provider.dart';
import '../theme/app_colors.dart';
import 'collection_screen.dart';
import 'home_screen.dart';
import 'laundry_screen.dart';
import 'locations_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  void _onNavigateTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onSearchCollection(String query) {
    context.read<CollectionProvider>().setSearchQuery(query);
    setState(() {
      _currentIndex = 1; // Switch to Collection tab
    });
  }

  void _onFilterStatus(String status) {
    context.read<CollectionProvider>().setStatusFilter(status);
    setState(() {
      _currentIndex = 1; // Switch to Collection tab
    });
  }

  @override
  Widget build(BuildContext context) {
    final laundryProvider = context.watch<LaundryProvider>();
    final activeLaundryCount =
        laundryProvider.inLaundryItems.length + laundryProvider.readyToStoreItems.length;

    final List<Widget> pages = [
      HomeScreen(
        onNavigateTab: _onNavigateTab,
        onSearchCollection: _onSearchCollection,
        onFilterStatus: _onFilterStatus,
      ),
      const CollectionScreen(),
      const LocationsScreen(),
      const LaundryScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: AppColors.textLight,
              selectedLabelStyle: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.checkroom_outlined),
                  activeIcon: Icon(Icons.checkroom_rounded),
                  label: 'Collection',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.inventory_2_outlined),
                  activeIcon: Icon(Icons.inventory_2_rounded),
                  label: 'Locations',
                ),
                BottomNavigationBarItem(
                  icon: Badge(
                    isLabelVisible: activeLaundryCount > 0,
                    label: Text(
                      '$activeLaundryCount',
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                    backgroundColor: AppColors.primary,
                    child: const Icon(Icons.local_laundry_service_outlined),
                  ),
                  activeIcon: Badge(
                    isLabelVisible: activeLaundryCount > 0,
                    label: Text(
                      '$activeLaundryCount',
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                    backgroundColor: AppColors.primary,
                    child: const Icon(Icons.local_laundry_service_rounded),
                  ),
                  label: 'Laundry',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.settings_outlined),
                  activeIcon: Icon(Icons.settings_rounded),
                  label: 'Settings',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
