import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../product/domain/models/category.dart';
import '../../../../shared/widgets/product_card.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../../product/presentation/providers/product_providers.dart';
import '../../../product/domain/models/product.dart';
import '../../../product/presentation/screens/product_detail_screen.dart';
import '../../../product/presentation/screens/product_list_screen.dart';
import '../../../profile/presentation/screens/wishlist_screen.dart';
import '../../../profile/presentation/providers/wishlist_provider.dart';
import 'notification_screen.dart';
import 'search_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featuredProductsState = ref.watch(featuredProductsProvider);
    final trendingProductsState = ref.watch(trendingProductsProvider);
    final categoriesState = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F9F9), // Light cyan/blue project tint
      appBar: AppBar(
        title: _buildSearchBar(context),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.notification_bing_copy, color: Colors.black87),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())),
          ),
          IconButton(
            icon: Consumer(
              builder: (context, ref, child) {
                final count = ref.watch(wishlistCountProvider);
                return Badge.count(
                  count: count,
                  isLabelVisible: count > 0,
                  backgroundColor: Colors.redAccent,
                  child: const Icon(Iconsax.heart_copy, color: Colors.black87),
                );
              },
            ),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WishlistScreen())),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.only(top: 8), child: AutoSliderBanner())),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Text('Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  _buildCategoriesCarousel(context, categoriesState),
                ],
              ),
            ),
          ),
          
          SliverToBoxAdapter(child: _buildSectionHeader('Featured Products', context)),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 250,
              child: featuredProductsState.when(
                data: (products) => _buildFeaturedProducts(products),
                loading: () => _buildFeaturedSkeleton(),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
            ),
          ),
          
          SliverToBoxAdapter(child: _buildSectionHeader('Trending Now', context)),
          trendingProductsState.when(
            data: (products) => _buildTrendingGrid(products),
            loading: () => _buildTrendingSkeleton(),
            error: (err, stack) => SliverToBoxAdapter(child: Center(child: Text('Error: $err'))),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(12)),
        child: const Row(
          children: [
            Icon(Iconsax.search_normal_copy, color: Colors.grey, size: 20),
            SizedBox(width: 12),
            Text('Search products...', style: TextStyle(fontSize: 14, color: Colors.grey)),
            Spacer(),
            Icon(Iconsax.setting_4_copy, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesCarousel(BuildContext context, AsyncValue<List<Category>> categoriesState) {
    return categoriesState.when(
      data: (categories) {
        if (categories.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 85,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(right: 16),
                child: InkWell(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProductListScreen(category: category.name, productCategoryId: category.id))),
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          shape: BoxShape.circle,
                          image: (category.imageUrl != null && category.imageUrl!.isNotEmpty)
                              ? DecorationImage(
                                  image: NetworkImage(category.imageUrl!),
                                  fit: BoxFit.cover)
                              : null,
                        ),
                        child: (category.imageUrl == null || category.imageUrl!.isEmpty)
                            ? Icon(Iconsax.category_copy, size: 28, color: Theme.of(context).primaryColor)
                            : null,
                      ),
                      const SizedBox(height: 8),
                      Text(category.name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87)),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox(height: 100, child: Center(child: CupertinoActivityIndicator())),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildSectionHeader(String title, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          TextButton(onPressed: () {}, child: Text('See All', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.w600))),
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
          width: 155,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          child: ProductCard(
            id: product.id, variantId: product.variantId, title: product.title, price: '₹${product.price.toStringAsFixed(2)}',imageUrl: product.imageUrl, rating: product.rating, discount: product.discount,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product))),
          ),
        );
      },
    );
  }

  Widget _buildFeaturedSkeleton() {
    return ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), itemCount: 4, itemBuilder: (context, index) => Container(width: 155, margin: const EdgeInsets.symmetric(horizontal: 6), child: const ProductCardSkeleton()));
  }

  Widget _buildTrendingGrid(List<Product> products) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 0.72),
        delegate: SliverChildBuilderDelegate((context, index) {
          final product = products[index];
          return ProductCard(id: "trending_${product.id}", variantId: product.variantId, title: product.title, price: '₹${product.price.toStringAsFixed(2)}', imageUrl: product.imageUrl, rating: product.rating, discount: product.discount, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product))));
        }, childCount: products.length),
      ),
    );
  }
  
  Widget _buildTrendingSkeleton() {
    return SliverPadding(padding: const EdgeInsets.symmetric(horizontal: 16), sliver: SliverGrid(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 0.72), delegate: SliverChildBuilderDelegate((context, index) => const ProductCardSkeleton(), childCount: 4)));
  }
}

class AutoSliderBanner extends StatefulWidget {
  const AutoSliderBanner({super.key});
  @override
  State<AutoSliderBanner> createState() => _AutoSliderBannerState();
}

class _AutoSliderBannerState extends State<AutoSliderBanner> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;
  
  final List<String> _bannerImages = [
    'https://images.unsplash.com/photo-1607082348824-0a96f2a4b9da?w=800&q=80',
    'https://images.unsplash.com/photo-1607083206869-4c7672e72a8a?w=800&q=80',
    'https://images.unsplash.com/photo-1483985988355-763728e1935b?w=800&q=80',
    'https://images.unsplash.com/photo-1555529669-e69e7aa0ba9a?w=800&q=80',
    'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=800&q=80',
    'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=800&q=80',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_pageController.hasClients) {
        int nextSelectedPage = _currentPage + 1;
        if (nextSelectedPage >= _bannerImages.length) {
          nextSelectedPage = 0;
        }
        
        _pageController.animateToPage(
          nextSelectedPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutQuart,
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
    final screenHeight = MediaQuery.of(context).size.height;
    final bannerHeight = screenHeight * 0.28; // Responsive height

    return Column(
      children: [
        SizedBox(
          height: bannerHeight,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _bannerImages.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4), // Minimal margin for that 'edge-to-edge' feel
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.zero, // Requested square border
                  image: DecorationImage(
                    image: NetworkImage(_bannerImages[index]),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _bannerImages.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 8,
              width: _currentPage == index ? 32 : 12,
              decoration: BoxDecoration(
                color: _currentPage == index ? const Color(0xFF6366F1) : Colors.grey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
