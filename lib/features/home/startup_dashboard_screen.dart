import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/models.dart';
import '../../shared/widgets/opportunity_card.dart';
import '../explore/opportunity_detail_screen.dart';

class StartupDashboardScreen extends StatelessWidget {
  const StartupDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
          builder: (context, userSnap) {
            final userData = userSnap.data?.data() as Map<String, dynamic>?;
            final companyName = userData?['name'] ?? 'Your Startup';

            return CustomScrollView(
              slivers: [
                // ── Header ──────────────────────────────────────────────────
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
                          Text('Welcome back 👋',
                              style: Theme.of(context).textTheme.bodySmall),
                          Text(companyName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(color: AppColors.teal)),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.logout_outlined,
                            color: AppColors.textSecondary),
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          if (context.mounted) context.go('/auth');
                        },
                      ),
                    ],
                  ),
                ),

                // ── Stats Row ────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('opportunities')
                          .where('companyId', isEqualTo: uid)
                          .snapshots(),
                      builder: (context, oppSnap) {
                        final oppCount = oppSnap.data?.docs.length ?? 0;
                        return StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('applications')
                              .where('companyId', isEqualTo: uid)
                              .snapshots(),
                          builder: (context, appSnap) {
                            final appDocs = appSnap.data?.docs ?? [];
                            final totalApplicants = appDocs.length;
                            final pendingApplicants = appDocs
                                .where((d) =>
                                    (d.data() as Map<String, dynamic>)['status'] ==
                                    'pending')
                                .length;

                            return Row(
                              children: [
                                _StatCard(
                                    label: 'Opportunities',
                                    value: '$oppCount',
                                    icon: Icons.work_outline,
                                    color: AppColors.teal),
                                const SizedBox(width: 12),
                                _StatCard(
                                    label: 'Applicants',
                                    value: '$totalApplicants',
                                    icon: Icons.people_outline,
                                    color: AppColors.info),
                                const SizedBox(width: 12),
                                _StatCard(
                                    label: 'Pending',
                                    value: '$pendingApplicants',
                                    icon: Icons.pending_actions_outlined,
                                    color: AppColors.gold),
                              ],
                            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
                          },
                        );
                      },
                    ),
                  ),
                ),

                // ── Section Title ─────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                    child: Row(
                      children: [
                        Text('Your Opportunities',
                            style: Theme.of(context).textTheme.titleLarge),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => _showPostOpportunitySheet(context, uid, companyName),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.teal, Color(0xFF00A896)],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.teal.withOpacity(0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add, size: 16, color: AppColors.background),
                                SizedBox(width: 4),
                                Text(
                                  'Post',
                                  style: TextStyle(
                                    color: AppColors.background,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Opportunities Stream ───────────────────────────────────────
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('opportunities')
                      .where('companyId', isEqualTo: uid)
                      .orderBy('postedAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(color: AppColors.teal),
                          ),
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return SliverToBoxAdapter(
                        child: Center(
                          child: Text('Error: ${snapshot.error}',
                              style: const TextStyle(color: AppColors.error)),
                        ),
                      );
                    }

                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(48),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🚀', style: TextStyle(fontSize: 52)),
                                const SizedBox(height: 16),
                                Text('No opportunities posted yet',
                                    style: Theme.of(context).textTheme.titleLarge),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap "Post" to share your first opening\nand start receiving applications.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(duration: 400.ms),
                      );
                    }

                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final data = docs[index].data() as Map<String, dynamic>;
                            final opp = OpportunityModel(
                              id: docs[index].id,
                              companyId: data['companyId'] ?? '',
                              companyName: data['companyName'] ?? companyName,
                              companyLogo: '',
                              title: data['title'] ?? 'Untitled',
                              type: data['type'] ?? 'Internship',
                              location: data['location'] ?? 'Remote',
                              isRemote: data['isRemote'] ?? true,
                              duration: data['duration'] ?? '3 months',
                              stipend: data['stipend'],
                              description: data['description'] ?? '',
                              category: data['category'] ?? 'Engineering',
                              postedAt: (data['postedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                              deadline: (data['deadline'] as Timestamp?)?.toDate() ??
                                  DateTime.now().add(const Duration(days: 30)),
                            );
                            return OpportunityCard(
                              opportunity: opp,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => OpportunityDetailScreen(opportunity: opp),
                                ),
                              ),
                            );
                          },
                          childCount: docs.length,
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
      ),
    );
  }

  void _showPostOpportunitySheet(
      BuildContext context, String? uid, String companyName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _PostOpportunityForm(uid: uid, companyName: companyName),
    );
  }
}

// ── Post Opportunity Form ─────────────────────────────────────────────────────

class _PostOpportunityForm extends StatefulWidget {
  final String? uid;
  final String companyName;

  const _PostOpportunityForm({required this.uid, required this.companyName});

  @override
  State<_PostOpportunityForm> createState() => _PostOpportunityFormState();
}

class _PostOpportunityFormState extends State<_PostOpportunityForm> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _durationController = TextEditingController();
  final _stipendController = TextEditingController();

  String _selectedType = 'Internship';
  String _selectedCategory = 'Engineering';
  bool _isRemote = true;
  bool _isLoading = false;

  final _types = ['Internship', 'Full-time', 'Part-time', 'Contract', 'Freelance'];
  final _categories = [
    'Engineering',
    'Design',
    'Business',
    'Marketing',
    'Finance',
    'Operations',
    'Data Science',
    'Product',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _durationController.dispose();
    _stipendController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and description are required.')),
      );
      return;
    }
    if (widget.uid == null) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('opportunities').add({
        'companyId': widget.uid,
        'companyName': widget.companyName,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'type': _selectedType,
        'location': _isRemote ? 'Remote' : (_locationController.text.trim().isEmpty ? 'Remote' : _locationController.text.trim()),
        'isRemote': _isRemote,
        'duration': _durationController.text.trim().isEmpty ? '3 months' : _durationController.text.trim(),
        'stipend': _stipendController.text.trim().isEmpty ? null : _stipendController.text.trim(),
        'category': _selectedCategory,
        'requirements': <String>[],
        'responsibilities': <String>[],
        'skills': <String>[],
        'postedAt': FieldValue.serverTimestamp(),
        'deadline': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
        'applicantCount': 0,
        'isFeatured': false,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Opportunity posted! 🚀'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text('Post Opportunity',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('Fill in the details to attract top ALU talent.',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),

            // Title
            TextField(
              controller: _titleController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Job Title *',
                hintText: 'e.g. Software Engineering Intern',
                prefixIcon: Icon(Icons.work_outline, color: AppColors.textMuted, size: 20),
              ),
            ),
            const SizedBox(height: 14),

            // Type Dropdown
            _DropdownField(
              label: 'Opportunity Type',
              value: _selectedType,
              items: _types,
              onChanged: (v) => setState(() => _selectedType = v!),
              icon: Icons.category_outlined,
            ),
            const SizedBox(height: 14),

            // Category Dropdown
            _DropdownField(
              label: 'Category',
              value: _selectedCategory,
              items: _categories,
              onChanged: (v) => setState(() => _selectedCategory = v!),
              icon: Icons.label_outline,
            ),
            const SizedBox(height: 14),

            // Remote toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.wifi, color: AppColors.textMuted, size: 20),
                  const SizedBox(width: 12),
                  Text('Remote Position',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.textPrimary)),
                  const Spacer(),
                  Switch(
                    value: _isRemote,
                    onChanged: (v) => setState(() => _isRemote = v),
                    activeColor: AppColors.teal,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Location (only if not remote)
            if (!_isRemote) ...[
              TextField(
                controller: _locationController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Location',
                  hintText: 'e.g. Kigali, Rwanda',
                  prefixIcon: Icon(Icons.location_on_outlined,
                      color: AppColors.textMuted, size: 20),
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Duration
            TextField(
              controller: _durationController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Duration',
                hintText: 'e.g. 3 months, 6 months, Permanent',
                prefixIcon:
                    Icon(Icons.schedule, color: AppColors.textMuted, size: 20),
              ),
            ),
            const SizedBox(height: 14),

            // Stipend
            TextField(
              controller: _stipendController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Stipend / Salary (optional)',
                hintText: 'e.g. \$500/month, Equity, Unpaid',
                prefixIcon:
                    Icon(Icons.attach_money, color: AppColors.textMuted, size: 20),
              ),
            ),
            const SizedBox(height: 14),

            // Description
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Description *',
                hintText: 'Describe the role, responsibilities, and what makes your startup exciting...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(AppColors.background)),
                      )
                    : const Text(
                        'Post Opportunity',
                        style: TextStyle(
                          color: AppColors.background,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final IconData icon;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                dropdownColor: AppColors.surface,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 14),
                hint: Text(label,
                    style: const TextStyle(color: AppColors.textMuted)),
                items: items
                    .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(t,
                            style: const TextStyle(
                                color: AppColors.textPrimary))))
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

// ── Stat Card ─────────────────────────────────────────────────────────────────

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
