import 'package:quickboom_app/core/icons/remix_icon.dart';
import 'package:flutter/material.dart';
import 'package:quickboom_app/core/theme/app_typography.dart';
import 'package:quickboom_app/core/theme/app_colors.dart';

class BusinessCategoryItem {
  final String label;
  final IconData icon;

  const BusinessCategoryItem(this.label, this.icon);
}

const List<BusinessCategoryItem> kDefaultBusinessCategories = [
  BusinessCategoryItem('Gym', LegacyRemixIcons.fitnessCenterRounded),
  BusinessCategoryItem('Restaurant', LegacyRemixIcons.restaurantRounded),
  BusinessCategoryItem('Hotel', LegacyRemixIcons.hotelRounded),
  BusinessCategoryItem('Salon', LegacyRemixIcons.contentCutRounded),
  BusinessCategoryItem('Hospital', LegacyRemixIcons.localHospitalRounded),
  BusinessCategoryItem('Clinic', LegacyRemixIcons.medicalServicesRounded),
  BusinessCategoryItem('Real Estate', LegacyRemixIcons.homeWorkRounded),
  BusinessCategoryItem('School', LegacyRemixIcons.schoolRounded),
  BusinessCategoryItem('College', LegacyRemixIcons.accountBalanceRounded),
  BusinessCategoryItem('Retail Store', LegacyRemixIcons.storefrontRounded),
  BusinessCategoryItem('Travel Agency', LegacyRemixIcons.flightTakeoffRounded),
  BusinessCategoryItem(
    'Automobile Dealer',
    LegacyRemixIcons.directionsCarRounded,
  ),
  BusinessCategoryItem('Custom Business', LegacyRemixIcons.tuneRounded),
];

class BusinessTypeSelector extends StatefulWidget {
  final String selectedCategory;
  final ValueChanged<String> onSelected;

  const BusinessTypeSelector({
    super.key,
    required this.selectedCategory,
    required this.onSelected,
  });

  static Future<String?> showSearchableBottomSheet(
    BuildContext context, {
    required String currentSelection,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) =>
          _SearchableCategorySheet(currentSelection: currentSelection),
    );
  }

  @override
  State<BusinessTypeSelector> createState() => _BusinessTypeSelectorState();
}

class _BusinessTypeSelectorState extends State<BusinessTypeSelector> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final result = await BusinessTypeSelector.showSearchableBottomSheet(
          context,
          currentSelection: widget.selectedCategory,
        );
        if (result != null) {
          widget.onSelected(result);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                LegacyRemixIcons.businessCenterRounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Business Category',
                    style: AppTypography.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.selectedCategory.isNotEmpty
                        ? widget.selectedCategory
                        : 'Select business type...',
                    style: AppTypography.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              LegacyRemixIcons.searchRounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchableCategorySheet extends StatefulWidget {
  final String currentSelection;

  const _SearchableCategorySheet({required this.currentSelection});

  @override
  State<_SearchableCategorySheet> createState() =>
      _SearchableCategorySheetState();
}

class _SearchableCategorySheetState extends State<_SearchableCategorySheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<BusinessCategoryItem> _filtered = kDefaultBusinessCategories;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearch);
  }

  void _onSearch() {
    final query = _searchCtrl.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filtered = kDefaultBusinessCategories;
      } else {
        _filtered = kDefaultBusinessCategories
            .where((item) => item.label.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Select Business Type',
              style: AppTypography.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Choose the category of commercial prospects you want to extract.',
              style: AppTypography.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchCtrl,
              autofocus: false,
              decoration: InputDecoration(
                hintText: 'Search business category...',
                hintStyle: AppTypography.inter(
                  fontSize: 14,
                  color: AppColors.textPlaceholder,
                ),
                prefixIcon: const Icon(
                  LegacyRemixIcons.searchRounded,
                  color: AppColors.textSecondary,
                ),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _filtered.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: AppColors.border),
                itemBuilder: (ctx, idx) {
                  final item = _filtered[idx];
                  final isSelected = item.label == widget.currentSelection;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryLight
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        item.icon,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      item.label,
                      style: AppTypography.inter(
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w600,
                        color: isSelected
                            ? AppColors.primaryDark
                            : AppColors.textPrimary,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(
                            LegacyRemixIcons.checkCircleRounded,
                            color: AppColors.primary,
                          )
                        : const Icon(
                            LegacyRemixIcons.chevronRightRounded,
                            color: AppColors.border,
                          ),
                    onTap: () => Navigator.pop(context, item.label),
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
