import 'package:flutter/material.dart';
import '../models/event_model.dart';

class CategorySelectorDialog extends StatefulWidget {
  final List<EventCategory> initiallySelectedCategories;
  final ValueChanged<List<EventCategory>> onCategoriesSelected;

  const CategorySelectorDialog({
    super.key,
    required this.initiallySelectedCategories,
    required this.onCategoriesSelected,
  });

  @override
  State<CategorySelectorDialog> createState() => _CategorySelectorDialogState();
}

class _CategorySelectorDialogState extends State<CategorySelectorDialog> {
  late List<EventCategory> selectedCategories;

  @override
  void initState() {
    super.initState();
    selectedCategories = List.from(widget.initiallySelectedCategories);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(), // แตะที่ไหนก็ได้เพื่อปิด popup
      child: Material(
        color: Colors.transparent,
        child: StatefulBuilder(
          builder: (context, setModalState) {
            // Check if all categories are selected for the "All" toggle
            bool isAllSelected =
                selectedCategories.length == EventCategory.values.length;

            return Align(
              alignment: Alignment.bottomCenter,
              child: GestureDetector(
                onTap: () {}, // ป้องกันการปิด popup เมื่อแตะที่เนื้อหา
                onPanUpdate: (details) {
                  // ตรวจสอบการปัดนิ้วลงมา
                  if (details.delta.dy > 0) {
                    // ถ้าปัดลงมา
                    final velocity = details.delta.dy;
                    if (velocity > 5) {
                      // ความเร็วในการปัด
                      Navigator.of(context).pop();
                    }
                  }
                },
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.75,
                    minHeight: MediaQuery.of(context).size.height * 0.4,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEDF0F7),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 15,
                        offset: Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Drag handle
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(top: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      // Header with "All" toggle
                      Container(
                        padding: const EdgeInsets.only(
                            left: 18, right: 28, top: 6, bottom: 6),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                                color: Colors.grey.shade200, width: 1),
                          ),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(
                                width:
                                    10), // เพื่อให้ "เลือกประเภท" อยู่ในแนวเดียวกับอีโมจิ
                            const Expanded(
                              child: Text(
                                'เลือกประเภท',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            const Text(
                              'All',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(
                                width:
                                    12), // เพิ่มเป็น 12 เพื่อให้ Switch ขยับไปทางขวา
                            Transform.scale(
                              scale: 0.8, // ลดขนาดให้ตรงกับ switch ด้านล่าง
                              child: Switch(
                                value: isAllSelected,
                                onChanged: (value) {
                                  setModalState(() {
                                    if (value) {
                                      selectedCategories =
                                          EventCategory.values.toList();
                                    } else {
                                      selectedCategories.clear();
                                    }
                                  });
                                  widget.onCategoriesSelected(
                                      List.from(selectedCategories));
                                },
                                activeColor: const Color(0xFF4673E5),
                                activeTrackColor:
                                    const Color(0xFF4673E5).withOpacity(0.3),
                                inactiveThumbColor: Colors.grey.shade400,
                                inactiveTrackColor: Colors.grey.shade300,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Category list with toggle switches
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 8),
                          itemCount: EventCategory.values.length,
                          itemBuilder: (context, index) {
                            final category = EventCategory.values[index];
                            final isSelected =
                                selectedCategories.contains(category);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 0.32),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey.shade200,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    category.emoji,
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      category.label,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  Transform.scale(
                                    scale: 0.8,
                                    child: Switch(
                                      value: isSelected,
                                      onChanged: (value) {
                                        setModalState(() {
                                          if (value) {
                                            selectedCategories.add(category);
                                          } else {
                                            selectedCategories.remove(category);
                                          }
                                        });
                                        widget.onCategoriesSelected(
                                            List.from(selectedCategories));
                                      },
                                      activeColor: const Color(0xFF4673E5),
                                      activeTrackColor: const Color(0xFF4673E5)
                                          .withOpacity(0.3),
                                      inactiveThumbColor: Colors.grey.shade400,
                                      inactiveTrackColor: Colors.grey.shade300,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                      // Safe area for bottom
                      SizedBox(
                        height: MediaQuery.of(context).padding.bottom + 16,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
