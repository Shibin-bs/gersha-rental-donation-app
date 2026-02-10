import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'home_tab_screen.dart';
import 'list_item_tab_screen.dart';
import 'receive_rent_tab_screen.dart';
import 'login_screen.dart';

/// Main app screen with bottom navigation bar containing 3 tabs
/// Home: donation and rental history
/// List an Item: donate or rent out an item
/// Receive or Rent: browse and request available items
class MainAppScreen extends StatefulWidget {
  const MainAppScreen({super.key});

  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  int _currentIndex = 0;

  // List of screens for bottom navigation
  final List<Widget> _screens = [
    const HomeTabScreen(), // Home tab - shows history
    const ListItemTabScreen(), // List Item tab - list items for donation/rent
    const ReceiveRentTabScreen(), // Receive/Rent tab - browse and receive/rent items
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final isAdmin = authProvider.isAdmin;

        return Scaffold(
          appBar: AppBar(
            title: const Text('GERSHA'),
            actions: [
              // Logout button
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Logout',
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await authProvider.signOut();
                    // Navigation happens automatically via authStateChanges in AuthWrapperScreen
                  }
                },
              ),
            ],
          ),
          body: _screens[_currentIndex],
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.add_circle_outline),
                selectedIcon: Icon(Icons.add_circle),
                label: 'List Item',
              ),
              NavigationDestination(
                icon: Icon(Icons.shopping_bag_outlined),
                selectedIcon: Icon(Icons.shopping_bag),
                label: 'Receive/Rent',
              ),
            ],
          ),
        );
      },
    );
  }
}
