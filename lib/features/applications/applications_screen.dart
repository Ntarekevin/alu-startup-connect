import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/tag_chip.dart';

class ApplicationsScreen extends StatefulWidget {
  const ApplicationsScreen({super.key});

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _statuses = ['All', 'Reviewing', 'Interview', 'Offer'];

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Applications',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black87,
                      letterSpacing: -0.5,
                    ),
                  ).animate().fadeIn().slideX(begin: -0.1, end: 0),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.more_horiz_rounded, color: isDark ? Colors.white : Colors.black87),
                  )
                ],
              ),
            ),

            // ── Segmented Control ───────────────────────────────────────────
            Container(
              height: 48,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.grey[200],
                borderRadius: BorderRadius.circular(50),
              ),
              child: TabBar(
                controller: _tabController,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.15) : Colors.white,
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: isDark ? [] : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: isDark ? Colors.white : Colors.black87,
                unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                tabs: _statuses.map((s) => Tab(text: s)).toList(),
              ),
            ).animate().fadeIn(delay: 50.ms),

            const SizedBox(height: 16),

            // ── Tab content ───────────────────────────────────────────────
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('applications')
                    .where('studentId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final docs = List<QueryDocumentSnapshot>.from(snapshot.data?.docs ?? []);
                  // Sort in-memory to avoid needing a Firestore composite index
                  docs.sort((a, b) {
                    final aTime = (a.data() as Map<String, dynamic>)['appliedAt'] as Timestamp?;
                    final bTime = (b.data() as Map<String, dynamic>)['appliedAt'] as Timestamp?;
                    if (aTime == null && bTime == null) return 0;
                    if (aTime == null) return 1;
                    if (bTime == null) return -1;
                    return bTime.compareTo(aTime);
                  });

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
                      timeline: [], // not used in new design directly, but kept for model consistency
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
                                  (status == 'Reviewing' && (a.status == 'applied' || a.status == 'pending' || a.status == 'reviewing')) ||
                                  (status == 'Offer' && (a.status == 'offer' || a.status == 'accepted')))
                              .toList();

                      return apps.isEmpty
                          ? _EmptyTab(status: status)
                          : ListView.separated(
                              padding: const EdgeInsets.all(24),
                              itemCount: apps.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 16),
                              itemBuilder: (_, i) => _ExpandableApplicationCard(application: apps[i]),
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

class _ExpandableApplicationCard extends StatefulWidget {
  final ApplicationModel application;

  const _ExpandableApplicationCard({required this.application});

  @override
  State<_ExpandableApplicationCard> createState() => _ExpandableApplicationCardState();
}

class _ExpandableApplicationCardState extends State<_ExpandableApplicationCard> {
  bool _expanded = false;

  Color _statusColor(String status) {
    switch (status) {
      case 'applied': 
      case 'pending':
      case 'reviewing': return const Color(0xFF5B8DEF); // Blue
      case 'interview': return const Color(0xFF6C5CE7); // Purple
      case 'offer':
      case 'accepted': return const Color(0xFF22D3A5); // Green
      case 'rejected': return const Color(0xFFFF4B63); // Red
      default: return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'applied': 
      case 'pending':
      case 'reviewing': return 'Under Review';
      case 'interview': return 'Interviewing';
      case 'offer': return 'Offer Received';
      case 'accepted': return 'Accepted';
      case 'rejected': return 'Not Selected';
      default: return 'Under Review';
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'applied': 
      case 'pending':
      case 'reviewing': return Icons.remove_red_eye_rounded;
      case 'interview': return Icons.videocam_rounded;
      case 'offer': return Icons.star_rounded;
      case 'accepted': return Icons.check_circle_rounded;
      case 'rejected': return Icons.close_rounded;
      default: return Icons.remove_red_eye_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.application;
    final color = _statusColor(app.status);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: app.companyLogo.isNotEmpty
                          ? Image.network(app.companyLogo, fit: BoxFit.cover)
                          : Center(
                              child: Text(
                                app.companyName[0],
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            app.opportunityTitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            app.companyName,
                            style: TextStyle(
                              color: isDark ? Colors.white60 : Colors.black54,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TagChip(
                      label: _statusLabel(app.status),
                      color: color,
                      icon: _statusIcon(app.status),
                    ),
                    Text(
                      DateFormat('MMM d').format(app.appliedAt),
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black45,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                // Expanded Section
                if (_expanded) ...[
                  const SizedBox(height: 20),
                  Divider(color: isDark ? Colors.white12 : Colors.black12),
                  const SizedBox(height: 16),
                  
                  if (app.status == 'interview') ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.videocam_rounded, color: color, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Interview Scheduled',
                                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Tomorrow, 2:00 PM (EAT)',
                                  style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (app.status == 'offer') ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.star_rounded, color: color, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Offer Received!',
                                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Check your email for the offer letter.',
                                  style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Default generic next step message
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded, color: isDark ? Colors.white54 : Colors.black54, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Your application is being reviewed. The team will reach out if your profile is a match.',
                            style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 13, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ]
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.1, end: 0);
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
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.folder_open_rounded, size: 36, color: AppColors.primary),
          ),
          const SizedBox(height: 24),
          Text(
            'No ${status == 'All' ? '' : status.toLowerCase()} applications',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Explore opportunities and start applying!',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}