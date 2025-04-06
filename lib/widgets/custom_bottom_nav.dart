import 'package:flutter/material.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Utiliser un index valide (0) si l'index est négatif pour éviter l'erreur d'assertion
    // tout en gardant l'apparence visuelle où aucun élément n'est sélectionné
    final validIndex = currentIndex < 0 ? 0 : currentIndex;
    
    return BottomNavigationBar(
      backgroundColor: Colors.black,
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      currentIndex: validIndex,
      onTap: onTap,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: 'Search',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.currency_exchange),
          label: 'Currency',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.translate),
          label: 'Translate',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
      ],
      // Si l'index est négatif, aucun élément ne sera visuellement sélectionné
      selectedItemColor: currentIndex < 0 ? Colors.grey : Color(0xFF4CD964),
      unselectedItemColor: Colors.grey,
    );
  }
}