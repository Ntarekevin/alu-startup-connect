import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/custom_button.dart';

class StartupDashboardScreen extends StatefulWidget {
  const StartupDashboardScreen({super.key});

  @override
  State<StartupDashboardScreen> createState() => _StartupDashboardScreenState();
}

class _StartupDashboardScreenState extends State<StartupDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, userSnap) {
          if (userSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final udata = userSnap.data?.data() as Map<String, dynamic>?;
          final startupName = udata?['name'] ?? 'Startup';

          return CustomScrollView(
            slivers: [
              // ── AppBar ───────────────────────────────────────────────────
              SliverAppBar(
                backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                expandedHeight: 180,
                pinned: true,
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
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF6C5CE7), Color(0xFF8E7DF9)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'Hello, $startupName 👋',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Manage your roles and applicants',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Stats ────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('opportunities')
                        .where('companyId', isEqualTo: uid)
                        .snapshots(),
                    builder: (context, oppsSnap) {
                      final activeRoles = oppsSnap.data?.docs.length ?? 0;

                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('applications')
                            .where('companyId', isEqualTo: uid)
                            .snapshots(),
                        builder: (context, appsSnap) {
                          final totalApps = appsSnap.data?.docs.length ?? 0;
                          final pendingApps = (appsSnap.data?.docs ?? [])
                              .where((d) => (d.data() as Map<String, dynamic>)['status'] == 'applied' || (d.data() as Map<String, dynamic>)['status'] == 'pending')
                              .length;

                          return Row(
                            children: [
                              _StatCard(
                                label: 'Active Roles',
                                value: '$activeRoles',
                                icon: Icons.work_outline_rounded,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 12),
                              _StatCard(
                                label: 'Total Applicants',
                                value: '$totalApps',
                                icon: Icons.people_outline_rounded,
                                color: AppColors.secondary,
                              ),
                              const SizedBox(width: 12),
                              _StatCard(
                                label: 'Pending Review',
                                value: '$pendingApps',
                                icon: Icons.rate_review_outlined,
                                color: AppColors.gold,
                              ),
                            ],
                          ).animate().fadeIn(duration: 400.ms);
                        },
                      );
                    },
                  ),
                ),
              ),

              // ── Action Buttons ───────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const PostOpportunityScreen()),
                          ),
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF4B63), Color(0xFFE53E55)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.4),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_rounded, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Post Opportunity',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Section Header ───────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                  child: Text(
                    'Recent Applicants',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),

              // ── Applicants List ───────────────────────────────────────────
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('applications')
                    .where('companyId', isEqualTo: uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverToBoxAdapter(
                      child: Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
                    );
                  }
                  if (snapshot.hasError) {
                    return SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                        ),
                      ),
                    );
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

                  if (docs.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: Text(
                            'No applicants yet',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final data = docs[i].data() as Map<String, dynamic>;
                        return _ApplicantTile(
                          appId: docs[i].id,
                          data: data,
                        );
                      },
                      childCount: docs.length,
                    ),
                  );
                },
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          );
        },
      ),
    );
  }
}

class _ApplicantTile extends StatelessWidget {
  final String appId;
  final Map<String, dynamic> data;

  const _ApplicantTile({required this.appId, required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final studentName = data['studentName'] ?? 'Student';
    final roleTitle = data['opportunityTitle'] ?? 'Role';
    final status = data['status'] ?? 'applied';

    Color statusColor;
    switch (status) {
      case 'applied':
      case 'pending':
        statusColor = AppColors.info;
        break;
      case 'interview':
        statusColor = AppColors.secondary;
        break;
      case 'offer':
        statusColor = AppColors.success;
        break;
      case 'rejected':
        statusColor = AppColors.error;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                studentName[0],
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
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
                  studentName,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  roleTitle,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _StatusActionChip(
            status: status,
            color: statusColor,
            onTap: () => _showStatusActionSheet(context),
          ),
        ],
      ),
    );
  }

  void _showStatusActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Update Application Status',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              _buildOption(context, 'Reviewing / Under Review', 'pending', AppColors.info),
              _buildOption(context, 'Invite to Interview', 'interview', AppColors.secondary),
              _buildOption(context, 'Send Job Offer', 'offer', AppColors.success),
              _buildOption(context, 'Reject Application', 'rejected', AppColors.error),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOption(BuildContext context, String title, String val, Color color) {
    return ListTile(
      leading: Icon(Icons.circle, color: color, size: 16),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      onTap: () async {
        await FirebaseFirestore.instance.collection('applications').doc(appId).update({
          'status': val,
        });
        if (context.mounted) Navigator.pop(context);
      },
    );
  }
}

class _StatusActionChip extends StatelessWidget {
  final String status;
  final Color color;
  final VoidCallback onTap;

  const _StatusActionChip({
    required this.status,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              status.toUpperCase(),
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: color),
          ],
        ),
      ),
    );
  }
}

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
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
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(color: color, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

// ── Post Opportunity Screen ───────────────────────────────────────────────

class PostOpportunityScreen extends StatefulWidget {
  const PostOpportunityScreen({super.key});

  @override
  State<PostOpportunityScreen> createState() => _PostOpportunityScreenState();
}

class _PostOpportunityScreenState extends State<PostOpportunityScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locController = TextEditingController();
  final _durController = TextEditingController();
  final _stipendController = TextEditingController();
  
  String _selectedType = 'Internship';
  String _selectedCat = 'Design';
  bool _isRemote = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locController.dispose();
    _durController.dispose();
    _stipendController.dispose();
    super.dispose();
  }

  void _post() async {
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();
    final loc = _locController.text.trim();
    final dur = _durController.text.trim();
    
    if (title.isEmpty || desc.isEmpty || dur.isEmpty || (!_isRemote && loc.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill out all required fields')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final companyName = userDoc.data()?['name'] ?? 'Startup';

      await FirebaseFirestore.instance.collection('opportunities').add({
        'companyId': uid,
        'companyName': companyName,
        'title': title,
        'description': desc,
        'type': _selectedType,
        'category': _selectedCat,
        'isRemote': _isRemote,
        'location': _isRemote ? 'Remote' : loc,
        'duration': dur,
        'stipend': _stipendController.text.trim().isNotEmpty ? _stipendController.text.trim() : null,
        'postedAt': FieldValue.serverTimestamp(),
        'deadline': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
        'applicantCount': 0,
      });

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error posting opportunity: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : Colors.white;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Post Opportunity'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Opportunity Title *',
                hintText: 'e.g. Flutter Developer Intern',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Job Description *',
                hintText: 'Describe the role, responsibilities, and qualifications...',
              ),
            ),
            const SizedBox(height: 16),
            
            // Dropdowns
            _buildDropdown(
              label: 'Job Type',
              value: _selectedType,
              items: const ['Internship', 'Full-time', 'Part-time', 'Contract'],
              onChanged: (v) => setState(() => _selectedType = v!),
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              label: 'Category',
              value: _selectedCat,
              items: const ['Design', 'Engineering', 'Marketing', 'Data', 'Other'],
              onChanged: (v) => setState(() => _selectedCat = v!),
            ),
            const SizedBox(height: 16),

            // Remote toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.wifi, color: Colors.grey, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('This is a remote role', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  Switch(
                    value: _isRemote,
                    activeColor: AppColors.primary,
                    onChanged: (v) => setState(() => _isRemote = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (!_isRemote) ...[
              TextField(
                controller: _locController,
                decoration: const InputDecoration(
                  labelText: 'Location *',
                  hintText: 'e.g. Kigali, Rwanda',
                ),
              ),
              const SizedBox(height: 16),
            ],

            TextField(
              controller: _durController,
              decoration: const InputDecoration(
                labelText: 'Duration *',
                hintText: 'e.g. 3 months, 6 months',
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _stipendController,
              decoration: const InputDecoration(
                labelText: 'Stipend (Optional)',
                hintText: 'e.g. \$500/month, Unpaid',
              ),
            ),
            const SizedBox(height: 32),

            GlowButton(
              label: _isLoading ? 'Posting...' : 'Post Opportunity',
              onPressed: _isLoading ? () {} : _post,
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                dropdownColor: surfaceColor,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14),
                items: items
                    .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(t)))
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}