import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../product/presentation/screens/product_list_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  int _selectedRailIndex = 0;

  final List<Map<String, dynamic>> _sideCategories = [
    {'image': 'https://images.unsplash.com/photo-1628191010210-a59de33e5941?w=150&q=80', 'label': 'Wallet'},
    {'image': 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=150&q=80', 'label': 'Mobiles'},
    {'image': 'https://images.unsplash.com/photo-1607082348824-0a96f2a4b9da?w=150&q=80', 'label': 'Deals'},
    {'image': 'https://images.unsplash.com/photo-1445205170230-053b830160b7?w=150&q=80', 'label': 'Fashion'},
    {'image': 'https://images.unsplash.com/photo-1616046229478-9901c5536a45?w=150&q=80', 'label': 'Home'},
    {'image': 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=150&q=80', 'label': 'Groceries'},
    {'image': 'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?w=150&q=80', 'label': 'Electronics'},
    {'image': 'https://images.unsplash.com/photo-1596461404969-9ae70f2830c1?w=150&q=80', 'label': 'Toys'},
  ];

  final Map<int, List<Map<String, dynamic>>> _gridItems = {
    1: [
      {'image': 'https://images.unsplash.com/photo-1598327105666-5b89351cb31b?w=250&q=80', 'label': 'Mobiles'},
      {'image': 'https://images.unsplash.com/photo-1583394838336-acd977736f90?w=250&q=80', 'label': 'Accessories'},
      {'image': 'https://images.unsplash.com/photo-1591799264318-7e6ef8ddb7ea?w=250&q=80', 'label': 'Processors'},
      {'image': 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=250&q=80', 'label': 'Smartwatches'},
    ],
    0: [
      {'image': 'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?w=250&q=80', 'label': 'Scan & Pay'},
      {'image': 'https://images.unsplash.com/photo-1601597111158-2fceff292cdc?w=250&q=80', 'label': 'Send Money'},
    ],
    2: [
      {'image': 'https://images.unsplash.com/photo-1607083206869-4c7672e72a8a?w=250&q=80', 'label': 'Clearance'},
      {'image': 'https://images.unsplash.com/photo-1549465220-1a8b9238cd48?w=250&q=80', 'label': 'Coupons'},
    ],
    3: [
      {'image': 'https://images.unsplash.com/photo-1525507119028-ed4c629a60a3?w=250&q=80', 'label': 'Top Brands'},
      {'image': 'https://images.unsplash.com/photo-1524592094714-b132f81dfda6?w=250&q=80', 'label': 'Watches'},
      {'image': 'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=250&q=80', 'label': 'Bags'},
    ]
  };

  @override
  Widget build(BuildContext context) {
    final subcategories = _gridItems[_selectedRailIndex] ?? _gridItems[1]!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFE2F6F8), // Light Amazon Cyan background
        title: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade400, width: 1),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
            ],
          ),
          child: const Row(
            children: [
              Icon(CupertinoIcons.search, color: Colors.black87),
              SizedBox(width: 8),
              Expanded(
                child: Text('Search Shop', style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.normal)),
              ),
              Icon(Icons.camera_alt_outlined, color: Colors.grey),
            ],
          ),
        ),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Rail (Main Categories)
          Container(
            width: 90,
            decoration: const BoxDecoration(
              color: Color(0xFFF7F7F7),
              border: Border(right: BorderSide(color: Color(0xFFE0E0E0), width: 1)),
            ),
            child: ListView.builder(
              itemCount: _sideCategories.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedRailIndex == index;
                final cat = _sideCategories[index];
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedRailIndex = index);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      border: Border(
                        left: BorderSide(
                          color: isSelected ? const Color(0xFF008296) : Colors.transparent,
                          width: 4,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.blueGrey.withValues(alpha: 0.1),
                          backgroundImage: NetworkImage(cat['image'] as String),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          cat['label'],
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
          ),

          // Right Grid (Subcategories)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Top Categories For You',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: GridView.builder(
                      key: ValueKey<int>(_selectedRailIndex),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 24,
                        childAspectRatio: 0.8, // Taller for label space
                      ),
                      itemCount: subcategories.length,
                      itemBuilder: (context, index) {
                        final item = subcategories[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductListScreen(category: item['label']),
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
                                    image: DecorationImage(
                                      image: NetworkImage(item['image'] as String),
                                      fit: BoxFit.cover,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item['label'],
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
