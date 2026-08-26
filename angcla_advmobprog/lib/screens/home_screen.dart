import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'cart_screen.dart';
import 'product_screen.dart';
import '../widgets/custom_text.dart';

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
                  'assets/images/nubdexchange_logo.png',
                  scale: 11.sp,
                )
              : CustomText(
                  text: _selectedIndex == 1
                      ? 'Cart'
                      : _selectedIndex == 2
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
            // Lab Activity 3 - Enhancement 1: Render CartScreen in main PageView container
            CartScreen(),
            Center(
              child: CustomText(text: 'Profile Page', fontSize: 18),
            ),
          ],
        ),
        // Lab Activity 3 - Enhancement 2: Make the chat bottom navigation as FloatingActionButton.
        // When in the cart_screen (_selectedIndex == 1), the FloatingActionButton must be hidden (null).
        floatingActionButton: _selectedIndex == 1
            ? null
            : FloatingActionButton(
                onPressed: () => _openChatSheet(context),
                backgroundColor: Colors.blueAccent,
                child: const Icon(Icons.chat, color: Colors.white),
              ),
        bottomNavigationBar: BottomNavigationBar(
          showSelectedLabels: false,
          showUnselectedLabels: false,
          currentIndex: _selectedIndex,
          onTap: _onTappedBar,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.shop_2),
              label: 'Shop',
            ),
            // Lab Activity 3 - Enhancement 2: Chat tab removed from BottomNavigationBar and replaced with Cart tab
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart),
              label: 'Cart',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
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

  // Basic chat UI that slides up from the bottom
  void _openChatSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (ctx) {
        return SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.55,
          child: Column(
            children: [
              SizedBox(height: 8.h),
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(12.w),
                child: CustomText(
                  text: 'Chat Support',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.all(16.w),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: CustomText(
                          text: 'Hi! How can we help you today?',
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: CustomText(
                          text: 'I have a question about my order.',
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 16.h),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24.r),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 10.h,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.send),
                      color: Colors.blueAccent,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
