import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  bool _isUploading = false;
  bool _isPickingFile = false;

  Future<void> _pickAndUploadAvatar(String uid) async {
    if (_isPickingFile || _isUploading) return;
    setState(() => _isPickingFile = true);
    
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
      );
      
      if (result != null && result.files.isNotEmpty) {
        final path = result.files.single.path;
        final name = result.files.single.name;
        if (path != null) {
          setState(() {
            _isUploading = true;
            _isPickingFile = false;
          });

          // Upload to Firebase Storage
          final file = File(path);
          final ref = FirebaseStorage.instance
              .ref()
              .child('avatars/${uid}_${DateTime.now().millisecondsSinceEpoch}_$name');
          
          await ref.putFile(file);
          final downloadUrl = await ref.getDownloadURL();

          // Update Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .update({'avatarUrl': downloadUrl});

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile picture updated successfully! 🎉')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading picture: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _isPickingFile = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, userSnap) {
          if (userSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
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
          final avatarUrl = data?['avatarUrl'] as String?;

          return CustomScrollView(
            slivers: [
              // ── Header ──────────────────────────────────────────────────────
              SliverAppBar(
                backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
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
                            colors: [Color(0xFF6C5CE7), Color(0xFF8E7DF9)],
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
                            color: Colors.white.withOpacity(0.1),
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
                            GestureDetector(
                              onTap: _isUploading || uid == null ? null : () => _pickAndUploadAvatar(uid),
                              child: Stack(
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                      border: Border.all(color: AppColors.primary, width: 3),
                                      image: avatarUrl != null && avatarUrl.isNotEmpty
                                          ? DecorationImage(
                                              image: NetworkImage(avatarUrl),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withOpacity(0.4),
                                          blurRadius: 20,
                                        ),
                                      ],
                                    ),
                                    child: avatarUrl != null && avatarUrl.isNotEmpty
                                        ? null
                                        : Center(
                                            child: Text(
                                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                                              style: const TextStyle(
                                                fontSize: 32,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ),
                                  ),
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                    ),
                                  ),
                                  if (_isUploading)
                                    Positioned.fill(
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.black45,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
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
                                      color: Colors.white,
                                    ),
                                  ),
                                  if (major != null || university != null)
                                    Text(
                                      [major, university].where((e) => e != null).join(' · '),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                  if (graduationYear != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.school_outlined, size: 12, color: Colors.white),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Class of $graduationYear',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.white,
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
                          final interviews = docs.where((d) => (d.data() as Map<String, dynamic>)['status'] == 'interview').length;
                          final offers = docs.where((d) => (d.data() as Map<String, dynamic>)['status'] == 'offer').length;
                          return Row(
                            children: [
                              _ProfileStat(value: '$total', label: 'Applications'),
                              const SizedBox(width: 12),
                              _ProfileStat(value: '$interviews', label: 'Interviews'),
                              const SizedBox(width: 12),
                              _ProfileStat(value: '$offers', label: 'Offers'),
                            ],
                          ).animate().fadeIn(delay: 100.ms, duration: 300.ms);
                        },
                      ),

                      const SizedBox(height: 24),

                      // Email
                      _ProfileSection(
                        title: 'Email',
                        child: Row(
                          children: [
                            const Icon(Icons.email_outlined, size: 16, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(email, style: Theme.of(context).textTheme.bodyMedium),
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
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.7),
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
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                                ),
                                child: Text(
                                  s,
                                  style: const TextStyle(
                                    color: AppColors.primary,
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
                                  color: AppColors.primary,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            Text(value, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 13)),
          ],
        ),
      ],
    );
  }
}
