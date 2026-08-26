import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../widgets/custom_text.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Enhancement 3: watch ThemeProvider so the switch updates when theme changes
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const CustomText(
          text: 'Settings',
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: ListView(
        children: [
          // Enhancement 3: Add settings page to move the dark/light mode switch
          SwitchListTile(
            title: CustomText(
              text: themeProvider.isDark ? 'Dark Mode' : 'Light Mode',
              fontSize: 16,
            ),
            value: themeProvider.isDark,
            onChanged: (_) {
              // Enhancement 3: toggle light/dark theme via Provider
              themeProvider.toggleTheme();
            },
          ),
        ],
      ),
    );
  }
}
