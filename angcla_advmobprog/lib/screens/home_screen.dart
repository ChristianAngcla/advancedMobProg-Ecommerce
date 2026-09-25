import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'cart_screen.dart';
import 'chat_screen.dart';
import 'product_screen.dart';
import 'profile_screen.dart';
import '../widgets/custom_text.dart';

// LAB ACTIVITY 6 - CHAT NAVIGATION
// Main screen containing four tabs: Shop (0), Chat (1), Cart (2), and Profile (3).
class HomeScreen extends StatefulWidget {
  final String username;
  const HomeScreen({super.key, this.username = ''});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          elevation: 2,
          title: _selectedIndex == 0
              ? Image.asset(
                  'assets/images/nu_logo.png',
                  height: 38.h,
                  fit: BoxFit.contain,
                )
              : CustomText(
                  text: _selectedIndex == 1
                      ? 'Chat'
                      : _selectedIndex == 2
                      ? 'Cart'
                      : _selectedIndex == 3
                      ? 'Profile'
                      : 'Home',
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
          actions: [
            IconButton(
              onPressed: () {
                Navigator.pushNamed(context, '/settings');
              },
              icon: const Icon(Icons.settings),
            ),
          ],
        ),
        // LAB ACTIVITY 6 - CHAT NAVIGATION
        // PageView with exactly four tabs: Shop (0), Chat (1), Cart (2), Profile (3)
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          children: const [
            ProductScreen(),
            ChatScreen(),
            CartScreen(),
            ProfileScreen(),
          ],
        ),
        // LAB ACTIVITY 6 - CHAT NAVIGATION
        // BottomNavigationBar with exactly four tabs: Shop, Chat, Cart, Profile
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          currentIndex: _selectedIndex,
          onTap: _onTappedBar,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.shop_2), label: 'Shop'),
            BottomNavigationBarItem(
              icon: Icon(Icons.forum_rounded),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart),
              label: 'Cart',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  void _onTappedBar(int value) {
    setState(() {
      _selectedIndex = value;
    });
    _pageController.jumpToPage(value);
  }
}
