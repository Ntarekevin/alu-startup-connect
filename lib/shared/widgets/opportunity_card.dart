import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import 'tag_chip.dart';

class OpportunityCard extends StatelessWidget {
  final OpportunityModel opportunity;
  final VoidCallback? onTap;
  final VoidCallback? onSave;
  final bool compact;

  const OpportunityCard({
    super.key,
    required this.opportunity,
    this.onTap,
    this.onSave,
    this.compact = false,
  });

  Color _typeColor(String type) {
    switch (type) {
      case 'Internship':
        return const Color(0xFF6C5CE7);
      case 'Full-time':
        return const Color(0xFF22D3A5);
      case 'Part-time':
        return const Color(0xFFFFB627);
      case 'Contract':
        return const Color(0xFFFF4B63);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final daysLeft = opportunity.deadline.difference(DateTime.now()).inDays;
    final typeColor = _typeColor(opportunity.type);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: opportunity.isFeatured
                ? AppColors.primary.withOpacity(0.5)
                : (isDark ? Colors.white12 : Colors.black12),
          ),
          boxShadow: [
            BoxShadow(
              color: opportunity.isFeatured 
                  ? AppColors.primary.withOpacity(0.15) 
                  : Colors.black.withOpacity(0.02),
              blurRadius: 20,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Company logo
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: opportunity.companyLogo.isNotEmpty
                        ? Image.network(
                            opportunity.companyLogo,
                            fit: BoxFit.cover,
                          )
                        : Center(
                            child: Text(
                              opportunity.companyName[0],
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
                          opportunity.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          opportunity.companyName,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Save button
                  if (onSave != null)
                    GestureDetector(
                      onTap: onSave,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: opportunity.isSaved
                              ? AppColors.primary.withOpacity(0.1)
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          opportunity.isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                          size: 20,
                          color: opportunity.isSaved ? AppColors.primary : Colors.grey,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Tags row
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  TagChip(label: opportunity.type, color: typeColor),
                  TagChip(
                    label: opportunity.isRemote ? 'Remote' : opportunity.location,
                    color: AppColors.secondary,
                  ),
                ],
              ),

              const SizedBox(height: 16),
              Divider(color: isDark ? Colors.white12 : Colors.black12),
              const SizedBox(height: 12),

              // Footer
              Row(
                children: [
                  Icon(Icons.people_outline_rounded, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    '${opportunity.applicantCount} applied',
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.schedule_rounded,
                    size: 16,
                    color: daysLeft <= 7 ? AppColors.error : Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    daysLeft <= 0
                        ? 'Closed'
                        : daysLeft == 1
                            ? '1 day left'
                            : '$daysLeft days left',
                    style: TextStyle(
                      fontSize: 12,
                      color: daysLeft <= 7 ? AppColors.error : (isDark ? Colors.white70 : Colors.black87),
                      fontWeight: daysLeft <= 7 ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.05, end: 0);
  }
}
