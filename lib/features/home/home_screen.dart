import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/opportunity_card.dart';
import '../../shared/widgets/curved_header.dart';
import '../../shared/widgets/tag_chip.dart';
import '../explore/opportunity_detail_screen.dart';
import '../explore/explore_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, userSnap) {
          final userData = userSnap.data?.data() as Map<String, dynamic>?;
          final firebaseName = FirebaseAuth.instance.currentUser?.displayName;
          final userName = userData?['name'] ?? firebaseName ?? 'Student';

          return Stack(
            children: [
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: CurvedHeader(
                  height: 340,
                  child: SizedBox.shrink(),
                ),
              ),
              SafeArea(
                bottom: false,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hello, $userName',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Find your next great opportunity',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () => context.push('/notifications'),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExploreScreen())),
                          child: Container(
                            height: 52,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark 
                                  ? AppColors.darkSurface 
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(50),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                )
                              ]
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.search_rounded, color: AppColors.secondary),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Search opportunities...',
                                    style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.tune_rounded, size: 18, color: AppColors.primary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    


                    // Categories
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(top: 32),
                        child: _CategoryRow(),
                      ),
                    ),

                    // Recent Listings
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                        child: Text('Recent opportunities', style: Theme.of(context).textTheme.titleLarge),
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
                            postedAt: (data['postedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                            deadline: (data['deadline'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 30)),
                          );
                        }).toList();

                        return SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, i) => OpportunityCard(
                                opportunity: opps[i],
                                compact: true,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => OpportunityDetailScreen(opportunity: opps[i]),
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
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}



class _CategoryRow extends StatelessWidget {
  const _CategoryRow();

  @override
  Widget build(BuildContext context) {
    final categories = [
      {'icon': Icons.design_services_rounded, 'label': 'Design', 'color': const Color(0xFFFF4B63)},
      {'icon': Icons.code_rounded, 'label': 'Engineering', 'color': const Color(0xFF6C5CE7)},
      {'icon': Icons.campaign_rounded, 'label': 'Marketing', 'color': const Color(0xFFFFB627)},
      {'icon': Icons.bar_chart_rounded, 'label': 'Data', 'color': const Color(0xFF22D3A5)},
      {'icon': Icons.more_horiz_rounded, 'label': 'Other', 'color': const Color(0xFF5B8DEF)},
    ];

    return SizedBox(
      height: 90,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 20),
        itemBuilder: (context, i) {
          final cat = categories[i];
          final color = cat['color'] as Color;
          return Column(
            children: [
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExploreScreen())),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(cat['icon'] as IconData, color: color, size: 24),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                cat['label'] as String,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          );
        },
      ),
    ).animate().fadeIn(delay: 100.ms).slideX(begin: 0.1, end: 0);
  }
}
