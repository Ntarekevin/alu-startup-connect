import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/custom_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StartupPendingScreen extends StatefulWidget {
  const StartupPendingScreen({super.key});

  @override
  State<StartupPendingScreen> createState() => _StartupPendingScreenState();
}

class _StartupPendingScreenState extends State<StartupPendingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, snap) {
          final data = snap.data?.data() as Map<String, dynamic>?;
          final status = data?['status'] as String?;

          // Auto-redirect when approved
          if (status == 'active') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) context.go('/main');
            });
          }

          final isRejected = status == 'rejected';

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated icon
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 1.0 + (_pulseController.value * 0.08),
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: (isRejected ? AppColors.error : AppColors.primary)
                                .withOpacity(0.12),
                            border: Border.all(
                              color: (isRejected ? AppColors.error : AppColors.primary)
                                  .withOpacity(0.4),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            isRejected
                                ? Icons.cancel_outlined
                                : Icons.hourglass_empty_rounded,
                            size: 52,
                            color: isRejected ? AppColors.error : AppColors.primary,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  Text(
                    isRejected ? 'Application Rejected' : 'Verification Pending',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isRejected
                              ? AppColors.error
                              : (isDark ? Colors.white : Colors.black87),
                          letterSpacing: -0.5,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  Text(
                    isRejected
                        ? 'Unfortunately your startup registration was not approved. Please ensure your ALU connection proof is valid and contact support if you believe this is a mistake.'
                        : 'Your startup registration is under review by our admin team. This usually takes 1–2 business days.\n\nYou\'ll be automatically redirected once approved! ✨',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Live status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: (isRejected ? AppColors.error : AppColors.gold)
                          .withOpacity(0.12),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(
                        color: (isRejected ? AppColors.error : AppColors.gold)
                            .withOpacity(0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isRejected ? Icons.block : Icons.schedule_rounded,
                          size: 14,
                          color: isRejected ? AppColors.error : AppColors.gold,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isRejected ? 'Rejected' : 'Pending Review',
                          style: TextStyle(
                            color: isRejected ? AppColors.error : AppColors.gold,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  GlowButton(
                    label: 'Sign Out',
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) context.go('/auth');
                    },
                    width: double.infinity,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
