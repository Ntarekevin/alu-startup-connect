import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';

class ApplicationsScreen extends StatefulWidget {
  const ApplicationsScreen({super.key});

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _statuses = ['All', 'Applied', 'Reviewing', 'Interview', 'Offer', 'Rejected'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statuses.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('My Applications',
                      style: Theme.of(context).textTheme.displayMedium)
                      .animate()
                      .fadeIn(duration: 300.ms),
                  const SizedBox(height: 4),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('applications')
                        .where('studentId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                        .snapshots(),
                    builder: (context, s) {
                      final count = s.data?.docs.length ?? 0;
                      return Text(
                        '$count total application${count != 1 ? 's' : ''}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      );
                    },
                  ),
                ],
              ),
            ),

            // ── Tabs ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: AppColors.teal,
                  borderRadius: BorderRadius.circular(8),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                labelColor: AppColors.background,
                unselectedLabelColor: AppColors.textMuted,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                tabs: _statuses.map((s) {
                  return Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Text(s),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 12),

            // ── Tab content ───────────────────────────────────────────────
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('applications')
                    .where('studentId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                    .orderBy('appliedAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.teal));
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final docs = snapshot.data?.docs ?? [];
                  final allApps = docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return ApplicationModel(
                      id: doc.id,
                      opportunityId: data['opportunityId'] ?? '',
                      opportunityTitle: data['opportunityTitle'] ?? '',
                      companyName: data['companyName'] ?? '',
                      companyLogo: '',
                      status: data['status'] ?? 'applied',
                      appliedAt: (data['appliedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                      timeline: [
                        ApplicationEvent(
                          status: 'applied',
                          message: 'Application received',
                          timestamp: (data['appliedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                        ),
                        if (data['status'] != 'applied' && data['status'] != 'pending')
                          ApplicationEvent(
                            status: data['status'],
                            message: 'Status updated to ${data['status']}',
                            timestamp: DateTime.now(),
                          ),
                      ],
                    );
                  }).toList();

                  return TabBarView(
                    controller: _tabController,
                    children: _statuses.map((status) {
                      final apps = status == 'All'
                          ? allApps
                          : allApps
                              .where((a) =>
                                  a.status.toLowerCase() == status.toLowerCase() ||
                                  (status == 'Applied' && (a.status == 'applied' || a.status == 'pending')))
                              .toList();

                      return apps.isEmpty
                          ? _EmptyTab(status: status)
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: apps.length,
                              itemBuilder: (_, i) => _ApplicationCard(application: apps[i]),
                            );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}



class _ApplicationCard extends StatelessWidget {
  final ApplicationModel application;

  const _ApplicationCard({required this.application});

  Color _statusColor(String status) {
    switch (status) {
      case 'applied': return AppColors.statusApplied;
      case 'reviewing': return AppColors.statusReviewing;
      case 'interview': return AppColors.statusInterview;
      case 'offer': return AppColors.statusOffer;
      case 'rejected': return AppColors.statusRejected;
      default: return AppColors.textMuted;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'applied': return 'Applied';
      case 'reviewing': return 'Under Review';
      case 'interview': return 'Interview';
      case 'offer': return '🎉 Offer!';
      case 'rejected': return 'Not Selected';
      default: return status;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'applied': return Icons.send_outlined;
      case 'reviewing': return Icons.manage_search;
      case 'interview': return Icons.videocam_outlined;
      case 'offer': return Icons.star_rounded;
      case 'rejected': return Icons.close;
      default: return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(application.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: application.status == 'offer'
              ? AppColors.gold.withOpacity(0.4)
              : AppColors.cardBorder,
        ),
        boxShadow: application.status == 'offer'
            ? [BoxShadow(color: AppColors.gold.withOpacity(0.08), blurRadius: 16)]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.network(
                    application.companyLogo,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.surfaceLight,
                      child: Center(
                        child: Text(
                          application.companyName[0],
                          style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        application.companyName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                      ),
                      Text(
                        application.opportunityTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withOpacity(0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_statusIcon(application.status), size: 12, color: color),
                      const SizedBox(width: 4),
                      Text(
                        _statusLabel(application.status),
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Timeline
            _Timeline(events: application.timeline),

            const SizedBox(height: 10),
            const Divider(color: AppColors.cardBorder, height: 1),
            const SizedBox(height: 10),

            // Footer
            Text(
              'Applied ${DateFormat('MMM d, yyyy').format(application.appliedAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.05, end: 0);
  }
}

class _Timeline extends StatelessWidget {
  final List<ApplicationEvent> events;
  const _Timeline({required this.events});

  static const _allStatuses = ['applied', 'reviewing', 'interview', 'offer'];

  Color _color(String status) {
    switch (status) {
      case 'applied': return AppColors.statusApplied;
      case 'reviewing': return AppColors.statusReviewing;
      case 'interview': return AppColors.statusInterview;
      case 'offer': return AppColors.statusOffer;
      default: return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final completedStatuses = events.map((e) => e.status).toSet();
    return Row(
      children: _allStatuses.asMap().entries.map((entry) {
        final i = entry.key;
        final status = entry.value;
        final isCompleted = completedStatuses.contains(status);
        final color = isCompleted ? _color(status) : AppColors.surfaceLight;
        return Expanded(
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: isCompleted ? color : AppColors.surfaceLight,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCompleted ? color : AppColors.cardBorder,
                    width: 1.5,
                  ),
                ),
              ),
              if (i < _allStatuses.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    color: isCompleted ? color.withOpacity(0.4) : AppColors.surfaceLight,
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _EmptyTab extends StatelessWidget {
  final String status;
  const _EmptyTab({required this.status});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('📋', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            'No ${status == 'All' ? '' : status.toLowerCase()} applications',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Explore opportunities and start applying!',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}
