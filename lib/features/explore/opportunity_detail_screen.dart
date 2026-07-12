import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/custom_button.dart';

class OpportunityDetailScreen extends StatefulWidget {
  final OpportunityModel opportunity;

  const OpportunityDetailScreen({super.key, required this.opportunity});

  @override
  State<OpportunityDetailScreen> createState() => _OpportunityDetailScreenState();
}

class _OpportunityDetailScreenState extends State<OpportunityDetailScreen> {
  bool _isSaved = false;
  bool _applied = false;

  @override
  void initState() {
    super.initState();
    _isSaved = widget.opportunity.isSaved;
  }

  void _apply() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ApplySheet(
        opportunity: widget.opportunity,
        onApply: () {
          Navigator.pop(context);
          setState(() => _applied = true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Application submitted! 🎉'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final opp = widget.opportunity;
    final daysLeft = opp.deadline.difference(DateTime.now()).inDays;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Header ────────────────────────────────────────────────────────
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
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.background.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isSaved ? Icons.bookmark : Icons.bookmark_border,
                    size: 20,
                    color: _isSaved ? AppColors.teal : AppColors.textPrimary,
                  ),
                ),
                onPressed: () => setState(() => _isSaved = !_isSaved),
              ),
            ],
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
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: AppColors.surfaceLight,
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.network(
                            opp.companyLogo,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                              child: Text(
                                opp.companyName[0],
                                style: const TextStyle(
                                  color: AppColors.teal,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 24,
                                ),
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
                                opp.companyName,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                opp.title,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
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

          // ── Content ───────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick info
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoChip(icon: Icons.work_outline, label: opp.type, color: AppColors.teal),
                      _InfoChip(
                        icon: opp.isRemote ? Icons.wifi : Icons.location_on_outlined,
                        label: opp.isRemote ? 'Remote' : opp.location,
                        color: AppColors.info,
                      ),
                      _InfoChip(icon: Icons.schedule, label: opp.duration, color: AppColors.textSecondary),
                      if (opp.stipend != null)
                        _InfoChip(icon: Icons.attach_money, label: opp.stipend!, color: AppColors.gold),
                    ],
                  ).animate().fadeIn(duration: 300.ms),

                  const SizedBox(height: 20),

                  // Deadline & applicants
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: daysLeft <= 7 ? AppColors.error.withOpacity(0.3) : AppColors.cardBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Icon(Icons.timer_outlined,
                                  color: daysLeft <= 7 ? AppColors.error : AppColors.textMuted,
                                  size: 22),
                              const SizedBox(height: 4),
                              Text(
                                '$daysLeft days left',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: daysLeft <= 7 ? AppColors.error : AppColors.textPrimary,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Deadline: ${DateFormat('MMM d, yyyy').format(opp.deadline)}',
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 48, color: AppColors.cardBorder),
                        Expanded(
                          child: Column(
                            children: [
                              const Icon(Icons.people_outline, color: AppColors.textMuted, size: 22),
                              const SizedBox(height: 4),
                              Text(
                                '${opp.applicantCount}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                ),
                              ),
                              const Text(
                                'Applicants so far',
                                style: TextStyle(color: AppColors.textMuted, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 48, color: AppColors.cardBorder),
                        Expanded(
                          child: Column(
                            children: [
                              const Icon(Icons.calendar_today, color: AppColors.textMuted, size: 22),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('MMM d').format(opp.postedAt),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                ),
                              ),
                              const Text(
                                'Posted',
                                style: TextStyle(color: AppColors.textMuted, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate(delay: 100.ms).fadeIn(duration: 300.ms),

                  const SizedBox(height: 24),

                  // Description
                  _Section(title: 'About the Role', content: opp.description),
                  const SizedBox(height: 20),

                  // Responsibilities
                  if (opp.responsibilities.isNotEmpty) ...[
                    _BulletSection(title: 'Responsibilities', items: opp.responsibilities),
                    const SizedBox(height: 20),
                  ],

                  // Requirements
                  if (opp.requirements.isNotEmpty) ...[
                    _BulletSection(title: 'Requirements', items: opp.requirements),
                    const SizedBox(height: 20),
                  ],

                  // Skills
                  if (opp.skills.isNotEmpty) ...[
                    Text('Skills', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: opp.skills.map((s) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.teal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.teal.withOpacity(0.3)),
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
                  ],

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.cardBorder)),
        ),
        child: _applied
            ? Container(
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.success.withOpacity(0.3)),
                ),
                child: const Center(
                  child: Text(
                    '✓ Applied Successfully',
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              )
            : GlowButton(label: 'Apply Now', onPressed: _apply, width: double.infinity),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String content;

  const _Section({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          content,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.7),
        ),
      ],
    );
  }
}

class _BulletSection extends StatelessWidget {
  final String title;
  final List<String> items;

  const _BulletSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.teal,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ApplySheet extends StatefulWidget {
  final OpportunityModel opportunity;
  final VoidCallback onApply;

  const _ApplySheet({required this.opportunity, required this.onApply});

  @override
  State<_ApplySheet> createState() => _ApplySheetState();
}

class _ApplySheetState extends State<_ApplySheet> {
  final _coverController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _coverController.dispose();
    super.dispose();
  }

  void _submitApplication() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    setState(() => _isLoading = true);
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final studentName = userDoc.data()?['name'] ?? 'Student';
      final studentEmail = userDoc.data()?['email'] ?? '';

      // Write application document
      await FirebaseFirestore.instance.collection('applications').add({
        'opportunityId': widget.opportunity.id,
        'opportunityTitle': widget.opportunity.title,
        'companyId': widget.opportunity.companyId,
        'companyName': widget.opportunity.companyName,
        'studentId': user.uid,
        'studentName': studentName,
        'studentEmail': studentEmail,
        'coverLetter': _coverController.text.trim(),
        'status': 'applied',   // matches ApplicationsScreen status filter
        'appliedAt': FieldValue.serverTimestamp(),
      });

      // Increment applicant counter on the opportunity (best-effort)
      FirebaseFirestore.instance
          .collection('opportunities')
          .doc(widget.opportunity.id)
          .update({'applicantCount': FieldValue.increment(1)})
          .catchError((_) {}); // silently ignore if opportunity was deleted
      
      if (mounted) widget.onApply();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
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
          Text(
            'Apply for ${widget.opportunity.title}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            widget.opportunity.companyName,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.teal),
          ),
          const SizedBox(height: 20),

          // CV
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.attach_file, color: AppColors.teal, size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Amara_Osei_CV.pdf',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  ),
                ),
                const Icon(Icons.check_circle, color: AppColors.success, size: 18),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Cover letter
          TextField(
            controller: _coverController,
            maxLines: 4,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'Add a cover letter (optional)...',
              alignLabelWithHint: true,
            ),
          ),

          const SizedBox(height: 20),

          GlowButton(
            label: _isLoading ? 'Submitting...' : 'Submit Application',
            onPressed: _isLoading ? () {} : _submitApplication,
            width: double.infinity,
          ),
        ],
      ),
    );
  }
}
