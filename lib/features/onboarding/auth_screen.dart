import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
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
  bool _isGoogleLoading = false;
  String? _loadingMessage;
  String _selectedRole = 'student';
  File? _proofFile;
  String? _proofFileName;
  final _googleSignIn = GoogleSignIn();

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
    if (_isGoogleLoading) return;
    setState(() {
      _isGoogleLoading = true;
      _loadingMessage = 'Opening Google...';
    });
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isGoogleLoading = false);
        return;
      }
      setState(() => _loadingMessage = 'Authenticating...');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      setState(() => _loadingMessage = 'Signing in...');
      await FirebaseAuth.instance.signInWithCredential(credential);
      
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        if (user.email?.endsWith('@aluadmin.com') == true) {
          if (mounted) context.go('/admin');
          return;
        }

        setState(() => _loadingMessage = 'Loading profile...');
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sign-in failed. Please try again.')));
    } finally {
      if (mounted) setState(() {
        _isGoogleLoading = false;
        _loadingMessage = null;
      });
    }
  }

  void _signInWithEmail() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) return;
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Authenticating...';
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        if (user.email?.endsWith('@aluadmin.com') == true) {
          if (mounted) context.go('/admin');
          return;
        }

        setState(() => _loadingMessage = 'Loading profile...');
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
    } on FirebaseException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Database query failed')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('An unexpected error occurred: $e')));
    } finally {
      if (mounted) setState(() {
        _isLoading = false;
        _loadingMessage = null;
      });
    }
  }

  bool _isPickingFile = false;

  Future<void> _pickProofFile() async {
    if (_isPickingFile) return;
    _isPickingFile = true;
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'png'],
        withData: false,
        withReadStream: false,
      );
      if (result != null && result.files.isNotEmpty) {
        final path = result.files.single.path;
        if (path != null) {
          setState(() {
            _proofFile = File(path);
            _proofFileName = result.files.single.name;
          });
        }
      }
    } catch (e) {
      // Silently handle if picker is already active
    } finally {
      _isPickingFile = false;
    }
  }

  void _signUpWithEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();
    
    if (email.isEmpty || password.isEmpty || name.isEmpty) return;

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

    setState(() {
      _isLoading = true;
      _loadingMessage = 'Creating account...';
    });
    try {
      final userCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      String? proofFileName;
      String? proofType;
      String? proofLocalPath;
      if (_selectedRole == 'startup' && _proofFile != null) {
        final ext = (_proofFileName ?? '').split('.').last.toLowerCase();
        final isPdf = ext == 'pdf';
        proofType = isPdf ? 'application/pdf' : 'image/$ext';
        proofFileName = _proofFileName;
        proofLocalPath = 'proof_${userCred.user!.uid}.$ext';

        setState(() => _loadingMessage = 'Saving document locally...');
        final appDir = await getApplicationDocumentsDirectory();
        final localFile = File('${appDir.path}/$proofLocalPath');
        await _proofFile!.copy(localFile.path);
      }
      
      setState(() => _loadingMessage = 'Finalizing profile...');
      try {
        await FirebaseFirestore.instance.collection('users').doc(userCred.user!.uid).set({
          'name': name,
          'email': email,
          'role': _selectedRole,
          'status': _selectedRole == 'startup' ? 'pending' : 'active',
          if (proofLocalPath != null) 'proofLocalPath': proofLocalPath,
          if (proofFileName != null) 'proofFileName': proofFileName,
          if (proofType != null) 'proofType': proofType,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        // If Firestore write fails, clean up the Auth user so the email is not locked
        await userCred.user?.delete();
        rethrow;
      }
      
      if (mounted) {
        if (_selectedRole == 'startup') {
          context.go('/pending');
        } else {
          context.go('/main');
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Signup failed')));
    } on FirebaseException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Database write failed during signup')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('An unexpected error occurred: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingMessage = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, Color(0xFF8E7DF9)],
                      ),
                      boxShadow: [
                        BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 16),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'ALU',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
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
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms),

              const SizedBox(height: 32),

              // TabBar wrapper
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelColor: isDark ? Colors.white : Colors.black87,
                  unselectedLabelColor: Colors.grey,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Sign In'),
                    Tab(text: 'Sign Up'),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                height: 380,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSignInTab(isDark),
                    _buildSignUpTab(isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignInTab(bool isDark) {
    return Column(
      children: [
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(
            hintText: 'Email address',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          obscureText: _obscure,
          decoration: InputDecoration(
            hintText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (_isLoading)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    _loadingMessage ?? 'Processing...',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          GlowButton(
            label: 'Sign In',
            onPressed: _signInWithEmail,
            width: double.infinity,
          ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: Divider(color: isDark ? Colors.white24 : Colors.black12)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('OR', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ),
            Expanded(child: Divider(color: isDark ? Colors.white24 : Colors.black12)),
          ],
        ),
        const SizedBox(height: 20),
        OutlinedButton(
          onPressed: (_isLoading || _isGoogleLoading) ? null : _signInWithGoogle,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            side: BorderSide(
              color: _isGoogleLoading ? AppColors.primary : (isDark ? Colors.white24 : Colors.black26),
            ),
          ),
          child: _isGoogleLoading
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _loadingMessage ?? 'Connecting...',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                  ],
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.g_mobiledata, size: 28),
                    SizedBox(width: 8),
                    Text('Continue with Google'),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildSignUpTab(bool isDark) {
    return SingleChildScrollView(
      child: Column(
        children: [
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            hintText: 'Full Name / Startup Name',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(
            hintText: 'Email address',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          obscureText: _obscure,
          decoration: InputDecoration(
            hintText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
        const SizedBox(height: 16),
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
                onTap: () => setState(() => _selectedRole = 'startup'),
              ),
            ),
          ],
        ),
        if (_selectedRole == 'startup') ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _proofFileName ?? 'Upload ALU Connection Proof (PDF/Img)',
                    style: TextStyle(
                      color: _proofFileName != null 
                          ? (isDark ? Colors.white : Colors.black87) 
                          : Colors.grey,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton.icon(
                  onPressed: _pickProofFile,
                  icon: const Icon(Icons.upload_file, size: 18, color: AppColors.primary),
                  label: const Text('Browse', style: TextStyle(color: AppColors.primary)),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (_isLoading)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    _loadingMessage ?? 'Processing...',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          GlowButton(
            label: 'Create Account',
            onPressed: _signUpWithEmail,
            width: double.infinity,
          ),
      ],
      ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.primary.withOpacity(0.12) 
              : (isDark ? AppColors.darkSurface : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : (isDark ? Colors.white12 : Colors.black12),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon, 
              color: isSelected ? AppColors.primary : Colors.grey, 
              size: 24
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : Colors.grey,
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