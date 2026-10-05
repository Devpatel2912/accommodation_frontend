import 'package:flutter/material.dart';
import 'package:accommodation/core/utils/color.dart';
import 'package:hugeicons/hugeicons.dart';

class BottomBarItem {
  final dynamic icon;
  final String label;

  const BottomBarItem({required this.icon, required this.label});
}

class CustomBottomBar extends StatelessWidget {
  final int currentIndex;
  final List<BottomBarItem> items;
  final ValueChanged<int> onTap;
  final VoidCallback? onAddPressed;

  const CustomBottomBar({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onTap,
    this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate center index for the + button
    final int centerIndex = (items.length / 2).floor();
    final List<Widget> barChildren = [];

    for (int i = 0; i < items.length; i++) {
      // Insert + button at center position
      if (i == centerIndex && onAddPressed != null) {
        barChildren.add(_buildAddButton());
      }
      barChildren.add(_buildBarItem(items[i], i));
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: barChildren,
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: onAddPressed,
      child: Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          color: AppColors.teal,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildBarItem(BottomBarItem item, int index) {
    final bool isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.teal
              : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: item.icon,
              size: 20,
              color: isSelected ? Colors.white : AppColors.labelGrey,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                item.label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
