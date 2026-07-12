import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/custom_button.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;
  String _selectedRole = 'student';
  File? _proofFile;
  String? _proofFileName;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      
      // Check user role/status in Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Admin: any @aluadmin.com email goes straight to admin dashboard
        if (user.email?.endsWith('@aluadmin.com') == true) {
          if (mounted) context.go('/admin');
          return;
        }

        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data();
          if (data?['role'] == 'startup' && data?['status'] == 'pending') {
            if (mounted) context.go('/pending');
            return;
          }
        }
      }
      
      if (mounted) context.go('/main');
    } on FirebaseAuthException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Authentication failed')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _signInWithEmail() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Admin: any @aluadmin.com email goes straight to admin dashboard
        if (user.email?.endsWith('@aluadmin.com') == true) {
          if (mounted) context.go('/admin');
          return;
        }

        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data();
          if (data?['role'] == 'startup' && data?['status'] == 'pending') {
            if (mounted) context.go('/pending');
            return;
          }
        }
      }

      if (mounted) context.go('/main');
    } on FirebaseAuthException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Authentication failed')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickProofFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png'],
    );
    if (result != null) {
      setState(() {
        _proofFile = File(result.files.single.path!);
        _proofFileName = result.files.single.name;
      });
    }
  }

  void _signUpWithEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();
    
    if (email.isEmpty || password.isEmpty || name.isEmpty) return;

    // Block admin-domain emails from self-registering
    if (email.endsWith('@aluadmin.com')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admin accounts are created by the ALU team, not through self-registration.')),
      );
      return;
    }
    
    if (_selectedRole == 'student' && !email.endsWith('@alustudent.com')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Students must use an @alustudent.com email address')));
      return;
    }
    
    if (_selectedRole == 'startup' && _proofFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload an ALU proof document')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      String? proofUrl;
      if (_selectedRole == 'startup' && _proofFile != null) {
        final ref = FirebaseStorage.instance.ref().child('startup_proofs/${userCred.user!.uid}_$_proofFileName');
        await ref.putFile(_proofFile!);
        proofUrl = await ref.getDownloadURL();
      }
      
      await FirebaseFirestore.instance.collection('users').doc(userCred.user!.uid).set({
        'name': name,
        'email': email,
        'role': _selectedRole,
        'status': _selectedRole == 'startup' ? 'pending' : 'active',
        if (proofUrl != null) 'proofUrl': proofUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      if (mounted) {
        if (_selectedRole == 'startup') {
          context.go('/pending');
        } else {
          context.go('/main');
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Signup failed')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 32),

              // Logo + title
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: const LinearGradient(
                        colors: [AppColors.teal, Color(0xFF00A896)],
                      ),
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.teal.withOpacity(0.4),
                            blurRadius: 16),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'ALU',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.background,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Startup Connect',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms),

              const SizedBox(height: 32),

              // Tab bar
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.teal,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: AppColors.background,
                  unselectedLabelColor: AppColors.textMuted,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  tabs: const [
                    Tab(text: 'Sign In'),
                    Tab(text: 'Sign Up'),
                  ],
                ),
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 28),

              // Tab content
              SizedBox(
                height: 380,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSignIn(),
                    _buildSignUp(),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Divider
              Row(children: [
                const Expanded(child: Divider(color: AppColors.cardBorder)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('or', style: Theme.of(context).textTheme.bodySmall),
                ),
                const Expanded(child: Divider(color: AppColors.cardBorder)),
              ]),

              const SizedBox(height: 16),

              // Google sign-in button
              GestureDetector(
                onTap: _isLoading ? null : _signInWithGoogle,
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: const Center(
                          child: Text('G', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.blue)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Continue with Google',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignIn() {
    return Column(
      children: [
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            labelText: 'Email',
            hintText: 'your@alustudent.com',
            prefixIcon: Icon(Icons.email_outlined, color: AppColors.textMuted, size: 20),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _passwordController,
          obscureText: _obscure,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            labelText: 'Password',
            hintText: '••••••••',
            prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textMuted, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppColors.textMuted,
                size: 20,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {},
            child: const Text('Forgot password?', style: TextStyle(color: AppColors.teal, fontSize: 13)),
          ),
        ),
        const SizedBox(height: 8),
        GlowButton(
          label: _isLoading ? 'Signing In...' : 'Sign In', 
          onPressed: _isLoading ? () {} : _signInWithEmail, 
          width: double.infinity
        ),
      ],
    );
  }

  Widget _buildSignUp() {
    return Column(
      children: [
        TextField(
          controller: _nameController,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            labelText: 'Full Name',
            hintText: 'Amara Osei',
            prefixIcon: Icon(Icons.person_outline, color: AppColors.textMuted, size: 20),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            labelText: 'Email',
            hintText: 'your@alustudent.com',
            prefixIcon: Icon(Icons.email_outlined, color: AppColors.textMuted, size: 20),
          ),
        ),
        const SizedBox(height: 12),
        // Role selector
        Row(
          children: [
            Expanded(
              child: _RoleButton(
                label: 'Student',
                icon: Icons.school_outlined,
                isSelected: _selectedRole == 'student',
                onTap: () => setState(() => _selectedRole = 'student'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _RoleButton(
                label: 'Startup',
                icon: Icons.business_outlined,
                isSelected: _selectedRole == 'startup',
                onTap: () => setState(() {
                  _selectedRole = 'startup';
                  // Clear proof if switching role
                }),
              ),
            ),
          ],
        ),
        if (_selectedRole == 'startup') ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder, style: BorderStyle.dash),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _proofFileName ?? 'Upload ALU Connection Proof (PDF/Img)',
                    style: TextStyle(
                      color: _proofFileName != null ? AppColors.textPrimary : AppColors.textMuted,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton.icon(
                  onPressed: _pickProofFile,
                  icon: const Icon(Icons.upload_file, size: 18, color: AppColors.teal),
                  label: const Text('Browse', style: TextStyle(color: AppColors.teal)),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        GlowButton(
          label: _isLoading ? 'Creating...' : 'Create Account',
          onPressed: _isLoading ? () {} : _signUpWithEmail,
          width: double.infinity,
        ),
      ],
    );
  }
}

class _RoleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.teal.withOpacity(0.12) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.teal : AppColors.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? AppColors.teal : AppColors.textMuted, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.teal : AppColors.textMuted,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
