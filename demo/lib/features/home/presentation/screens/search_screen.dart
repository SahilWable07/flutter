import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../product/presentation/screens/product_list_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _recentSearches = ['Headphones', 'Smart Watch', 'Laptop', 'Shoes'];

  void _onSearchSubmit(String query) {
    if (query.isNotEmpty) {
      // In a real app, you might save to recent searches here
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductListScreen(category: 'Search: $query'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Container(
          height: 40,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onSubmitted: _onSearchSubmit,
            decoration: InputDecoration(
              hintText: 'Search for products, brands...',
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: () => _searchController.clear(),
              ),
            ),
          ),
        ),
      ),
      body: _recentSearches.isEmpty
          ? const Center(child: Text('Start typing to search...'))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Recent Searches',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _recentSearches.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: const Icon(CupertinoIcons.time, color: Colors.grey),
                        title: Text(_recentSearches[index]),
                        trailing: const Icon(CupertinoIcons.arrow_up_left, color: Colors.grey, size: 18),
                        onTap: () {
                          _searchController.text = _recentSearches[index];
                          _onSearchSubmit(_recentSearches[index]);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
