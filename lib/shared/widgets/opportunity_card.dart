import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';

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
        return AppColors.teal;
      case 'Full-time':
        return AppColors.gold;
      case 'Part-time':
        return AppColors.info;
      case 'Contract':
        return AppColors.statusInterview;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final daysLeft = opportunity.deadline.difference(DateTime.now()).inDays;
    final typeColor = _typeColor(opportunity.type);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: opportunity.isFeatured
                ? AppColors.teal.withOpacity(0.4)
                : AppColors.cardBorder,
          ),
          boxShadow: opportunity.isFeatured
              ? [
                  BoxShadow(
                    color: AppColors.teal.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Company logo
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: AppColors.surfaceLight,
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.network(
                      opportunity.companyLogo,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Text(
                          opportunity.companyName[0],
                          style: const TextStyle(
                            color: AppColors.teal,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          opportunity.companyName,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textMuted,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          opportunity.title,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Save button
                  GestureDetector(
                    onTap: onSave,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: opportunity.isSaved
                            ? AppColors.teal.withOpacity(0.15)
                            : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: opportunity.isSaved ? AppColors.teal : AppColors.cardBorder,
                        ),
                      ),
                      child: Icon(
                        opportunity.isSaved ? Icons.bookmark : Icons.bookmark_border,
                        size: 18,
                        color: opportunity.isSaved ? AppColors.teal : AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Tags row
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _Tag(label: opportunity.type, color: typeColor),
                  _Tag(
                    label: opportunity.isRemote ? '🌍 Remote' : '📍 ${opportunity.location}',
                    color: AppColors.textMuted,
                  ),
                  _Tag(label: '⏱ ${opportunity.duration}', color: AppColors.textMuted),
                  if (opportunity.stipend != null)
                    _Tag(label: '💰 ${opportunity.stipend}', color: AppColors.gold),
                ],
              ),

              if (!compact) ...[
                const SizedBox(height: 12),
                // Skills
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: opportunity.skills.take(3).map((s) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Text(
                        s,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 12),
              const Divider(color: AppColors.cardBorder, height: 1),
              const SizedBox(height: 10),

              // Footer
              Row(
                children: [
                  Icon(Icons.people_outline, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    '${opportunity.applicantCount} applicants',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  Icon(
                    Icons.schedule,
                    size: 14,
                    color: daysLeft <= 7 ? AppColors.error : AppColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    daysLeft <= 0
                        ? 'Closed'
                        : daysLeft == 1
                            ? '1 day left'
                            : '$daysLeft days left',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: daysLeft <= 7 ? AppColors.error : AppColors.textMuted,
                        ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    DateFormat('MMM d').format(opportunity.postedAt),
                    style: Theme.of(context).textTheme.bodySmall,
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

class _Tag extends StatelessWidget {
  final String label;
  final Color color;

  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color == AppColors.textMuted ? AppColors.textSecondary : color,
        ),
      ),
    );
  }
}
