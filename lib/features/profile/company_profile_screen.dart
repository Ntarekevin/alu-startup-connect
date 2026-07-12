import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../explore/opportunity_detail_screen.dart';

class CompanyProfileScreen extends StatelessWidget {
  final String companyId;
  const CompanyProfileScreen({super.key, required this.companyId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(companyId).snapshots(),
        builder: (context, companySnap) {
          final cData = companySnap.data?.data() as Map<String, dynamic>?;
          final companyName = cData?['name'] ?? 'Startup';
          final companyEmail = cData?['email'] ?? '';

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('opportunities')
                .where('companyId', isEqualTo: companyId)
                .snapshots(),
            builder: (context, rolesSnap) {
              final openRoles = (rolesSnap.data?.docs ?? []).map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return OpportunityModel(
                  id: doc.id,
                  companyId: companyId,
                  companyName: companyName,
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
                  deadline: (data['deadline'] as Timestamp?)?.toDate() ??
                      DateTime.now().add(const Duration(days: 30)),
                );
              }).toList();

              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 200,
                    pinned: true,
                    backgroundColor: AppColors.surface,
                    leading: IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.background.withOpacity(0.7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back, size: 20),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF1A2550), AppColors.surface],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 16,
                            left: 20,
                            right: 20,
                            child: Row(
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: AppColors.teal.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppColors.cardBorder),
                                  ),
                                  child: Center(
                                    child: Text(
                                      companyName.isNotEmpty ? companyName[0] : '?',
                                      style: const TextStyle(
                                        color: AppColors.teal,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 28,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        companyName,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      if (companyEmail.isNotEmpty)
                                        Text(
                                          companyEmail,
                                          style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 12),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
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

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Open roles header
                          Row(
                            children: [
                              Text('Open Roles',
                                  style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.teal.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${openRoles.length}',
                                  style: const TextStyle(
                                    color: AppColors.teal,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ).animate().fadeIn(duration: 300.ms),
                          const SizedBox(height: 12),

                          if (openRoles.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: Text(
                                  'No open roles right now',
                                  style: TextStyle(color: AppColors.textMuted),
                                ),
                              ),
                            )
                          else
                            ...openRoles.map(
                              (opp) => GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        OpportunityDetailScreen(opportunity: opp),
                                  ),
                                ),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.cardBorder),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              opp.title,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(fontSize: 14),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${opp.type} · ${opp.isRemote ? 'Remote' : opp.location}',
                                              style: const TextStyle(
                                                  color: AppColors.textMuted,
                                                  fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (opp.stipend != null)
                                        Text(
                                          opp.stipend!,
                                          style: const TextStyle(
                                            color: AppColors.gold,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.chevron_right,
                                          color: AppColors.textMuted, size: 18),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
