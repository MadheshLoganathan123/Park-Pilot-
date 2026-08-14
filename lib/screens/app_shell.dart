import 'package:flutter/material.dart';
import '../services/parking_data_service.dart';
import 'customer/customer_home_screen.dart';
import 'customer/find_parking_screen.dart';
import 'customer/customer_bookings_screen.dart';
import 'customer/customer_profile_screen.dart';
import 'provider/provider_dashboard_screen.dart';
import 'provider/provider_slot_status_screen.dart';
import 'provider/provider_bookings_screen.dart';
import 'provider/provider_profile_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _customerTabIndex = 0;
  int _providerTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final dataService = ParkingDataService();

    return AnimatedBuilder(
      animation: dataService,
      builder: (context, _) {
        final isCustomer = dataService.currentRole == AppUserRole.customer;

        final customerPages = [
          const CustomerHomeScreen(),
          const FindParkingScreen(),
          const CustomerBookingsScreen(),
          const CustomerProfileScreen(),
        ];

        final providerPages = [
          const ProviderDashboardScreen(),
          const ProviderSlotStatusScreen(),
          const ProviderBookingsScreen(),
          const ProviderProfileScreen(),
        ];

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                // Persistent Global Error Banner
                ValueListenableBuilder<String?>(
                  valueListenable: dataService.globalErrorNotifier,
                  builder: (context, error, _) {
                    if (error == null || error.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return MaterialBanner(
                      backgroundColor: const Color(0xFFFEF2F2),
                      elevation: 2,
                      leading: const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626)),
                      content: Text(
                        error,
                        style: const TextStyle(
                          color: Color(0xFFDC2626),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => dataService.clearGlobalError(),
                          child: const Text(
                            'DISMISS',
                            style: TextStyle(
                              color: Color(0xFFDC2626),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                // Main Page Content
                Expanded(
                  child: IndexedStack(
                    index: isCustomer ? _customerTabIndex : _providerTabIndex,
                    children: isCustomer ? customerPages : providerPages,
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: isCustomer ? _customerTabIndex : _providerTabIndex,
              onTap: (index) {
                setState(() {
                  if (isCustomer) {
                    _customerTabIndex = index;
                  } else {
                    _providerTabIndex = index;
                  }
                });
              },
              backgroundColor: Colors.white,
              selectedItemColor: const Color(0xFF005DAC),
              unselectedItemColor: const Color(0xFF94A3B8),
              showSelectedLabels: true,
              showUnselectedLabels: true,
              type: BottomNavigationBarType.fixed,
              selectedLabelStyle:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              unselectedLabelStyle: const TextStyle(fontSize: 12),
              items: isCustomer
                  ? const [
                      BottomNavigationBarItem(
                        icon: Icon(Icons.home_outlined),
                        activeIcon: Icon(Icons.home_rounded),
                        label: 'Home',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.explore_outlined),
                        activeIcon: Icon(Icons.explore_rounded),
                        label: 'Explore',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.receipt_long_outlined),
                        activeIcon: Icon(Icons.receipt_long_rounded),
                        label: 'Reservations',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.person_outline_rounded),
                        activeIcon: Icon(Icons.person_rounded),
                        label: 'Profile',
                      ),
                    ]
                  : const [
                      BottomNavigationBarItem(
                        icon: Icon(Icons.dashboard_outlined),
                        activeIcon: Icon(Icons.dashboard_rounded),
                        label: 'Dashboard',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.grid_view_outlined),
                        activeIcon: Icon(Icons.grid_view_rounded),
                        label: 'Slots',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.confirmation_number_outlined),
                        activeIcon: Icon(Icons.confirmation_number_rounded),
                        label: 'Bookings',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.person_outline_rounded),
                        activeIcon: Icon(Icons.person_rounded),
                        label: 'Profile',
                      ),
                    ],
            ),
          ),
        );
      },
    );
  }
}
