import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../product/presentation/providers/product_providers.dart';
import '../../../product/domain/models/category.dart';
import '../../../product/presentation/screens/product_list_screen.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  int _selectedRailIndex = 0;

  @override
  Widget build(BuildContext context) {
    final categoriesState = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFE2F6F8),
        title: _buildSearchBar(),
      ),
      body: categoriesState.when(
        data: (categories) {
          if (categories.isEmpty) return const Center(child: Text('No categories found'));
          
          final selectedCategory = categories[_selectedRailIndex < categories.length ? _selectedRailIndex : 0];
          final subcategoriesState = ref.watch(subcategoriesProvider(selectedCategory.id));
          
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Rail (Main Categories)
              _buildCategoryRail(categories),

              // Right Grid (Subcategories)
              Expanded(
                child: _buildSubcategoryGrid(selectedCategory, subcategoriesState),
              ),
            ],
          );
        },
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade400, width: 1),
      ),
      child: const Row(
        children: [
          Icon(CupertinoIcons.search, color: Colors.black87),
          SizedBox(width: 8),
          Expanded(
            child: Text('Search Shop', style: TextStyle(color: Colors.grey, fontSize: 16)),
          ),
          Icon(Icons.camera_alt_outlined, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildCategoryRail(List<Category> categories) {
    return Container(
      width: 90,
      decoration: const BoxDecoration(
        color: Color(0xFFF7F7F7),
        border: Border(right: BorderSide(color: Color(0xFFE0E0E0), width: 1)),
      ),
      child: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedRailIndex == index;
          final cat = categories[index];
          return GestureDetector(
            onTap: () => setState(() => _selectedRailIndex = index),
            child: Container(
              color: isSelected ? Colors.white : Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: cat.imageUrl != null ? NetworkImage(cat.imageUrl!) : null,
                    child: cat.imageUrl == null ? const Icon(CupertinoIcons.square_grid_2x2, size: 18) : null,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    cat.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? const Color(0xFF008296) : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubcategoryGrid(Category category, AsyncValue<List<Subcategory>> subcategoriesState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            category.name,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: subcategoriesState.when(
            data: (subcategories) {
              if (subcategories.isEmpty) {
                return const Center(child: Text('No subcategories found', style: TextStyle(fontSize: 12, color: Colors.grey)));
              }
              return GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 24,
                  childAspectRatio: 0.8,
                ),
                itemCount: subcategories.length,
                itemBuilder: (context, index) {
                  final sub = subcategories[index];
                  return GestureDetector(
                    onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductListScreen(
                              category: sub.name,
                              subcategoryId: sub.id,
                            ),
                          ),
                        );
                    },
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              image: sub.imageUrl != null 
                                ? DecorationImage(
                                    image: NetworkImage(sub.imageUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                            ),
                            child: sub.imageUrl == null 
                              ? const Center(child: Icon(CupertinoIcons.tag, size: 20, color: Colors.grey))
                              : null,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          sub.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CupertinoActivityIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(fontSize: 12))),
          ),
        ),
      ],
    );
  }
}
