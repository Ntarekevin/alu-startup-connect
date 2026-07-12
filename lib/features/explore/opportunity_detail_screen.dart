import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/tag_chip.dart';
import 'package:file_picker/file_picker.dart';

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
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: CustomScrollView(
        slivers: [
          // ── Header ────────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: isDark ? AppColors.darkHeader : AppColors.lightHeader,
            elevation: 0,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : Colors.black87),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.ios_share_rounded,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                onPressed: () {},
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkHeader : AppColors.lightHeader,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 30,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 24,
                    right: 24,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              )
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: opp.companyLogo.isNotEmpty
                              ? Image.network(
                                  opp.companyLogo,
                                  fit: BoxFit.cover,
                                )
                              : Center(
                                  child: Text(
                                    opp.companyName[0],
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 32,
                                    ),
                                  ),
                                ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : Colors.white,
                            borderRadius: BorderRadius.circular(50),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ]
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                size: 18,
                                color: _isSaved ? AppColors.primary : (isDark ? Colors.white70 : Colors.black54),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _isSaved ? 'Saved' : 'Save',
                                style: TextStyle(
                                  color: _isSaved ? AppColors.primary : (isDark ? Colors.white70 : Colors.black54),
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            ],
                          )
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
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    opp.title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ).animate().fadeIn().slideY(begin: 0.1, end: 0),
                  const SizedBox(height: 8),
                  Text(
                    opp.companyName,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ).animate().fadeIn(delay: 50.ms).slideY(begin: 0.1, end: 0),
                  
                  const SizedBox(height: 24),
                  
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      TagChip(label: opp.category.isNotEmpty ? opp.category : 'General', color: const Color(0xFF6C5CE7)),
                      TagChip(label: opp.type, color: const Color(0xFFFF4B63)),
                      TagChip(label: opp.isRemote ? 'Remote' : 'On-site', color: const Color(0xFF22D3A5)),
                    ],
                  ).animate().fadeIn(delay: 100.ms),

                  const SizedBox(height: 32),

                  // Info Rows
                  _buildInfoRow(context, Icons.schedule_rounded, 'Duration', opp.duration),
                  const SizedBox(height: 16),
                  _buildInfoRow(context, Icons.location_on_rounded, 'Location', opp.location),
                  const SizedBox(height: 16),
                  _buildInfoRow(context, Icons.calendar_today_rounded, 'Posted', DateFormat('MMMM d, yyyy').format(opp.postedAt)),
                  if (opp.stipend != null) ...[
                    const SizedBox(height: 16),
                    _buildInfoRow(context, Icons.attach_money_rounded, 'Stipend', opp.stipend!),
                  ],

                  const SizedBox(height: 32),

                  // Description
                  _Section(title: 'About the Role', content: opp.description),
                  const SizedBox(height: 24),

                  // Responsibilities
                  if (opp.responsibilities.isNotEmpty) ...[
                    _BulletSection(title: 'Responsibilities', items: opp.responsibilities),
                    const SizedBox(height: 24),
                  ],

                  // Requirements
                  if (opp.requirements.isNotEmpty) ...[
                    _BulletSection(title: 'Requirements', items: opp.requirements),
                    const SizedBox(height: 24),
                  ],

                  // Skills
                  if (opp.skills.isNotEmpty) ...[
                    Text('Skills required', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: opp.skills.map((s) => TagChip(label: s, color: AppColors.secondary)).toList(),
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
        padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: 20,
              offset: const Offset(0, -10),
            )
          ],
        ),
        child: _applied
            ? Container(
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: AppColors.success.withOpacity(0.3)),
                ),
                child: const Center(
                  child: Text(
                    '✓ Application Submitted',
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              )
            : GlowButton(label: 'Apply Now', onPressed: _apply, width: double.infinity),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String title, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: isDark ? Colors.white70 : Colors.black54),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          ],
        )
      ],
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
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Text(
          content,
          style: TextStyle(
            height: 1.6,
            fontSize: 15,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
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
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8, right: 12),
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      height: 1.5,
                      fontSize: 15,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
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
  PlatformFile? _selectedCv;
  bool _isPickingFile = false;

  Future<void> _pickCvFile() async {
    if (_isPickingFile) return;
    setState(() => _isPickingFile = true);
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );
      if (result != null && mounted) {
        setState(() {
          _selectedCv = result.files.first;
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking file: $e')));
    } finally {
      if (mounted) setState(() => _isPickingFile = false);
    }
  }

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

      await FirebaseFirestore.instance.collection('applications').add({
        'opportunityId': widget.opportunity.id,
        'opportunityTitle': widget.opportunity.title,
        'companyId': widget.opportunity.companyId,
        'companyName': widget.opportunity.companyName,
        'studentId': user.uid,
        'studentName': studentName,
        'studentEmail': studentEmail,
        'coverLetter': _coverController.text.trim(),
        'status': 'applied',
        'appliedAt': FieldValue.serverTimestamp(),
      });

      FirebaseFirestore.instance
          .collection('opportunities')
          .doc(widget.opportunity.id)
          .update({'applicantCount': FieldValue.increment(1)})
          .catchError((_) {});
      
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Apply for ${widget.opportunity.title}',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5),
          ),
          const SizedBox(height: 6),
          Text(
            widget.opportunity.companyName,
            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 32),

          // CV
          _selectedCv != null
              ? Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.description_rounded, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedCv!.name,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${(_selectedCv!.size / 1024).round()} KB',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.error),
                        onPressed: () => setState(() => _selectedCv = null),
                      ),
                    ],
                  ),
                )
              : GestureDetector(
                  onTap: _pickCvFile,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white24 : Colors.black26,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.upload_file_rounded, color: AppColors.primary),
                        const SizedBox(width: 12),
                        const Text(
                          'Upload your CV (PDF, DOCX)',
                          style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ),

          const SizedBox(height: 24),

          // Cover letter
          TextField(
            controller: _coverController,
            maxLines: 4,
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Add a cover letter (optional)...',
              alignLabelWithHint: true,
              filled: true,
              fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.02),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),

          const SizedBox(height: 32),

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
