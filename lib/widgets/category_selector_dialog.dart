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
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.25,
      maxChildSize: 0.95,
      snap: false,
      builder: (context, scrollController) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            bool isAllSelected =
                selectedCategories.length == EventCategory.values.length;

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -8),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Drag handle
                  Container(
                    width: 48,
                    height: 5,
                    margin: const EdgeInsets.only(top: 16, bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),

                  // Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'เลือกประเภท',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                  letterSpacing: -0.5,
                                  fontFamily: 'NotoSansThai',
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${selectedCategories.length} จาก ${EventCategory.values.length} รายการ',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w400,
                                  fontFamily: 'NotoSansThai',
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Checkbox
                        GestureDetector(
                          onTap: () {
                            setModalState(() {
                              if (isAllSelected) {
                                selectedCategories.clear();
                              } else {
                                selectedCategories =
                                    EventCategory.values.toList();
                              }
                            });
                            widget.onCategoriesSelected(
                                List.from(selectedCategories));
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: isAllSelected
                                  ? const Color(0xFF4673E5)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isAllSelected
                                    ? const Color(0xFF4673E5)
                                    : Colors.grey.shade300,
                                width: 2,
                              ),
                              boxShadow: isAllSelected
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF4673E5)
                                            .withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: isAllSelected
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 18,
                                  )
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Category list
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: ListView.separated(
                          controller: scrollController,
                          physics: const ClampingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: EventCategory.values.length,
                          separatorBuilder: (context, index) => Container(
                            height: 1,
                            margin: const EdgeInsets.only(left: 56, right: 16),
                            color: Colors.grey.shade200,
                          ),
                          itemBuilder: (context, index) {
                            final category = EventCategory.values[index];
                            final isSelected =
                                selectedCategories.contains(category);

                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF4673E5).withOpacity(0.08)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.grey.shade200,
                                          width: 1,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          category.emoji,
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        category.label,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                          fontFamily: 'NotoSansThai',
                                        ),
                                      ),
                                    ),
                                    AnimatedScale(
                                      scale: isSelected ? 1.0 : 0.9,
                                      duration:
                                          const Duration(milliseconds: 150),
                                      child: Switch.adaptive(
                                        value: isSelected,
                                        onChanged: (value) {
                                          setModalState(() {
                                            if (value) {
                                              selectedCategories.add(category);
                                            } else {
                                              selectedCategories
                                                  .remove(category);
                                            }
                                          });
                                          widget.onCategoriesSelected(
                                              List.from(selectedCategories));
                                        },
                                        activeColor: const Color(0xFF4673E5),
                                        activeTrackColor:
                                            const Color(0xFF4673E5)
                                                .withOpacity(0.3),
                                        inactiveThumbColor:
                                            Colors.grey.shade400,
                                        inactiveTrackColor:
                                            Colors.grey.shade300,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  // Bottom safe area
                  Container(
                    height: MediaQuery.of(context).padding.bottom + 20,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
