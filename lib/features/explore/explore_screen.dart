import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/opportunity_card.dart';
import 'opportunity_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _selectedType = 'All';
  String _searchQuery = '';


  static const List<String> _categories = [
    'All', 'Engineering', 'Design', 'Business', 'Marketing',
    'Finance', 'Operations', 'Data Science', 'Product',
  ];
  static const List<String> _opportunityTypes = [
    'All', 'Internship', 'Full-time', 'Part-time', 'Contract', 'Freelance',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Explore', style: Theme.of(context).textTheme.displayMedium)
                      .animate()
                      .fadeIn(duration: 300.ms),
                  const SizedBox(height: 4),
                  Text(
                    'Find opportunities from African startups',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ).animate().fadeIn(delay: 100.ms),
                  const SizedBox(height: 16),

                  // Search bar
                  TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search roles, companies, skills...',
                      prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 18, color: AppColors.textMuted),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                    ),
                  ).animate().fadeIn(delay: 150.ms),

                  const SizedBox(height: 14),

                  // Category chips
                  SizedBox(
                    height: 34,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      itemBuilder: (_, i) {
                        final cat = _categories[i];
                        final isSelected = cat == _selectedCategory;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategory = cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.secondary
                                  : AppColors.darkSurface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? AppColors.secondary : AppColors.darkBorder,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                cat,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.darkTextSecondary,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Type chips
                  SizedBox(
                    height: 30,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _opportunityTypes.length,
                      itemBuilder: (_, i) {
                        final type = _opportunityTypes[i];
                        final isSelected = type == _selectedType;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedType = type),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.gold.withOpacity(0.15)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? AppColors.gold : AppColors.cardBorder,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                type,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                  color: isSelected ? AppColors.gold : AppColors.textMuted,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            const SizedBox(height: 8),

            // ── Results ───────────────────────────────────────────────────
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('opportunities').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.secondary));
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text('Failed to load opportunities'));
                  }
                  
                  final docs = snapshot.data?.docs ?? [];
                  final allOpportunities = docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return OpportunityModel(
                      id: doc.id,
                      companyId: data['companyId'] ?? '',
                      companyName: data['companyName'] ?? 'Startup',
                      companyLogo: '',
                      title: data['title'] ?? '',
                      type: data['type'] ?? '',
                      location: data['location'] ?? '',
                      isRemote: data['isRemote'] ?? false,
                      duration: data['duration'] ?? '',
                      description: data['description'] ?? '',
                      category: data['category'] ?? '',
                      postedAt: (data['postedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                      deadline: (data['deadline'] as Timestamp?)?.toDate() ?? DateTime.now(),
                    );
                  }).toList();

                  final results = allOpportunities.where((o) {
                    final matchesSearch = _searchQuery.isEmpty ||
                        o.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                        o.companyName.toLowerCase().contains(_searchQuery.toLowerCase());
                    final matchesCategory = _selectedCategory == 'All' || o.category == _selectedCategory;
                    final matchesType = _selectedType == 'All' || o.type == _selectedType;
                    return matchesSearch && matchesCategory && matchesType;
                  }).toList();

                  if (results.isEmpty) return _EmptyState();

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: results.length,
                    itemBuilder: (_, i) => OpportunityCard(
                      opportunity: results[i],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OpportunityDetailScreen(opportunity: results[i]),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔍', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}
