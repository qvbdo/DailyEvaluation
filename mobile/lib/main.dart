import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/app_providers.dart';
import 'screens/daily_evaluation_screen.dart';
import 'screens/student_database_screen.dart';
import 'screens/group_distribution_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/course_cycle_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const EvaApp(),
    ),
  );
}

class EvaApp extends StatelessWidget {
  const EvaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eva - تقييم الممارسة اليومية',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar', 'IQ'),
      supportedLocales: const [
        Locale('ar', 'IQ'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xff1a5276),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff1a5276),
          primary: const Color(0xff1a5276),
          secondary: const Color(0xff16a085),
          background: const Color(0xfff5f6fa),
        ),
        fontFamily: 'Tahoma',
        cardTheme: const CardThemeData(
          elevation: 1.5,
          margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        ),
      ),
      home: const MainNavigationShell(),
    );
  }
}

class MainNavigationShell extends ConsumerStatefulWidget {
  const MainNavigationShell({super.key});

  @override
  ConsumerState<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends ConsumerState<MainNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    AnalyticsScreen(), // Dashboard
    DailyEvaluationScreen(), // Daily Work
    CourseCycleScreen(), // Course / Cycle System
    StudentDatabaseScreen(), // Student DB
    GroupDistributionScreen(), // Group/Hospital distribution and rosters
  ];

  @override
  Widget build(BuildContext context) {
    // Responsive Layout detection (iPad/Tablet landscape uses Side Navigation Rail)
    final double width = MediaQuery.of(context).size.width;
    final bool isTablet = width >= 720;

    final List<NavigationDestination> destinations = const [
      NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: 'لوحة التحكم',
      ),
      NavigationDestination(
        icon: Icon(Icons.assignment_outlined),
        selectedIcon: Icon(Icons.assignment),
        label: 'العمل اليومي',
      ),
      NavigationDestination(
        icon: Icon(Icons.sync_alt_outlined),
        selectedIcon: Icon(Icons.sync_alt),
        label: 'نظام الدورة',
      ),
      NavigationDestination(
        icon: Icon(Icons.people_outline),
        selectedIcon: Icon(Icons.people),
        label: 'قاعدة البيانات',
      ),
      NavigationDestination(
        icon: Icon(Icons.local_hospital_outlined),
        selectedIcon: Icon(Icons.local_hospital),
        label: 'توزيع المجاميع',
      ),
    ];

    return Scaffold(
      body: Row(
        children: [
          if (isTablet)
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: (int index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              extended: width >= 1000,
              labelType: width >= 1000 ? NavigationRailLabelType.none : NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 8.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      radius: 28,
                      child: const Text(
                        '🏥',
                        style: TextStyle(fontSize: 28),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (width >= 1000)
                      const Text(
                        'تقييم الممارسة اليومية',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff1a5276),
                        ),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
              destinations: destinations
                  .map(
                    (d) => NavigationRailDestination(
                      icon: d.icon,
                      selectedIcon: d.selectedIcon,
                      label: Text(d.label),
                    ),
                  )
                  .toList(),
            ),
          Expanded(
            child: _screens[_currentIndex],
          ),
        ],
      ),
      bottomNavigationBar: isTablet
          ? null
          : NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (int index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              destinations: destinations,
            ),
    );
  }
}
