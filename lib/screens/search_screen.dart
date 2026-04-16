import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/post_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all';
  String _selectedCondition = 'all';
  RangeValues _priceRange = const RangeValues(0, 1000000);
  String _selectedLocation = 'all';

  final List<String> _locations = [
    'all',
    'القاهرة',
    'الإسكندرية',
    'الجيزة',
    'القليوبية',
    'الشرقية',
    'الدقهلية',
    'البحيرة',
    'الغربية',
    'المنوفية',
    'أسوان',
    'أسيوط',
  ];

  String _getSearchTitle() {
    final query = _searchController.text;
    if (query.isEmpty) return 'جميع المنشورات';
    return 'نتائج البحث عن $query';
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text;
    final _ = query.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('بحث'), centerTitle: true),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ابحث عن سيارات، خدمات...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),

          // فلترة سريعة
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('الكل'),
                  selected: _selectedFilter == 'all',
                  onSelected: (_) => setState(() => _selectedFilter = 'all'),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('سيارات'),
                  selected: _selectedFilter == 'cars',
                  onSelected: (_) => setState(() => _selectedFilter = 'cars'),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('خدمات'),
                  selected: _selectedFilter == 'services',
                  onSelected: (_) =>
                      setState(() => _selectedFilter = 'services'),
                ),
              ],
            ),
          ),

          // فلترة متقدمة
          ExpansionTile(
            title: const Text('فلترة متقدمة'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // الحالة
                    Row(
                      children: [
                        const Text('الحالة: '),
                        const SizedBox(width: 16),
                        ChoiceChip(
                          label: const Text('الكل'),
                          selected: _selectedCondition == 'all',
                          onSelected: (_) =>
                              setState(() => _selectedCondition = 'all'),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('جديد'),
                          selected: _selectedCondition == 'new',
                          onSelected: (_) =>
                              setState(() => _selectedCondition = 'new'),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('مستعمل'),
                          selected: _selectedCondition == 'used',
                          onSelected: (_) =>
                              setState(() => _selectedCondition = 'used'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // السعر
                    Row(
                      children: [
                        const Text('السعر: '),
                        Expanded(
                          child: RangeSlider(
                            values: _priceRange,
                            min: 0,
                            max: 1000000,
                            divisions: 100,
                            labels: RangeLabels(
                              '${_priceRange.start.round()} ج.م',
                              '${_priceRange.end.round()} ج.م',
                            ),
                            onChanged: (values) =>
                                setState(() => _priceRange = values),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // الموقع
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'المحافظة'),
                      initialValue: _selectedLocation,
                      items: _locations.map((location) {
                        return DropdownMenuItem(
                          value: location,
                          child: Text(
                            location == 'all' ? 'كل المحافظات' : location,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => _selectedLocation = value!),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Divider(),

          // عنوان النتائج
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              _getSearchTitle(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),

          // النتائج
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _buildQuery().snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final posts = snapshot.data!.docs;

                if (posts.isEmpty) {
                  return const Center(child: Text('لا توجد نتائج'));
                }

                return ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    return PostCard(post: posts[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Query<Map<String, dynamic>> _buildQuery() {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection(
      'posts',
    );

    if (_searchController.text.isNotEmpty) {
      final searchText = _searchController.text;
      query = query
          .where('title', isGreaterThanOrEqualTo: searchText)
          .where('title', isLessThanOrEqualTo: '$searchText\uf8ff');
    }

    if (_selectedFilter != 'all') {
      query = query.where('service', isEqualTo: _selectedFilter);
    }

    if (_selectedCondition != 'all') {
      query = query.where('condition', isEqualTo: _selectedCondition);
    }

    if (_selectedLocation != 'all') {
      query = query.where('location', isEqualTo: _selectedLocation);
    }

    return query.orderBy('createdAt', descending: true);
  }
}
