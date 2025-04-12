import 'package:flutter/material.dart';
import '../services/auth_service.dart';
// Import the new screen if needed for type checking, though not strictly required for routing by name

class AppDrawer extends StatelessWidget {
  final String currentRoute;

  const AppDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryColor = const Color(0xFF4CD964);

    return Drawer(
      backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      child: Column(
        children: [
          // Modern drawer header with gradient and logo
          Container(
            height: 170,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryColor,
                  primaryColor.withOpacity(0.7),
                ],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval( // Ensure the logo is clipped into a circular shape
                      child: Image.asset(
                        'assets/logodark.png',
                        height: 70,
                        width: 70, // Ensure the logo is square to fit the circle
                        fit: BoxFit.cover, // Scale the image to cover the circle
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Nomadly',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Your Smart Travel Companion',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Divider with subtle shadow
          Container(
            height: 1,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),

          // Main menu items
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  _buildCategoryLabel(context, 'MAIN', isDarkMode),

                  _buildDrawerItem(
                    context,
                    'Home',
                    Icons.home_rounded,
                    '/home',
                    currentRoute == '/home',
                    isDarkMode,
                    primaryColor,
                  ),

                  _buildDrawerItem(
                    context,
                    'Trip Planner',
                    Icons.map_rounded,
                    '/planner',
                    currentRoute == '/planner',
                    isDarkMode,
                    primaryColor,
                  ),

                  _buildDrawerItem(
                    context,
                    'Travel Deals', // Rename "Deals" to "Travel Deals"
                    Icons.local_offer_rounded,
                    '/travel-deals', // Update route
                    currentRoute == '/travel-deals',
                    isDarkMode,
                    primaryColor,
                  ),

                  _buildDrawerItem(
                    context,
                    'Deal Hunting', // Add new "Deal Hunting" option
                    Icons.search_rounded,
                    '/deal-hunting', // New route for Deal Hunting
                    currentRoute == '/deal-hunting',
                    isDarkMode,
                    primaryColor,
                  ),

                  const SizedBox(height: 16),
                  _buildCategoryLabel(context, 'TOOLS', isDarkMode),

                  _buildDrawerItem(
                    context,
                    'Currency Converter',
                    Icons.currency_exchange_rounded,
                    '/currency-converter',
                    currentRoute == '/currency-converter',
                    isDarkMode,
                    primaryColor,
                  ),

                  _buildDrawerItem(
                    context,
                    'Translation',
                    Icons.translate_rounded,
                    '/translation',
                    currentRoute == '/translation',
                    isDarkMode,
                    primaryColor,
                  ),

                  // Add Weather Forecast item
                  _buildDrawerItem(
                    context,
                    'Weather Forecast', // New item label
                    Icons.wb_sunny_rounded, // Choose an appropriate icon
                    '/weather-forecast', // New route name
                    currentRoute == '/weather-forecast',
                    isDarkMode,
                    primaryColor,
                  ),

                  const SizedBox(height: 16),
                  _buildCategoryLabel(context, 'FINANCE', isDarkMode),

                  _buildDrawerItem(
                    context,
                    'Expense Tracker',
                    Icons.account_balance_wallet_rounded,
                    '/expense-tracker',
                    currentRoute == '/expense-tracker',
                    isDarkMode,
                    primaryColor,
                  ),

                  _buildDrawerItem(
                    context,
                    'Group Expenses',
                    Icons.group_rounded,
                    '/travel-groups',
                    currentRoute == '/travel-groups',
                    isDarkMode,
                    primaryColor,
                  ),

                  _buildDrawerItem(
                    context,
                    'Statistics',
                    Icons.bar_chart_rounded,
                    '/statistics',
                    currentRoute == '/statistics',
                    isDarkMode,
                    primaryColor,
                  ),

                  const SizedBox(height: 16),
                  _buildCategoryLabel(context, 'ACCOUNT', isDarkMode),

                  _buildDrawerItem(
                    context,
                    'Profile',
                    Icons.person_rounded,
                    '/profile',
                    currentRoute == '/profile',
                    isDarkMode,
                    primaryColor,
                  ),
                ],
              ),
            ),
          ),

          // Logout button at the bottom
          Container(
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.1),
              border: Border(
                top: BorderSide(
                  color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                ),
              ),
            ),
            child: ListTile(
              leading: Icon(
                Icons.logout_rounded,
                color: Colors.red[400],
              ),
              title: Text(
                'Logout',
                style: TextStyle(
                  color: Colors.red[400],
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () => _confirmLogout(context),
              dense: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryLabel(BuildContext context, String label, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.grey[500] : Colors.grey[700],
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    String title,
    IconData icon,
    String route,
    bool isSelected,
    bool isDarkMode,
    Color primaryColor,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected 
            ? primaryColor.withOpacity(0.15) 
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected 
              ? primaryColor
              : (isDarkMode ? Colors.white70 : Colors.black54),
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            color: isSelected 
                ? primaryColor
                : (isDarkMode ? Colors.white : Colors.black87),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        dense: true,
        horizontalTitleGap: 12,
        onTap: () {
          Navigator.pop(context); // Close the drawer
          if (route != currentRoute) {
            // Navigate to selected route if it's not the current one
            Navigator.pushReplacementNamed(context, route);
          }
        },
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close drawer
                
                // Perform logout
                AuthService().logout().then((_) {
                  // Navigate to login screen
                  Navigator.pushNamedAndRemoveUntil(
                    context, 
                    '/sign-in', 
                    (route) => false,
                  );
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[400],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}
