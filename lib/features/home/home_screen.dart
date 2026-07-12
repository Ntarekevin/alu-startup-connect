import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/opportunity_card.dart';
import '../explore/opportunity_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, userSnap) {
          final userData = userSnap.data?.data() as Map<String, dynamic>?;
          final userName = userData?['name'] ?? 'there';

          return CustomScrollView(
            slivers: [
              // ── App Bar ────────────────────────────────────────────────────
              SliverAppBar(
                backgroundColor: AppColors.background,
                floating: true,
                pinned: false,
                toolbarHeight: 64,
                title: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good morning 👋',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          userName.split(' ').first,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => context.push('/notifications'),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: const Icon(Icons.notifications_outlined,
                            color: AppColors.textPrimary, size: 20),
                      ),
                    ),
                    const SizedBox(width: 10),
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.teal,
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                        style: const TextStyle(
                            color: AppColors.background,
                            fontWeight: FontWeight.w700,
                            fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Stats Row ──────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('applications')
                        .where('studentId', isEqualTo: uid)
                        .snapshots(),
                    builder: (context, appSnap) {
                      final docs = appSnap.data?.docs ?? [];
                      final total = docs.length;
                      final interviews = docs
                          .where((d) =>
                              (d.data() as Map<String, dynamic>)['status'] ==
                              'interview')
                          .length;
                      final offers = docs
                          .where((d) =>
                              (d.data() as Map<String, dynamic>)['status'] ==
                              'offer')
                          .length;

                      return Row(
                        children: [
                          _StatCard(
                              label: 'Applications',
                              value: '$total',
                              icon: Icons.assignment_outlined,
                              color: AppColors.teal),
                          const SizedBox(width: 12),
                          _StatCard(
                              label: 'Interviews',
                              value: '$interviews',
                              icon: Icons.calendar_today_outlined,
                              color: AppColors.statusInterview),
                          const SizedBox(width: 12),
                          _StatCard(
                              label: 'Offers',
                              value: '$offers',
                              icon: Icons.star_outline_rounded,
                              color: AppColors.gold),
                        ],
                      )
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: 0.1, end: 0);
                    },
                  ),
                ),
              ),

              // ── Featured Opportunities ─────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                  child: Row(
                    children: [
                      Text('Featured Roles',
                          style: Theme.of(context).textTheme.titleLarge),
                      const Spacer(),
                      Text('See all',
                          style: const TextStyle(
                              color: AppColors.teal,
                              fontSize: 13,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('opportunities')
                    .orderBy('postedAt', descending: true)
                    .limit(3)
                    .snapshots(),
                builder: (context, snapshot) {
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: const Text(
                            '✨ No opportunities yet — check back soon!',
                            style: TextStyle(color: AppColors.textMuted),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                  }

                  final opps = docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return OpportunityModel(
                      id: doc.id,
                      companyId: data['companyId'] ?? '',
                      companyName: data['companyName'] ?? 'Startup',
                      companyLogo: '',
                      title: data['title'] ?? '',
                      type: data['type'] ?? 'Internship',
                      location: data['location'] ?? 'Remote',
                      isRemote: data['isRemote'] ?? true,
                      duration: data['duration'] ?? '',
                      stipend: data['stipend'],
                      description: data['description'] ?? '',
                      category: data['category'] ?? '',
                      postedAt: (data['postedAt'] as Timestamp?)?.toDate() ??
                          DateTime.now(),
                      deadline: (data['deadline'] as Timestamp?)?.toDate() ??
                          DateTime.now().add(const Duration(days: 30)),
                    );
                  }).toList();

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => OpportunityCard(
                          opportunity: opps[i],
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  OpportunityDetailScreen(opportunity: opps[i]),
                            ),
                          ),
                        ),
                        childCount: opps.length,
                      ),
                    ),
                  );
                },
              ),

              // ── Recent Opportunities ───────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                  child: Row(
                    children: [
                      Text('Recent Listings',
                          style: Theme.of(context).textTheme.titleLarge),
                      const Spacer(),
                      Text('See all',
                          style: const TextStyle(
                              color: AppColors.teal,
                              fontSize: 13,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('opportunities')
                    .orderBy('postedAt', descending: true)
                    .limit(5)
                    .snapshots(),
                builder: (context, snapshot) {
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  }
                  final opps = docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return OpportunityModel(
                      id: doc.id,
                      companyId: data['companyId'] ?? '',
                      companyName: data['companyName'] ?? 'Startup',
                      companyLogo: '',
                      title: data['title'] ?? '',
                      type: data['type'] ?? 'Internship',
                      location: data['location'] ?? 'Remote',
                      isRemote: data['isRemote'] ?? true,
                      duration: data['duration'] ?? '',
                      stipend: data['stipend'],
                      description: data['description'] ?? '',
                      category: data['category'] ?? '',
                      postedAt: (data['postedAt'] as Timestamp?)?.toDate() ??
                          DateTime.now(),
                      deadline: (data['deadline'] as Timestamp?)?.toDate() ??
                          DateTime.now().add(const Duration(days: 30)),
                    );
                  }).toList();

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => OpportunityCard(
                          opportunity: opps[i],
                          compact: true,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  OpportunityDetailScreen(opportunity: opps[i]),
                            ),
                          ),
                        ),
                        childCount: opps.length,
                      ),
                    ),
                  );
                },
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
