import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/models.dart';
import '../messages/messages_screen.dart';

class StartupApplicantsScreen extends StatelessWidget {
  const StartupApplicantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('Applicants'),
        backgroundColor: AppColors.darkSurface,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('applications')
            .where('companyId', isEqualTo: uid)
            .orderBy('appliedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No applicants yet',
                style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 16),
              ),
            );
          }

          final docs = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final docId = docs[index].id;
              final studentId = data['studentId'];
              final status = data['status'] ?? 'pending';
              final appliedAt = (data['appliedAt'] as Timestamp?)?.toDate() ?? DateTime.now();

              return Card(
                color: AppColors.darkSurface,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              data['studentName'] ?? 'Unknown Student',
                              style: const TextStyle(
                                  color: AppColors.darkTextPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          _StatusChip(status: status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data['studentEmail'] ?? '',
                        style: const TextStyle(color: AppColors.darkTextSecondary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Role: ${data['opportunityTitle']}',
                        style: const TextStyle(color: AppColors.darkTextSecondary, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Applied: ${DateFormat.yMMMd().format(appliedAt)}',
                        style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12),
                      ),
                      if (data['coverLetter'] != null && data['coverLetter'].isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text('Cover Letter:', style: TextStyle(color: AppColors.darkTextPrimary, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          data['coverLetter'],
                          style: const TextStyle(color: AppColors.darkTextSecondary),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          if (status == 'pending') ...[
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                                onPressed: () => _updateStatus(docId, 'accepted'),
                                child: const Text('Accept', style: TextStyle(color: Colors.white)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
                                onPressed: () => _updateStatus(docId, 'rejected'),
                                child: const Text('Reject'),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.surfaceLight,
                                foregroundColor: AppColors.secondary,
                              ),
                              icon: const Icon(Icons.message, size: 18),
                              label: const Text('Message'),
                              onPressed: () => _startConversation(
                                context,
                                studentId: studentId,
                                studentName: data['studentName'] ?? 'Student',
                                startupId: uid!,
                                startupName: data['companyName'] ?? 'Startup',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _updateStatus(String docId, String status) async {
    await FirebaseFirestore.instance.collection('applications').doc(docId).update({
      'status': status,
    });
  }

  void _startConversation(
    BuildContext context, {
    required String studentId,
    required String studentName,
    required String startupId,
    required String startupName,
  }) async {
    final convoId = '${startupId}_$studentId';
    
    final convoRef = FirebaseFirestore.instance.collection('conversations').doc(convoId);
    final doc = await convoRef.get();
    
    if (!doc.exists) {
      await convoRef.set({
        'participants': [startupId, studentId],
        'names': {
          startupId: startupName,
          studentId: studentName,
        },
        'avatars': {
          startupId: '',
          studentId: '',
        },
        'roles': {
          startupId: 'Startup',
          studentId: 'Student',
        },
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCounts': {
          startupId: 0,
          studentId: 0,
        },
      });
    }

    final convoModel = ConversationModel(
      id: convoId,
      participantName: studentName,
      participantAvatar: '',
      participantRole: 'Student',
      lastMessage: '',
      lastMessageTime: DateTime.now(),
    );

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatScreen(conversation: convoModel)),
      );
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'accepted':
        color = AppColors.success;
        break;
      case 'rejected':
        color = AppColors.error;
        break;
      default:
        color = AppColors.gold;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
