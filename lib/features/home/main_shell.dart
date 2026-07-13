import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/bottom_nav_bar.dart';
import '../home/home_screen.dart';
import '../explore/explore_screen.dart';
import '../applications/applications_screen.dart';
import '../messages/messages_screen.dart';
import '../profile/student_profile_screen.dart';
import '../home/startup_dashboard_screen.dart';
import '../applications/startup_applicants_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.darkBackground,
            body: Center(child: CircularProgressIndicator(color: AppColors.secondary)),
          );
        }

        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final role = data?['role'] ?? 'student';

        if (role == 'startup') {
          return _StartupShell();
        }
        return _StudentShell();
      },
    );
  }
}

// ── Student Shell ─────────────────────────────────────────────────────────────

class _StudentShell extends StatefulWidget {
  @override
  State<_StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<_StudentShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    ExploreScreen(),
    ApplicationsScreen(),
    MessagesScreen(),
    StudentProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ── Startup Shell ─────────────────────────────────────────────────────────────

class _StartupShell extends StatefulWidget {
  @override
  State<_StartupShell> createState() => _StartupShellState();
}

class _StartupShellState extends State<_StartupShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    StartupDashboardScreen(),
    StartupApplicantsScreen(),
    MessagesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _StartupNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

class _StartupNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _StartupNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      {'icon': Icons.dashboard_outlined, 'activeIcon': Icons.dashboard, 'label': 'Dashboard'},
      {'icon': Icons.people_outline, 'activeIcon': Icons.people, 'label': 'Applicants'},
      {'icon': Icons.chat_bubble_outline, 'activeIcon': Icons.chat_bubble, 'label': 'Messages'},
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.darkSurface,
        border: Border(top: BorderSide(color: AppColors.darkBorder)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            children: items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              final isSelected = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isSelected ? item['activeIcon'] as IconData : item['icon'] as IconData,
                        color: isSelected ? AppColors.primary : AppColors.darkTextSecondary,
                        size: 22,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['label'] as String,
                        style: TextStyle(
                          color: isSelected ? AppColors.primary : AppColors.darkTextSecondary,
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}