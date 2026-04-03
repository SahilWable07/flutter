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
    {'icon': Icons.account_balance_wallet, 'label': 'Wallet'},
    {'icon': Icons.phone_android, 'label': 'Mobiles'},
    {'icon': Icons.discount, 'label': 'Deals'},
    {'icon': Icons.checkroom, 'label': 'Fashion'},
    {'icon': Icons.chair, 'label': 'Home'},
    {'icon': Icons.local_grocery_store, 'label': 'Groceries'},
    {'icon': Icons.laptop, 'label': 'Electronics'},
    {'icon': Icons.toys, 'label': 'Toys'},
  ];

  final Map<int, List<Map<String, dynamic>>> _gridItems = {
    1: [
      {'icon': Icons.phone_android, 'label': 'Mobiles'},
      {'icon': Icons.headphones, 'label': 'Accessories'},
      {'icon': Icons.memory, 'label': 'Processors'},
      {'icon': Icons.watch, 'label': 'Smartwatches'},
    ],
    0: [
      {'icon': Icons.qr_code_scanner, 'label': 'Scan & Pay'},
      {'icon': Icons.money, 'label': 'Send Money'},
    ],
    2: [
      {'icon': Icons.local_offer, 'label': 'Clearance'},
      {'icon': Icons.card_giftcard, 'label': 'Coupons'},
    ],
    3: [
      {'icon': Icons.star, 'label': 'Top Brands'},
      {'icon': Icons.watch, 'label': 'Watches'},
      {'icon': Icons.business_center, 'label': 'Bags'},
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
                          child: Icon(cat['icon'], color: Colors.blueGrey.shade800, size: 24),
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
                  child: GridView.builder(
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
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ],
                                ),
                                child: Center(
                                  child: Icon(item['icon'], size: 36, color: Theme.of(context).primaryColor),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
