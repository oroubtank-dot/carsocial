import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ResponsiveServiceIcons extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterSelected;
  final Function(String) showFilterMessage;

  const ResponsiveServiceIcons({
    super.key,
    required this.selectedFilter,
    required this.onFilterSelected,
    required this.showFilterMessage,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth > 900) {
      return _buildVerticalIcons(context);
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildVerticalIcons(BuildContext context) {
    return Container(
      width: 120,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkSurface
            : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          bottomLeft: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: _getAllServices().length,
        itemBuilder: (context, index) {
          final service = _getAllServices()[index];
          final isSelected = selectedFilter == service['filterKey'];

          return _buildVerticalIconItem(
            context: context,
            icon: service['icon'],
            label: service['label'],
            color: service['color'],
            isSelected: isSelected,
            filterKey: service['filterKey'],
          );
        },
      ),
    );
  }

  Widget _buildVerticalIconItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required bool isSelected,
    required String filterKey,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          onFilterSelected(filterKey);
          showFilterMessage(label);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color:
                isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, size: 24, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? color : null,
                  ),
                ),
              ),
              if (isSelected) Icon(Icons.check_circle, size: 16, color: color),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getAllServices() {
    return [
      {
        'icon': Icons.home,
        'label': 'الكل',
        'filterKey': 'all',
        'color': AppColors.primary
      },
      {
        'icon': Icons.directions_car,
        'label': 'سيارات',
        'filterKey': 'cars',
        'color': Colors.blue
      },
      {
        'icon': Icons.build,
        'label': 'ورش صيانة',
        'filterKey': 'workshops',
        'color': Colors.orange
      },
      {
        'icon': Icons.movie,
        'label': 'أفلام حماية',
        'filterKey': 'films',
        'color': Colors.purple
      },
      {
        'icon': Icons.brush,
        'label': 'سمكرة ودهان',
        'filterKey': 'painting',
        'color': Colors.red
      },
      {
        'icon': Icons.electrical_services,
        'label': 'كهرباء',
        'filterKey': 'electric',
        'color': Colors.amber
      },
      {
        'icon': Icons.tire_repair,
        'label': 'إطارات',
        'filterKey': 'tires',
        'color': Colors.brown
      },
      {
        'icon': Icons.handyman,
        'label': 'قطع غيار',
        'filterKey': 'spare_parts',
        'color': Colors.teal
      },
      {
        'icon': Icons.brush,
        'label': 'اكسسوارات',
        'filterKey': 'accessories',
        'color': Colors.pink
      },
      {
        'icon': Icons.air,
        'label': 'عادم',
        'filterKey': 'exhaust',
        'color': Colors.grey
      },
      {
        'icon': Icons.settings,
        'label': 'تظبيط',
        'filterKey': 'tuning',
        'color': Colors.indigo
      },
      {
        'icon': Icons.ac_unit,
        'label': 'تكييف',
        'filterKey': 'ac',
        'color': Colors.cyan
      },
      {
        'icon': Icons.shield,
        'label': 'طلاء حماية',
        'filterKey': 'coating',
        'color': Colors.green
      },
      {
        'icon': Icons.description,
        'label': 'رخص',
        'filterKey': 'license',
        'color': Colors.deepPurple
      },
      {
        'icon': Icons.local_shipping,
        'label': 'نقل',
        'filterKey': 'transport',
        'color': Colors.blueGrey
      },
      {
        'icon': Icons.school,
        'label': 'تعليم قيادة',
        'filterKey': 'driving',
        'color': Colors.lime
      },
      {
        'icon': Icons.store,
        'label': 'معارض',
        'filterKey': 'dealership',
        'color': Colors.deepOrange
      },
      {
        'icon': Icons.money,
        'label': 'تمويل',
        'filterKey': 'finance',
        'color': Colors.green.shade700
      },
      {
        'icon': Icons.security,
        'label': 'تأمين',
        'filterKey': 'insurance',
        'color': Colors.blue.shade700
      },
    ];
  }
}
