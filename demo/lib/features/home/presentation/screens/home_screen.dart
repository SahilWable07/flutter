import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/product_card.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../../product/presentation/providers/product_providers.dart';
import '../../../product/domain/models/product.dart';
import '../../../product/presentation/screens/product_detail_screen.dart';
import '../../../product/presentation/screens/product_list_screen.dart';
import '../../../cart/presentation/screens/cart_screen.dart';
import 'notification_screen.dart';
import 'search_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featuredProductsState = ref.watch(featuredProductsProvider);
    final trendingProductsState = ref.watch(trendingProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: _buildSearchBar(context),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.bell),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen()));
            },
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.cart),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. Categories Strip
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: _buildCategories(context),
            ),
          ),
          
          // 2. Auto-Sliding Banner
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: 8),
              child: AutoSliderBanner(),
            ),
          ),
          
          // 3. Featured Products Horizontal Scroll
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: _buildSectionHeader('Featured Products', context),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 240, // Standard card height
              child: featuredProductsState.when(
                data: (products) => _buildFeaturedProducts(products),
                loading: () => _buildFeaturedSkeleton(),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
            ),
          ),
          
          // 4. Trending Grid
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 8),
              child: _buildSectionHeader('Trending Now', context),
            ),
          ),
          trendingProductsState.when(
            data: (products) => _buildTrendingGrid(products),
            loading: () => _buildTrendingSkeleton(),
            error: (err, stack) => SliverToBoxAdapter(
              child: Center(child: Text('Error: $err')),
            ),
          ),
          
          const SliverToBoxAdapter(
            child: SizedBox(height: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()));
      },
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const AbsorbPointer(
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search for products...',
              hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
              prefixIcon: Icon(CupertinoIcons.search, color: Colors.grey, size: 20),
              suffixIcon: Icon(Icons.mic, color: Colors.grey, size: 20),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategories(BuildContext context) {
    final categories = [
      {'image': 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=200&q=80', 'label': 'Mobiles'},
      {'image': 'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?w=200&q=80', 'label': 'Laptops'},
      {'image': 'https://images.unsplash.com/photo-1445205170230-053b830160b7?w=200&q=80', 'label': 'Fashion'},
      {'image': 'https://images.unsplash.com/photo-1616046229478-9901c5536a45?w=200&q=80', 'label': 'Home'},
      {'image': 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=200&q=80', 'label': 'Cameras'},
    ];

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 20),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductListScreen(category: categories[index]['label'] as String),
                  ),
                );
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: NetworkImage(categories[index]['image'] as String),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    categories[index]['label'] as String,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text('VIEW ALL', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedProducts(List<Product> products) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Container(
          width: 140, // Standard card width
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: ProductCard(
            id: product.id,
            title: product.title,
            price: '\$${product.price.toStringAsFixed(2)}',
            imageUrl: product.imageUrl,
            rating: product.rating,
            discount: product.discount,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildFeaturedSkeleton() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          width: 140,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: const ProductCardSkeleton(),
        );
      },
    );
  }

  Widget _buildTrendingGrid(List<Product> products) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 8.0,
          crossAxisSpacing: 8.0,
          childAspectRatio: 0.70, // Standard commerce fit
        ),
        delegate: SliverChildBuilderDelegate(
          (BuildContext context, int index) {
            final product = products[index];
            return ProductCard(
              id: "trending_${product.id}",
              title: product.title,
              price: '\$${product.price.toStringAsFixed(2)}',
              imageUrl: product.imageUrl,
              rating: product.rating,
              discount: product.discount,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
                );
              },
            );
          },
          childCount: products.length,
        ),
      ),
    );
  }
  
  Widget _buildTrendingSkeleton() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 8.0,
          crossAxisSpacing: 8.0,
          childAspectRatio: 0.70,
        ),
        delegate: SliverChildBuilderDelegate(
          (BuildContext context, int index) {
            return const ProductCardSkeleton();
          },
          childCount: 4,
        ),
      ),
    );
  }
}

class AutoSliderBanner extends StatefulWidget {
  const AutoSliderBanner({super.key});

  @override
  State<AutoSliderBanner> createState() => _AutoSliderBannerState();
}

class _AutoSliderBannerState extends State<AutoSliderBanner> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  final List<String> _bannerImages = [
    'https://images.unsplash.com/photo-1607082348824-0a96f2a4b9da?w=800&q=80',
    'https://images.unsplash.com/photo-1607083206869-4c7672e72a8a?w=800&q=80',
    'https://images.unsplash.com/photo-1483985988355-763728e1935b?w=800&q=80',
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (_pageController.hasClients) {
        if (_currentPage < _bannerImages.length - 1) {
          _currentPage++;
        } else {
          _currentPage = 0;
        }
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeIn,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemCount: _bannerImages.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(_bannerImages[index]),
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _bannerImages.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 6,
              width: _currentPage == index ? 16 : 6,
              decoration: BoxDecoration(
                color: _currentPage == index ? Theme.of(context).primaryColor : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
