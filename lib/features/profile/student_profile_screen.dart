import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, userSnap) {
          if (userSnap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.teal));
          }

          final data = userSnap.data?.data() as Map<String, dynamic>?;
          final name = data?['name'] ?? 'Student';
          final email = data?['email'] ?? '';
          final bio = data?['bio'] as String?;
          final major = data?['major'] as String?;
          final university = data?['university'] as String?;
          final graduationYear = data?['graduationYear'] as String?;
          final skills = List<String>.from(data?['skills'] ?? []);
          final linkedinUrl = data?['linkedinUrl'] as String?;
          final portfolioUrl = data?['portfolioUrl'] as String?;

          return CustomScrollView(
            slivers: [
              // ── Header ──────────────────────────────────────────────────────
              SliverAppBar(
                backgroundColor: AppColors.background,
                expandedHeight: 240,
                pinned: true,
                toolbarHeight: 56,
                title: const Text('My Profile'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.logout_outlined),
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) context.go('/auth');
                    },
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    children: [
                      // Cover gradient
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF0E1A45), Color(0xFF0A0F2E)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      // Decorative circle
                      Positioned(
                        right: -20,
                        top: -20,
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.teal.withOpacity(0.06),
                          ),
                        ),
                      ),
                      // Avatar & info
                      Positioned(
                        bottom: 16,
                        left: 20,
                        right: 20,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [AppColors.teal, Color(0xFF00A896)],
                                ),
                                border: Border.all(
                                    color: AppColors.background, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.teal.withOpacity(0.4),
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  name.isNotEmpty
                                      ? name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.background,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  if (major != null || university != null)
                                    Text(
                                      [major, university]
                                          .where((e) => e != null)
                                          .join(' · '),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  if (graduationYear != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.school_outlined,
                                            size: 12, color: AppColors.gold),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Class of $graduationYear',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.gold,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Content ──────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats (live from Firestore)
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('applications')
                            .where('studentId', isEqualTo: uid)
                            .snapshots(),
                        builder: (context, appSnap) {
                          final docs = appSnap.data?.docs ?? [];
                          final total = docs.length;
                          final interviews = docs
                              .where((d) =>
                                  (d.data() as Map<String, dynamic>)[
                                      'status'] ==
                                  'interview')
                              .length;
                          final offers = docs
                              .where((d) =>
                                  (d.data() as Map<String, dynamic>)[
                                      'status'] ==
                                  'offer')
                              .length;
                          return Row(
                            children: [
                              _ProfileStat(
                                  value: '$total', label: 'Applications'),
                              const SizedBox(width: 12),
                              _ProfileStat(
                                  value: '$interviews', label: 'Interviews'),
                              const SizedBox(width: 12),
                              _ProfileStat(value: '$offers', label: 'Offers'),
                            ],
                          )
                              .animate()
                              .fadeIn(delay: 100.ms, duration: 300.ms);
                        },
                      ),

                      const SizedBox(height: 24),

                      // Email
                      _ProfileSection(
                        title: 'Email',
                        child: Row(
                          children: [
                            const Icon(Icons.email_outlined,
                                size: 16, color: AppColors.teal),
                            const SizedBox(width: 8),
                            Text(email,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: AppColors.textPrimary)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // About
                      if (bio != null && bio.isNotEmpty) ...[
                        _ProfileSection(
                          title: 'About',
                          child: Text(
                            bio,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(height: 1.7),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Skills
                      if (skills.isNotEmpty) ...[
                        _ProfileSection(
                          title: 'Skills',
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: skills.map((s) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.teal.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: AppColors.teal.withOpacity(0.3)),
                                ),
                                child: Text(
                                  s,
                                  style: const TextStyle(
                                    color: AppColors.teal,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Links
                      if (linkedinUrl != null || portfolioUrl != null) ...[
                        _ProfileSection(
                          title: 'Links',
                          child: Column(
                            children: [
                              if (linkedinUrl != null)
                                _LinkRow(
                                  icon: Icons.link,
                                  label: 'LinkedIn',
                                  value: linkedinUrl,
                                  color: const Color(0xFF0077B5),
                                ),
                              if (linkedinUrl != null && portfolioUrl != null)
                                const SizedBox(height: 8),
                              if (portfolioUrl != null)
                                _LinkRow(
                                  icon: Icons.language,
                                  label: 'Portfolio',
                                  value: portfolioUrl,
                                  color: AppColors.teal,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String value;
  final String label;
  const _ProfileStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.teal,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style:
                  Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final Widget child;
  const _ProfileSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        child,
      ],
    ).animate().fadeIn(duration: 300.ms);
  }
}

class _LinkRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _LinkRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style:
                    const TextStyle(color: AppColors.textMuted, fontSize: 11)),
            Text(value,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
      ],
    );
  }
}
