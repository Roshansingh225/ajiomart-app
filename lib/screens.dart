import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'main.dart';
import 'models.dart';
import 'store_api.dart';

const _wine = Color(0xFF8D344B);
const _ink = Color(0xFF271C1D);
const _muted = Color(0xFF76696A);
const _line = Color(0xFFEAE1DC);
const _storePhone = '9905138225';
const _storeWhatsApp = '919905138225';

void _notice(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
}

class ShopShell extends StatefulWidget {
  const ShopShell({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  State<ShopShell> createState() => _ShopShellState();
}

class _ShopShellState extends State<ShopShell> {
  late int _tab;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
  }

  void selectTab(int index) => setState(() => _tab = index);

  @override
  Widget build(BuildContext context) {
    final api = StoreScope.of(context);
    final pages = [
      const HomeTab(),
      const ShopTab(),
      const WishlistTab(),
      const CartTab(),
      const AccountTab(),
    ];
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 18,
        title: InkWell(
          onTap: () => setState(() => _tab = 0),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Image.asset('assets/images/ajiomart-logo.png',
                  width: 30, height: 30, fit: BoxFit.cover),
            ),
            const SizedBox(width: 10),
            const Text('AJIOMART',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.9,
                    color: _ink)),
          ]),
        ),
        actions: [
          IconButton(
            tooltip: 'Search products',
            onPressed: () => setState(() => _tab = 1),
            icon: const Icon(Icons.search_rounded),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: IconButton(
              tooltip: 'Your bag',
              onPressed: () => setState(() => _tab = 3),
              icon: Badge(
                  label: Text('${api.cartCount}'),
                  isLabelVisible: api.cartCount > 0,
                  child: const Icon(Icons.shopping_bag_outlined)),
            ),
          ),
        ],
      ),
      body: IndexedStack(index: _tab, children: pages),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'style-assistant',
        backgroundColor: const Color(0xFF3A272B),
        foregroundColor: Colors.white,
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: const Color(0xFFFCF9F6),
          builder: (_) => const _StyleAssistantSheet(),
        ),
        icon: const Icon(Icons.auto_awesome_rounded, size: 19),
        label: const Text('Style assistant'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) => setState(() => _tab = index),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view_rounded),
              label: 'Shop'),
          NavigationDestination(
              icon: Icon(Icons.favorite_border),
              selectedIcon: Icon(Icons.favorite),
              label: 'Wishlist'),
          NavigationDestination(
              icon: Icon(Icons.shopping_bag_outlined),
              selectedIcon: Icon(Icons.shopping_bag),
              label: 'Bag'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Account'),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.title, {this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
              child: Text(title,
                  style: Theme.of(context).textTheme.headlineMedium)),
          if (action != null)
            TextButton(
                onPressed: onAction,
                child: Text(action!,
                    style: const TextStyle(
                        color: _wine, fontWeight: FontWeight.w700))),
        ],
      );
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: const TextStyle(
            color: _wine,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.55),
      );
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return const _ImagePlaceholder();
    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : const ColoredBox(
              color: Color(0xFFF2EAE4),
              child: Center(
                  child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _wine)))),
      errorBuilder: (_, __, ___) => const _ImagePlaceholder(),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();
  @override
  Widget build(BuildContext context) => const ColoredBox(
        color: Color(0xFFF2EAE4),
        child: Center(
            child:
                Icon(Icons.image_outlined, size: 32, color: Color(0xFFB9A8A1))),
      );
}

class _ProductCard extends StatelessWidget {
  const _ProductCard(this.product);
  final ShopProduct product;

  @override
  Widget build(BuildContext context) {
    final api = StoreScope.of(context);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () =>
            Navigator.pushNamed(context, '/product', arguments: product.id),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: .79,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _ProductImage(url: product.imageUrl),
                  if (product.badge.isNotEmpty)
                    Positioned(
                        left: 9,
                        top: 10,
                        child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 5),
                            decoration: BoxDecoration(
                                color: Colors.white.withOpacity(.92),
                                borderRadius: BorderRadius.circular(30)),
                            child: Text(product.badge,
                                style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: _ink)))),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton.filledTonal(
                      visualDensity: VisualDensity.compact,
                      style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(.9)),
                      onPressed: () => api.toggleWishlist(product.id),
                      icon: Icon(
                          api.wishlistIds.contains(product.id)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: _wine,
                          size: 19),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 10, 11, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.category.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: _muted,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.15)),
                  const SizedBox(height: 4),
                  Text(product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13,
                          height: 1.25,
                          fontWeight: FontWeight.w700,
                          color: _ink)),
                  const SizedBox(height: 7),
                  Row(children: [
                    Text(money(product.price),
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: _ink)),
                    if (product.originalPrice > product.price) ...[
                      const SizedBox(width: 6),
                      Flexible(
                          child: Text(money(product.originalPrice),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: _muted,
                                  decoration: TextDecoration.lineThrough))),
                    ],
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductGrid extends StatelessWidget {
  const _ProductGrid(
      {required this.products, this.shrinkWrap = false, this.physics});
  final List<ShopProduct> products;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const _EmptyState(
          icon: Icons.search_off_rounded,
          title: 'No pieces found',
          message: 'Try another search or category.');
    }
    return GridView.builder(
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 22),
      itemCount: products.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 13,
          // Leave enough height for a two-line product name and the price
          // below the fixed-ratio image on narrow Android screens.
          childAspectRatio: .50),
      itemBuilder: (_, index) => _ProductCard(products[index]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState(
      {required this.icon,
      required this.title,
      required this.message,
      this.button,
      this.onPressed});
  final IconData icon;
  final String title;
  final String message;
  final String? button;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 42, color: const Color(0xFFBDA5A2)),
            const SizedBox(height: 12),
            Text(title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 7),
            Text(message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
            if (button != null) ...[
              const SizedBox(height: 18),
              FilledButton(onPressed: onPressed, child: Text(button!)),
            ],
          ]),
        ),
      );
}

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final api = StoreScope.of(context);
    final picks = api.products.take(4).toList();
    return RefreshIndicator(
      color: _wine,
      onRefresh: api.refreshProducts,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              height: 345,
              child: Stack(fit: StackFit.expand, children: [
                Image.asset('assets/images/ajiomart-colour-campaign.jpg',
                    fit: BoxFit.cover, alignment: const Alignment(0, -.18)),
                const DecoratedBox(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Color(0xCC231416), Color(0x001A1112)],
                            stops: [0, .78]))),
                Positioned(
                  left: 22,
                  right: 22,
                  bottom: 23,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _Eyebrow('The new season edit'),
                        const SizedBox(height: 7),
                        const Text('Make room\nfor a little more you.',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 31,
                                height: 1.07,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -.8)),
                        const SizedBox(height: 15),
                        FilledButton.tonal(
                            onPressed: () => _goTab(context, 1),
                            style: FilledButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: _ink),
                            child: const Text('Shop the collection')),
                      ]),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 24),
          const _SectionHeading('Shop by mood'),
          const SizedBox(height: 12),
          SizedBox(
            height: 91,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: productCategories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 9),
              itemBuilder: (context, index) {
                final category = productCategories[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    ShopTab.requestedCategory.value = category;
                    _goTab(context, 1);
                  },
                  child: Container(
                    width: 94,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 14),
                    decoration: BoxDecoration(
                        color: const Color(0xFFF0E7E1),
                        borderRadius: BorderRadius.circular(18)),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_categoryIcon(category), size: 22, color: _wine),
                          const SizedBox(height: 7),
                          Text(category,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: _ink,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700)),
                        ]),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeading('Ajiomart favourites',
              action: 'View all', onAction: () => _goTab(context, 1)),
          if (api.productsLoading && picks.isEmpty)
            const Padding(
                padding: EdgeInsets.all(30),
                child: Center(child: CircularProgressIndicator(color: _wine)))
          else if (picks.isEmpty)
            Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                    api.error.isEmpty
                        ? 'The latest collection is being prepared.'
                        : api.error,
                    style: Theme.of(context).textTheme.bodyMedium))
          else
            _ProductGrid(
                products: picks,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics()),
          const SizedBox(height: 8),
          const _LookbookSection(),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: SizedBox(
                height: 170,
                child: Stack(fit: StackFit.expand, children: [
                  Image.asset('assets/images/ajiomart-brand-story.jpg',
                      fit: BoxFit.cover),
                  const DecoratedBox(
                      decoration: BoxDecoration(
                          gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [Color(0xC9221617), Color(0x001C1415)]))),
                  const Padding(
                      padding: EdgeInsets.all(20),
                      child: Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                              width: 215,
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Beauty, in your own rhythm.',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 22,
                                            height: 1.2,
                                            fontWeight: FontWeight.w700)),
                                  ])))),
                ])),
          ),
          const SizedBox(height: 20),
          const _ServiceHighlights(),
        ],
      ),
    );
  }
}

class _LookbookSection extends StatefulWidget {
  const _LookbookSection();

  @override
  State<_LookbookSection> createState() => _LookbookSectionState();
}

class _LookbookSectionState extends State<_LookbookSection> {
  static const _stories = [
    (
      'Dresses',
      'Poolside colour',
      'Light layers. Long afternoons.',
      'assets/images/ajiomart-lookbook-poolside.jpg'
    ),
    (
      'Skincare',
      'The everyday ritual',
      'A slower start, just for you.',
      'assets/images/ajiomart-lookbook-ritual.jpg'
    ),
    (
      'Handbags',
      'Ready when you are',
      'One last detail. Then, out the door.',
      'assets/images/ajiomart-lookbook-handbag.jpg'
    ),
  ];
  int _active = 0;

  @override
  Widget build(BuildContext context) {
    final story = _stories[_active];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _Eyebrow('Ajiomart / Lookbook 2026'),
      const SizedBox(height: 9),
      ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          height: 280,
          child: Stack(fit: StackFit.expand, children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              child: Image.asset(story.$4,
                  key: ValueKey(story.$4), fit: BoxFit.cover),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xC9211518), Color(0x00211518)],
                  stops: [0, .75],
                ),
              ),
            ),
            Positioned(
              left: 17,
              right: 17,
              bottom: 17,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${story.$1} / The story',
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            letterSpacing: 1.1,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 5),
                    Text(story.$2,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.w700)),
                    Text(story.$3,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 10),
                    Row(children: [
                      FilledButton.tonal(
                        onPressed: () {
                          ShopTab.requestedCategory.value = story.$1;
                          _goTab(context, 1);
                        },
                        style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: _ink,
                            minimumSize: const Size(0, 40)),
                        child: const Text('Shop the story'),
                      ),
                      const Spacer(),
                      IconButton.filledTonal(
                        onPressed: () => setState(() => _active =
                            (_active + _stories.length - 1) % _stories.length),
                        style:
                            IconButton.styleFrom(backgroundColor: Colors.white),
                        icon: const Icon(Icons.chevron_left, color: _ink),
                      ),
                      const SizedBox(width: 4),
                      IconButton.filledTonal(
                        onPressed: () => setState(
                            () => _active = (_active + 1) % _stories.length),
                        style:
                            IconButton.styleFrom(backgroundColor: Colors.white),
                        icon: const Icon(Icons.chevron_right, color: _ink),
                      ),
                    ]),
                  ]),
            ),
          ]),
        ),
      ),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
            _stories.length,
            (index) => TextButton(
                  onPressed: () => setState(() => _active = index),
                  child: Text(_stories[index].$1,
                      style: TextStyle(
                          color: _active == index ? _wine : _muted,
                          fontSize: 10,
                          fontWeight: _active == index
                              ? FontWeight.w800
                              : FontWeight.w500)),
                )),
      ),
    ]);
  }
}

class _ServiceHighlights extends StatelessWidget {
  const _ServiceHighlights();
  @override
  Widget build(BuildContext context) => const Row(children: [
        Expanded(
            child: _ServiceItem(
                icon: Icons.local_shipping_outlined,
                title: 'Pan-India',
                caption: 'Delivery')),
        Expanded(
            child: _ServiceItem(
                icon: Icons.lock_outline,
                title: 'Secure',
                caption: 'Checkout')),
        Expanded(
            child: _ServiceItem(
                icon: Icons.support_agent_outlined,
                title: 'Here to',
                caption: 'Help')),
      ]);
}

class _ServiceItem extends StatelessWidget {
  const _ServiceItem(
      {required this.icon, required this.title, required this.caption});
  final IconData icon;
  final String title;
  final String caption;
  @override
  Widget build(BuildContext context) => Column(children: [
        Icon(icon, size: 21, color: _wine),
        const SizedBox(height: 5),
        Text(title,
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w800, color: _ink)),
        Text(caption, style: const TextStyle(fontSize: 10, color: _muted))
      ]);
}

class _StyleAssistantSheet extends StatefulWidget {
  const _StyleAssistantSheet();
  @override
  State<_StyleAssistantSheet> createState() => _StyleAssistantSheetState();
}

class _StyleAssistantSheetState extends State<_StyleAssistantSheet> {
  final _input = TextEditingController();
  final List<(bool, String)> _messages = [
    (
      false,
      'Hi, I am the Ajiomart style assistant. Tell me the plan and I will suggest fashion, beauty, and jewellery picks.'
    ),
  ];
  static const _prompts = [
    'Office outfit',
    'Wedding guest look',
    'Jewellery finishing touch',
    'Everyday glow kit'
  ];

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 14, 16, MediaQuery.viewInsetsOf(context).bottom + 14),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .72,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  _Eyebrow('Ajiomart AI'),
                  SizedBox(height: 3),
                  Text('Style Assistant',
                      style: TextStyle(
                          color: _ink,
                          fontSize: 21,
                          fontWeight: FontWeight.w700))
                ])),
            IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close))
          ]),
          const Divider(height: 15),
          Expanded(
              child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: _messages
                      .map((message) => Align(
                          alignment: message.$1
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.sizeOf(context).width * .78),
                              decoration: BoxDecoration(
                                  color: message.$1
                                      ? const Color(0xFFF0DDE2)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(15)),
                              child: Text(message.$2,
                                  style: const TextStyle(
                                      color: _ink,
                                      fontSize: 13,
                                      height: 1.4)))))
                      .toList())),
          Wrap(
              spacing: 6,
              runSpacing: 4,
              children: _prompts
                  .map((prompt) => ActionChip(
                      avatar: const Icon(Icons.auto_awesome,
                          size: 13, color: _wine),
                      label: Text(prompt, style: const TextStyle(fontSize: 10)),
                      onPressed: () => _ask(prompt)))
                  .toList()),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
                child: TextField(
                    controller: _input,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _ask,
                    decoration: const InputDecoration(
                        hintText: 'Ask for a look, shade, or routine…',
                        isDense: true))),
            const SizedBox(width: 8),
            IconButton.filled(
                onPressed: () => _ask(_input.text),
                icon: const Icon(Icons.send_rounded))
          ]),
        ]),
      ),
    );
  }

  void _ask(String prompt) {
    final question = prompt.trim();
    if (question.isEmpty) return;
    final api = StoreScope.of(context);
    final lower = question.toLowerCase();
    ShopProduct? find(String category) => api.products
        .where((product) => product.category == category)
        .firstOrNull;
    final bag = find('Handbags');
    final shoes = find('Footwear');
    final dress = find('Dresses');
    final makeup = find('Makeup');
    final skincare = find('Skincare');
    final jewellery = find('Jewellery');
    String reply;
    if (lower.contains('office') || lower.contains('work')) {
      reply =
          'For work, try ${bag?.name ?? 'a structured handbag'} with tailored separates and a clean lip. Keep the palette calm, then add ${shoes?.name ?? 'comfortable shoes'} for an easy commute.';
    } else if (lower.contains('jewel') || lower.contains('accessor')) {
      reply = jewellery == null
          ? 'A delicate necklace or sculptural earrings can finish the look. Our jewellery edit is being curated now.'
          : '${jewellery.name} at ${money(jewellery.price)} is a lovely finishing touch. Pair it with a clean neckline and keep the rest simple.';
    } else if (lower.contains('wedding') ||
        lower.contains('party') ||
        lower.contains('evening')) {
      reply =
          'For an event, start with ${dress?.name ?? 'a satin dress'}${dress == null ? '' : ' at ${money(dress.price)}'} and finish with a berry lip from ${makeup?.name ?? 'the lip wardrobe'}.${jewellery == null ? '' : ' Add ${jewellery.name} at ${money(jewellery.price)} for a finishing touch.'}';
    } else if (lower.contains('skin') ||
        lower.contains('glow') ||
        lower.contains('beauty')) {
      reply =
          'For a fresh glow, use ${skincare?.name ?? 'a serum kit'} before makeup, then choose a soft coral lip and a light fragrance.';
    } else {
      reply =
          'Build your look around one hero piece, one comfort piece, and one beauty or jewellery finish. Dresses, makeup, and jewellery make an easy Ajiomart pairing.';
    }
    setState(() {
      _messages.add((true, question));
      _messages.add((false, reply));
      _input.clear();
    });
  }
}

void _goTab(BuildContext context, int index) {
  final shell = context.findAncestorStateOfType<_ShopShellState>();
  shell?.selectTab(index);
}

IconData _categoryIcon(String category) => switch (category) {
      'Dresses' => Icons.checkroom_outlined,
      'Co-ords' => Icons.style_outlined,
      'Makeup' => Icons.brush_outlined,
      'Skincare' => Icons.spa_outlined,
      'Fragrance' => Icons.air_outlined,
      'Handbags' => Icons.shopping_bag_outlined,
      'Jewellery' => Icons.auto_awesome_outlined,
      'Footwear' => Icons.ice_skating_outlined,
      _ => Icons.local_mall_outlined,
    };

class ShopTab extends StatefulWidget {
  const ShopTab({super.key});
  static final requestedCategory = ValueNotifier<String?>(null);

  @override
  State<ShopTab> createState() => _ShopTabState();
}

class _ShopTabState extends State<ShopTab> {
  final _search = TextEditingController();
  String _category = 'All';
  String _sort = 'Featured';

  @override
  void initState() {
    super.initState();
    _category = ShopTab.requestedCategory.value ?? 'All';
    ShopTab.requestedCategory.addListener(_categoryRequested);
    ShopTab.requestedCategory.value = null;
  }

  void _categoryRequested() {
    final requested = ShopTab.requestedCategory.value;
    if (requested == null || !mounted) return;
    setState(() => _category = requested);
    ShopTab.requestedCategory.value = null;
  }

  @override
  void dispose() {
    ShopTab.requestedCategory.removeListener(_categoryRequested);
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final api = StoreScope.of(context);
    final query = _search.text.trim().toLowerCase();
    final filtered = api.products.where((product) {
      final matchesCategory =
          _category == 'All' || product.category == _category;
      final matchesSearch = query.isEmpty ||
          '${product.name} ${product.category} ${product.description}'
              .toLowerCase()
              .contains(query);
      return matchesCategory && matchesSearch;
    }).toList();
    if (_sort == 'Price: low to high') {
      filtered.sort((a, b) => a.price.compareTo(b.price));
    }
    if (_sort == 'Price: high to low') {
      filtered.sort((a, b) => b.price.compareTo(a.price));
    }
    if (_sort == 'Top rated') {
      filtered.sort((a, b) => b.rating.compareTo(a.rating));
    }
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 13, 18, 6),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const _Eyebrow('The complete collection'),
          const SizedBox(height: 5),
          const Text('Find your next favourite.',
              style: TextStyle(
                  color: _ink, fontSize: 23, fontWeight: FontWeight.w700)),
          const SizedBox(height: 13),
          TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'Search fashion, beauty, bags…')),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                    children: ['All', ...productCategories]
                        .map((category) => Padding(
                              padding: const EdgeInsets.only(right: 7),
                              child: ChoiceChip(
                                  label: Text(category),
                                  selected: _category == category,
                                  onSelected: (_) =>
                                      setState(() => _category = category),
                                  selectedColor: const Color(0xFFF0DDE2)),
                            ))
                        .toList()),
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Sort products',
              icon: const Icon(Icons.tune_rounded, color: _wine),
              onSelected: (value) => setState(() => _sort = value),
              itemBuilder: (_) => [
                'Featured',
                'Price: low to high',
                'Price: high to low',
                'Top rated'
              ].map((e) => PopupMenuItem(value: e, child: Text(e))).toList(),
            ),
          ]),
          Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 5),
              child: Text('${filtered.length} pieces · $_sort',
                  style: const TextStyle(fontSize: 11, color: _muted))),
        ]),
      ),
      if (api.productsLoading && api.products.isEmpty)
        const Expanded(
            child: Center(child: CircularProgressIndicator(color: _wine)))
      else
        Expanded(child: _ProductGrid(products: filtered)),
    ]);
  }
}

class WishlistTab extends StatelessWidget {
  const WishlistTab({super.key});

  @override
  Widget build(BuildContext context) {
    final api = StoreScope.of(context);
    final items = api.wishlist;
    if (items.isEmpty) {
      return const _EmptyState(
          icon: Icons.favorite_border,
          title: 'Your saved edit',
          message: 'Tap the heart on a product to keep it close.');
    }
    return Column(children: [
      const Padding(
          padding: EdgeInsets.fromLTRB(18, 18, 18, 7),
          child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Eyebrow('Your collection'),
                    SizedBox(height: 5),
                    Text('Wishlist',
                        style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: _ink))
                  ]))),
      Expanded(child: _ProductGrid(products: items)),
    ]);
  }
}

class CartTab extends StatelessWidget {
  const CartTab({super.key});

  @override
  Widget build(BuildContext context) {
    final api = StoreScope.of(context);
    if (api.user == null) {
      return _EmptyState(
          icon: Icons.shopping_bag_outlined,
          title: 'Your bag is waiting',
          message:
              'Sign in to save your cart across devices and continue checkout.',
          button: 'Sign in',
          onPressed: () => Navigator.pushNamed(context, '/auth'));
    }
    if (api.cartLoading) {
      return const Center(child: CircularProgressIndicator(color: _wine));
    }
    if (api.cart.isEmpty) {
      return const _EmptyState(
          icon: Icons.shopping_bag_outlined,
          title: 'Nothing in your bag yet',
          message: 'Find a piece you love and it will be right here.');
    }
    final onlineTotal = api.cartSubtotal * .9;
    final codTotal = api.cartSubtotal + 20;
    return Column(children: [
      Padding(
          padding: const EdgeInsets.fromLTRB(18, 17, 18, 10),
          child: Row(children: [
            const Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  _Eyebrow('Your picks'),
                  SizedBox(height: 4),
                  Text('Your Ajiomart bag.',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: _ink))
                ])),
            Text('${api.cartCount} item${api.cartCount == 1 ? '' : 's'}',
                style:
                    const TextStyle(color: _muted, fontWeight: FontWeight.w600))
          ])),
      Expanded(
          child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
              itemCount: api.cart.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, index) => _CartLineCard(line: api.cart[index]))),
      SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: _line))),
            child: Column(children: [
              Row(children: [
                const Expanded(
                    child: Text('Pay online and save 10%',
                        style: TextStyle(color: _muted, fontSize: 12))),
                Text(money(onlineTotal),
                    style: const TextStyle(
                        color: _wine, fontWeight: FontWeight.w800))
              ]),
              const SizedBox(height: 4),
              Row(children: [
                const Expanded(
                    child: Text('Cash on Delivery (includes ₹20 fee)',
                        style: TextStyle(color: _muted, fontSize: 12))),
                Text(money(codTotal),
                    style: const TextStyle(
                        color: _ink, fontWeight: FontWeight.w700))
              ]),
              const SizedBox(height: 12),
              SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/checkout'),
                      child: const Text('Continue to checkout'))),
            ]),
          )),
    ]);
  }
}

class _CartLineCard extends StatelessWidget {
  const _CartLineCard({required this.line});
  final CartLine line;
  @override
  Widget build(BuildContext context) {
    final api = StoreScope.of(context);
    return Card(
      child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: SizedBox(
                    width: 88,
                    height: 104,
                    child: _ProductImage(url: line.product.imageUrl))),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(line.product.category.toUpperCase(),
                      style: const TextStyle(
                          color: _muted,
                          fontSize: 9,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(line.product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: _ink,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                  const SizedBox(height: 3),
                  Text('${line.color} · ${line.size}',
                      style: const TextStyle(color: _muted, fontSize: 11)),
                  const SizedBox(height: 10),
                  Row(children: [
                    Container(
                        decoration: BoxDecoration(
                            border: Border.all(color: _line),
                            borderRadius: BorderRadius.circular(10)),
                        child: Row(children: [
                          _QuantityButton(
                              icon: Icons.remove,
                              onTap: () => _changeQuantity(
                                  context, api, line, line.quantity - 1)),
                          Text('${line.quantity}',
                              style: const TextStyle(
                                  color: _ink, fontWeight: FontWeight.w700)),
                          _QuantityButton(
                              icon: Icons.add,
                              onTap: () => _changeQuantity(
                                  context, api, line, line.quantity + 1)),
                        ])),
                    const Spacer(),
                    Text(money(line.lineTotal),
                        style: const TextStyle(
                            color: _ink, fontWeight: FontWeight.w800)),
                  ]),
                ])),
          ])),
    );
  }

  Future<void> _changeQuantity(
      BuildContext context, AjiStoreApi api, CartLine line, int value) async {
    try {
      await api.setCartQuantity(line, value);
    } catch (error) {
      if (context.mounted) {
        _notice(
            context, error.toString().replaceFirst('FormatException: ', ''));
      }
    }
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => IconButton(
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      iconSize: 17,
      constraints: const BoxConstraints.tightFor(width: 34, height: 34),
      icon: Icon(icon, color: _wine));
}

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  final _razorpay = Razorpay();
  String _paymentMethod = 'online';
  String _status = '';
  bool _working = false;
  bool _loadedUserDetails = false;
  String _pinStatus = '';
  Timer? _pinLookup;

  @override
  void initState() {
    super.initState();
    for (final field in [
      'customerName',
      'customerPhone',
      'addressLine1',
      'addressLine2',
      'city',
      'state',
      'postalCode',
      'landmark'
    ]) {
      _controllers[field] = TextEditingController();
    }
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _paymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _paymentFailure);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _externalWallet);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadedUserDetails) {
      final user = StoreScope.of(context).user;
      _controllers['customerName']!.text = user?.name ?? '';
      _controllers['customerPhone']!.text =
          user?.phone.replaceAll('+91', '') ?? '';
      _loadedUserDetails = true;
    }
  }

  @override
  void dispose() {
    _pinLookup?.cancel();
    _razorpay.clear();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final api = StoreScope.of(context);
    if (api.user == null) {
      return Scaffold(
          appBar: AppBar(title: const Text('Checkout')),
          body: _EmptyState(
              icon: Icons.lock_outline,
              title: 'Sign in to checkout',
              message: 'Your cart will be ready when you come back.',
              button: 'Sign in',
              onPressed: () => Navigator.pushNamed(context, '/auth')));
    }
    if (api.cart.isEmpty) {
      return Scaffold(
          appBar: AppBar(title: const Text('Checkout')),
          body: const _EmptyState(
              icon: Icons.shopping_bag_outlined,
              title: 'Your bag is empty',
              message: 'Add something you love before checkout.'));
    }
    final subtotal = api.cartSubtotal;
    final discount = _paymentMethod == 'online' ? (subtotal * .10) : 0.0;
    final cod = _paymentMethod == 'cod' ? 20.0 : 0.0;
    final total = subtotal - discount + cod;
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery & payment')),
      body: Form(
          key: _formKey,
          child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 11, 18, 28),
              children: [
                const _Eyebrow('Delivery address'),
                const SizedBox(height: 5),
                const Text('Where should we send it?',
                    style: TextStyle(
                        color: _ink,
                        fontSize: 23,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 15),
                _checkoutField(
                    'customerName', 'Full name', Icons.person_outline,
                    required: true),
                const SizedBox(height: 10),
                _checkoutField('customerPhone', '10-digit mobile number',
                    Icons.phone_outlined,
                    required: true,
                    keyboard: TextInputType.phone,
                    maxLength: 10),
                const SizedBox(height: 10),
                _checkoutField(
                    'addressLine1', 'Address line 1', Icons.home_outlined,
                    required: true),
                const SizedBox(height: 10),
                _checkoutField('addressLine2', 'Address line 2 (optional)',
                    Icons.apartment_outlined),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                      child: _checkoutField(
                          'city', 'City', Icons.location_city_outlined,
                          required: true)),
                  const SizedBox(width: 9),
                  Expanded(
                      child: _checkoutField(
                          'state', 'State', Icons.map_outlined,
                          required: true))
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                      child: _checkoutField(
                          'postalCode', '6-digit PIN', Icons.pin_drop_outlined,
                          required: true,
                          keyboard: TextInputType.number,
                          maxLength: 6)),
                  const SizedBox(width: 9),
                  Expanded(
                      child: _checkoutField('landmark', 'Landmark (optional)',
                          Icons.near_me_outlined))
                ]),
                if (_pinStatus.isNotEmpty)
                  Padding(
                      padding: const EdgeInsets.only(top: 4, left: 4),
                      child: Text(_pinStatus,
                          style: const TextStyle(color: _muted, fontSize: 11))),
                const SizedBox(height: 23),
                const _Eyebrow('Payment method'),
                const SizedBox(height: 8),
                _PaymentOption(
                    value: 'online',
                    group: _paymentMethod,
                    title: 'Pay online',
                    subtitle: 'UPI, cards & more · Save 10%',
                    icon: Icons.credit_card_rounded,
                    onChanged: (v) => setState(() => _paymentMethod = v)),
                const SizedBox(height: 9),
                _PaymentOption(
                    value: 'cod',
                    group: _paymentMethod,
                    title: 'Cash on Delivery',
                    subtitle: 'Pay when your order arrives · ₹20 fee',
                    icon: Icons.payments_outlined,
                    onChanged: (v) => setState(() => _paymentMethod = v)),
                const SizedBox(height: 18),
                Card(
                    child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(children: [
                          _priceRow('Items subtotal', money(subtotal)),
                          if (discount > 0) ...[
                            const SizedBox(height: 7),
                            _priceRow(
                                'Online payment savings', '−${money(discount)}',
                                color: const Color(0xFF50755D))
                          ],
                          if (cod > 0) ...[
                            const SizedBox(height: 7),
                            _priceRow('COD fee', money(cod))
                          ],
                          const Padding(
                              padding: EdgeInsets.symmetric(vertical: 11),
                              child: Divider(height: 1)),
                          _priceRow('Total', money(total), bold: true),
                        ]))),
                if (_status.isNotEmpty)
                  Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(_status,
                          style: const TextStyle(color: _wine, fontSize: 13))),
                const SizedBox(height: 14),
                FilledButton.icon(
                    onPressed: _working ? null : _placeOrder,
                    icon: _working
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.lock_outline),
                    label: Text(_working
                        ? 'Please wait…'
                        : 'Place order · ${money(total)}')),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                    onPressed: () => _openWhatsApp(context,
                        'Hello Ajiomart, I need help with my cart: ${api.cart.map((item) => '${item.quantity} x ${item.product.name}').join(', ')}. Total ${money(total)}.'),
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Need help? WhatsApp us')),
                const SizedBox(height: 9),
                const Text(
                    'Your account and payment are protected by Supabase and Razorpay.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _muted, fontSize: 11)),
              ])),
    );
  }

  Widget _checkoutField(String key, String label, IconData icon,
          {bool required = false, TextInputType? keyboard, int? maxLength}) =>
      TextFormField(
        controller: _controllers[key],
        onChanged: key == 'postalCode' ? _lookupPin : null,
        keyboardType: keyboard,
        maxLength: maxLength,
        textCapitalization: key == 'postalCode' || key == 'customerPhone'
            ? TextCapitalization.none
            : TextCapitalization.words,
        decoration: InputDecoration(
            labelText: label, prefixIcon: Icon(icon), counterText: ''),
        validator: (value) {
          final input = (value ?? '').trim();
          if (required && input.isEmpty) return 'Required';
          if (key == 'postalCode' &&
              input.isNotEmpty &&
              !RegExp(r'^\d{6}$').hasMatch(input)) return 'Enter a 6-digit PIN';
          if (key == 'customerPhone' &&
              input.isNotEmpty &&
              !RegExp(r'^[6-9]\d{9}$').hasMatch(input)) {
            return 'Enter a valid mobile number';
          }
          return null;
        },
      );

  void _lookupPin(String value) {
    _pinLookup?.cancel();
    final pin = value.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
      setState(() => _pinStatus = '');
      return;
    }
    setState(() => _pinStatus = 'Checking PIN code…');
    _pinLookup = Timer(const Duration(milliseconds: 350), () async {
      try {
        final response = await http
            .get(Uri.https('api.pincodeapi.in', '/api/v1/pincode/$pin'))
            .timeout(const Duration(seconds: 8));
        if (response.statusCode != 200) throw const FormatException();
        final payload = jsonDecode(response.body);
        final data = payload is Map ? payload['data'] : null;
        final offices = data is Map && data['post_offices'] is List
            ? (data['post_offices'] as List).whereType<Map>().toList()
            : <Map>[];
        if (payload is! Map || payload['success'] != true || offices.isEmpty) {
          if (mounted && _controllers['postalCode']!.text.trim() == pin) {
            setState(() => _pinStatus =
                'PIN code not found. Enter city and state manually.');
          }
          return;
        }
        final office = offices.firstWhere(
            (item) => item['delivery_status'] == 'Delivery',
            orElse: () => offices.first);
        final city = '${office['district'] ?? ''}';
        final stateName = '${office['state'] ?? ''}';
        if (!mounted || _controllers['postalCode']!.text.trim() != pin) return;
        if (city.isNotEmpty) _controllers['city']!.text = city;
        if (stateName.isNotEmpty) _controllers['state']!.text = stateName;
        setState(() => _pinStatus =
            [city, stateName].where((part) => part.isNotEmpty).join(', '));
      } catch (_) {
        if (mounted && _controllers['postalCode']!.text.trim() == pin) {
          setState(() => _pinStatus =
              'Could not look up this PIN. Enter city and state manually.');
        }
      }
    });
  }

  Map<String, String> _shipping() =>
      _controllers.map((key, value) => MapEntry(key, value.text.trim()));

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
    final api = StoreScope.of(context);
    setState(() {
      _working = true;
      _status = _paymentMethod == 'online'
          ? 'Preparing secure online payment…'
          : 'Placing your order…';
    });
    try {
      if (_paymentMethod == 'cod') {
        final order = await api.placeCodOrder(_shipping());
        if (mounted) await _showOrderSuccess(order);
        return;
      }
      final checkout = await api.startOnlinePayment(_shipping());
      _lastSessionId = '${checkout['sessionId'] ?? ''}';
      if (_lastSessionId.isEmpty) {
        throw const FormatException(
            'Payment session was not created. Try checkout again.');
      }
      final subtotalPaise = (api.cartSubtotal * 100).round();
      final expectedAmount = subtotalPaise - (subtotalPaise * .1).round();
      if (int.tryParse('${checkout['amount']}') != expectedAmount) {
        throw const FormatException(
            'Secure payment total does not match your cart. Refresh the cart and try again.');
      }
      setState(() => _status = 'Opening Razorpay checkout…');
      _razorpay.open({
        'key': checkout['keyId'],
        'order_id': checkout['orderId'],
        'amount': checkout['amount'],
        'currency': checkout['currency'] ?? 'INR',
        'name': 'Ajiomart',
        'description': 'Fashion, beauty, and accessories order',
        'prefill': {
          'name': _controllers['customerName']!.text,
          'email': api.user?.email ?? '',
          'contact': _controllers['customerPhone']!.text
        },
        'theme': {'color': '#8D344B'},
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _working = false;
          _status = error
              .toString()
              .replaceFirst('FormatException: ', '')
              .replaceFirst('FunctionException: ', '');
        });
      }
    }
  }

  Future<void> _paymentSuccess(PaymentSuccessResponse response) async {
    final api = StoreScope.of(context);
    setState(() => _status = 'Verifying payment securely…');
    try {
      final order = await api.verifyOnlinePayment({
        'sessionId': _lastSessionId,
        'razorpay_order_id': response.orderId,
        'razorpay_payment_id': response.paymentId,
        'razorpay_signature': response.signature,
      });
      if (mounted) await _showOrderSuccess(order);
    } catch (error) {
      if (mounted) {
        setState(() {
          _working = false;
          _status = 'Payment confirmation needs another try: $error';
        });
      }
    }
  }

  String _lastSessionId = '';

  void _paymentFailure(PaymentFailureResponse response) {
    if (!mounted) return;
    setState(() {
      _working = false;
      _status = response.message?.isNotEmpty == true
          ? response.message!
          : 'Payment was not completed. You can retry checkout.';
    });
  }

  void _externalWallet(ExternalWalletResponse response) {
    if (mounted) {
      setState(() => _status =
          'Selected wallet: ${response.walletName ?? 'External wallet'}');
    }
  }

  Future<void> _showOrderSuccess(AjiOrder order) async {
    if (!mounted) return;
    setState(() {
      _working = false;
      _status = '';
    });
    await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
              icon: const Icon(Icons.check_circle_outline,
                  color: Color(0xFF50755D), size: 42),
              title: const Text('Order placed'),
              content: Text(
                  'Your order ${order.id.substring(0, order.id.length > 8 ? 8 : order.id.length)} is confirmed. We’ll keep you updated.'),
              actions: [
                FilledButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Done'))
              ],
            ));
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
          context, '/orders', (route) => route.settings.name == '/');
    }
  }
}

class _PaymentOption extends StatelessWidget {
  const _PaymentOption(
      {required this.value,
      required this.group,
      required this.title,
      required this.subtitle,
      required this.icon,
      required this.onChanged});
  final String value;
  final String group;
  final String title;
  final String subtitle;
  final IconData icon;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => onChanged(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
          decoration: BoxDecoration(
              color: group == value ? const Color(0xFFFFF5F7) : Colors.white,
              border: Border.all(color: group == value ? _wine : _line),
              borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            Radio<String>(
                value: value,
                groupValue: group,
                onChanged: (v) {
                  if (v != null) onChanged(v);
                },
                activeColor: _wine),
            Icon(icon, color: _wine, size: 21),
            const SizedBox(width: 11),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, color: _ink)),
                  Text(subtitle,
                      style: const TextStyle(fontSize: 11, color: _muted))
                ]))
          ]),
        ),
      );
}

Widget _priceRow(String title, String value,
        {bool bold = false, Color? color}) =>
    Row(children: [
      Expanded(
          child: Text(title,
              style: TextStyle(
                  color: color ?? (bold ? _ink : _muted),
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w500))),
      Text(value,
          style: TextStyle(
              color: color ?? _ink,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              fontSize: bold ? 16 : 13))
    ]);

class AccountTab extends StatelessWidget {
  const AccountTab({super.key});
  @override
  Widget build(BuildContext context) {
    final api = StoreScope.of(context);
    final user = api.user;
    if (user == null) {
      return _EmptyState(
          icon: Icons.person_outline,
          title: 'The best of Ajiomart, together',
          message:
              'Sign in for saved favourites, faster checkout, and order updates.',
          button: 'Sign in / Create account',
          onPressed: () => Navigator.pushNamed(context, '/auth'));
    }
    return ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
        children: [
          const _Eyebrow('Your account'),
          const SizedBox(height: 4),
          Text(
              'Hello, ${user.name.isEmpty ? 'there' : user.name.split(' ').first}.',
              style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 5),
          Text(user.email, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 19),
          Card(
              child: Column(children: [
            _AccountAction(
                icon: Icons.receipt_long_outlined,
                title: 'My orders',
                subtitle: 'Status, delivery, and payment',
                onTap: () => Navigator.pushNamed(context, '/orders')),
            const Divider(height: 1, indent: 58),
            _AccountAction(
                icon: Icons.favorite_border,
                title: 'Wishlist',
                subtitle: 'Your saved pieces',
                onTap: () => _goTab(context, 2)),
            const Divider(height: 1, indent: 58),
            _AccountAction(
                icon: Icons.policy_outlined,
                title: 'Privacy policy',
                subtitle: 'How your information is used',
                onTap: () => Navigator.pushNamed(context, '/privacy')),
            if (user.isAdmin) ...[
              const Divider(height: 1, indent: 58),
              _AccountAction(
                  icon: Icons.dashboard_outlined,
                  title: 'Admin dashboard',
                  subtitle: 'Products, orders, shipping, sales',
                  onTap: () => Navigator.pushNamed(context, '/admin')),
            ],
          ])),
          const SizedBox(height: 18),
          Card(
              child: Column(children: [
            _AccountAction(
                icon: Icons.chat_bubble_outline,
                title: 'WhatsApp support',
                subtitle: '+91 $_storePhone',
                onTap: () =>
                    _openWhatsApp(context, 'Hello Ajiomart, I need help.')),
            const Divider(height: 1, indent: 58),
            _AccountAction(
                icon: Icons.phone_outlined,
                title: 'Call Ajiomart',
                subtitle: '+91 $_storePhone',
                onTap: () => launchUrl(Uri.parse('tel:+91$_storePhone'))),
          ])),
          const SizedBox(height: 12),
          OutlinedButton.icon(
              onPressed: () async {
                await api.signOut();
                if (context.mounted) {
                  _notice(context, 'You have been signed out.');
                }
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign out')),
          const SizedBox(height: 9),
          TextButton(
              onPressed: () => _confirmDeleteAccount(context, api),
              child:
                  const Text('Delete account', style: TextStyle(color: _wine))),
        ]);
  }
}

class _AccountAction extends StatelessWidget {
  const _AccountAction(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
      leading: Icon(icon, color: _wine),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w700, color: _ink)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap);
}

Future<void> _confirmDeleteAccount(
    BuildContext context, AjiStoreApi api) async {
  final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
            title: const Text('Delete your account?'),
            content: const Text(
                'This signs you out. Permanent Supabase account deletion requires a server-side admin function, just like the website.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel')),
              FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Continue'))
            ],
          ));
  if (confirmed == true) {
    await api.deleteAccountSession();
    if (context.mounted) {
      _notice(context,
          'You have been signed out. Contact support for permanent account deletion.');
    }
  }
}

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final api = StoreScope.of(context);
    if (api.user == null) {
      return Scaffold(
          appBar: AppBar(title: const Text('My orders')),
          body: _EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Sign in to see your orders',
              message: 'Your order history follows your account.',
              button: 'Sign in',
              onPressed: () => Navigator.pushNamed(context, '/auth')));
    }
    final orders =
        api.orders.where((order) => order.userId == api.user!.id).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('My orders'), actions: [
        IconButton(
            onPressed: api.refreshOrders,
            tooltip: 'Refresh orders',
            icon: const Icon(Icons.refresh_rounded))
      ]),
      body: api.ordersLoading && orders.isEmpty
          ? const Center(child: CircularProgressIndicator(color: _wine))
          : orders.isEmpty
              ? const _EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'No orders yet',
                  message: 'Once you checkout, your orders will show here.')
              : RefreshIndicator(
                  color: _wine,
                  onRefresh: api.refreshOrders,
                  child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                      itemCount: orders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) =>
                          _CustomerOrderCard(order: orders[index]))),
    );
  }
}

class _CustomerOrderCard extends StatelessWidget {
  const _CustomerOrderCard({required this.order});
  final AjiOrder order;
  @override
  Widget build(BuildContext context) {
    final api = StoreScope.of(context);
    final timeline = order.status == 'cancelled'
        ? ['cancelled']
        : orderStatuses.where((status) => status != 'cancelled').toList();
    final currentIndex = timeline.indexOf(order.status);
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(15),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(order.paymentMethod.toUpperCase(),
                          style: const TextStyle(
                              color: _wine,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.3)),
                      const SizedBox(height: 4),
                      Text(money(order.total),
                          style: const TextStyle(
                              color: _ink,
                              fontSize: 22,
                              fontWeight: FontWeight.w800)),
                      Text(
                          order.createdAt == null
                              ? 'Order #${order.id.substring(0, 8)}'
                              : '${order.createdAt!.day}/${order.createdAt!.month}/${order.createdAt!.year} · #${order.id.substring(0, 8)}',
                          style: const TextStyle(color: _muted, fontSize: 11)),
                    ])),
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                        color: const Color(0xFFF2E9E5),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(prettyStatus(order.status),
                        style: const TextStyle(
                            color: _wine,
                            fontWeight: FontWeight.w700,
                            fontSize: 11))),
              ]),
              const SizedBox(height: 12),
              _priceRow('Items subtotal', money(order.subtotal)),
              if (order.discount > 0) ...[
                const SizedBox(height: 4),
                _priceRow('Online payment savings', '−${money(order.discount)}',
                    color: const Color(0xFF50755D))
              ],
              if (order.codCharges > 0) ...[
                const SizedBox(height: 4),
                _priceRow('COD fee', money(order.codCharges))
              ],
              const Divider(height: 21),
              ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(children: [
                    ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                            width: 44,
                            height: 50,
                            child: _ProductImage(url: item.imageUrl))),
                    const SizedBox(width: 9),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: _ink,
                                  fontSize: 12)),
                          Text(
                              '${item.quantity} × ${money(item.price)} · ${item.color} · ${item.size}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  const TextStyle(color: _muted, fontSize: 10))
                        ])),
                  ]))),
              Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: const Color(0xFFF7F1ED),
                      borderRadius: BorderRadius.circular(13)),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.local_shipping_outlined,
                              color: _wine, size: 18),
                          const SizedBox(width: 7),
                          Expanded(
                              child: Text(order.courierPartner,
                                  style: const TextStyle(
                                      color: _ink,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12))),
                          Text(prettyStatus(order.status),
                              style: const TextStyle(
                                  color: _wine,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10))
                        ]),
                        const SizedBox(height: 6),
                        Text(
                            order.trackingNote.isEmpty
                                ? 'Tracking details will appear once your order is packed.'
                                : order.trackingNote,
                            style:
                                const TextStyle(color: _muted, fontSize: 11)),
                        if (order.trackingNumber.isNotEmpty)
                          Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                  'Tracking no. ${order.trackingNumber}',
                                  style: const TextStyle(
                                      color: _ink,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600))),
                        if (order.delhiveryStatus.isNotEmpty)
                          Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                  'Delhivery · ${order.delhiveryStatus}',
                                  style: const TextStyle(
                                      color: _wine,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700))),
                        if (order.trackingEvents.isNotEmpty) ...[
                          const SizedBox(height: 7),
                          ...order.trackingEvents.take(5).map((event) =>
                              Padding(
                                  padding: const EdgeInsets.only(top: 5),
                                  child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('•  ',
                                            style: TextStyle(
                                                color: _wine,
                                                fontWeight: FontWeight.w900)),
                                        Expanded(
                                            child: Text(
                                                [
                                                  event['status'],
                                                  event['location'],
                                                  event['details'],
                                                  event['at']
                                                ]
                                                    .where((value) =>
                                                        value != null &&
                                                        '$value'.isNotEmpty)
                                                    .join(' · '),
                                                style: const TextStyle(
                                                    color: _muted,
                                                    fontSize: 10)))
                                      ]))),
                        ],
                        const SizedBox(height: 8),
                        Wrap(spacing: 6, runSpacing: 6, children: [
                          if (order.trackingNumber.isNotEmpty &&
                              order.courierPartner == 'Delhivery')
                            OutlinedButton.icon(
                                onPressed: () => _refreshTracking(context, api),
                                icon:
                                    const Icon(Icons.refresh_rounded, size: 15),
                                label: const Text('Refresh tracking')),
                          if (order.trackingUrl.isNotEmpty)
                            OutlinedButton.icon(
                                onPressed: () =>
                                    _openUrl(context, order.trackingUrl),
                                icon: const Icon(Icons.open_in_new, size: 15),
                                label: const Text('Track package')),
                        ]),
                      ])),
              const SizedBox(height: 12),
              Row(
                  children: timeline.map((status) {
                final index = timeline.indexOf(status);
                final active =
                    order.status == 'cancelled' || index <= currentIndex;
                return Expanded(
                    child: Column(children: [
                  Row(children: [
                    Expanded(
                        child: Container(
                            height: 2,
                            color: index == 0
                                ? Colors.transparent
                                : active
                                    ? _wine
                                    : _line)),
                    Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                            color: active ? _wine : _line,
                            shape: BoxShape.circle)),
                    Expanded(
                        child: Container(
                            height: 2,
                            color: index == timeline.length - 1
                                ? Colors.transparent
                                : active && index < currentIndex
                                    ? _wine
                                    : _line))
                  ]),
                  const SizedBox(height: 4),
                  Text(prettyStatus(status),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: active ? _wine : _muted,
                          fontSize: 8,
                          fontWeight:
                              active ? FontWeight.w700 : FontWeight.w400)),
                ]));
              }).toList()),
            ])));
  }

  Future<void> _refreshTracking(BuildContext context, AjiStoreApi api) async {
    try {
      final result = await api.refreshDelhiveryTracking(order.id);
      if (context.mounted) {
        _notice(context,
            'Tracking updated: ${result['status'] ?? 'latest scan received'}.');
      }
    } catch (error) {
      if (context.mounted) _notice(context, error.toString());
    }
  }
}

Future<void> _openUrl(BuildContext context, String rawUrl) async {
  final uri = Uri.tryParse(rawUrl);
  if (uri == null ||
      !(await launchUrl(uri, mode: LaunchMode.externalApplication))) {
    if (context.mounted) _notice(context, 'Could not open this tracking link.');
  }
}

Future<void> _openWhatsApp(BuildContext context, String message) async {
  final uri = Uri.https('wa.me', '/$_storeWhatsApp', {'text': message});
  if (!(await launchUrl(uri, mode: LaunchMode.externalApplication)) &&
      context.mounted) {
    _notice(context, 'Could not open WhatsApp. Call +91 $_storePhone instead.');
  }
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Privacy policy')),
      body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
          children: const [
            _Eyebrow('Ajiomart'),
            SizedBox(height: 6),
            Text('Your privacy matters.',
                style: TextStyle(
                    color: _ink, fontSize: 27, fontWeight: FontWeight.w700)),
            SizedBox(height: 14),
            Text(
                'Ajiomart uses the information you provide to manage your account, keep your cart and wishlist available, process orders, arrange delivery, and help with customer support. Account and order data are stored in Supabase. Product images are served from Supabase Storage.',
                style: TextStyle(color: _muted, height: 1.6)),
            SizedBox(height: 16),
            Text('Payments',
                style: TextStyle(
                    color: _ink, fontWeight: FontWeight.w800, fontSize: 16)),
            SizedBox(height: 5),
            Text(
                'Online payments are processed by Razorpay. Ajiomart uses its secured server functions to verify payment details before confirming an order. The app does not store card or UPI credentials.',
                style: TextStyle(color: _muted, height: 1.6)),
            SizedBox(height: 16),
            Text('Delivery and account requests',
                style: TextStyle(
                    color: _ink, fontWeight: FontWeight.w800, fontSize: 16)),
            SizedBox(height: 5),
            Text(
                'Shipping details are shared with the courier to deliver your order. You can sign out from your account screen. Permanent account deletion requires a server-side deletion service; contact Ajiomart support to request it.',
                style: TextStyle(color: _muted, height: 1.6)),
            SizedBox(height: 16),
            Text('Data protection',
                style: TextStyle(
                    color: _ink, fontWeight: FontWeight.w800, fontSize: 16)),
            SizedBox(height: 5),
            Text(
                'Supabase Row Level Security limits account carts and orders to their owner and gives admins the access required to fulfil orders. Do not share your password or payment verification codes.',
                style: TextStyle(color: _muted, height: 1.6)),
          ]));
}

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final api = StoreScope.of(context);
    if (api.user?.isAdmin != true) {
      return Scaffold(
          appBar: AppBar(title: const Text('Admin dashboard')),
          body: const _EmptyState(
              icon: Icons.lock_outline,
              title: 'Admin access only',
              message:
                  'Sign in with an Ajiomart admin account to open the dashboard.'));
    }
    final stock =
        api.products.fold<int>(0, (sum, product) => sum + product.stock);
    final revenue =
        api.orders.fold<double>(0, (sum, order) => sum + order.total);
    return DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ajiomart Dashboard',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  Text('ADMIN',
                      style: TextStyle(
                          fontSize: 9,
                          color: _wine,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w800))
                ]),
            actions: [
              IconButton(
                  onPressed: () async {
                    await Future.wait([
                      api.refreshProducts(),
                      api.refreshOrders(),
                      api.refreshCustomers()
                    ]);
                  },
                  tooltip: 'Refresh dashboard',
                  icon: const Icon(Icons.refresh_rounded))
            ],
            bottom: const TabBar(tabs: [
              Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Catalog'),
              Tab(icon: Icon(Icons.receipt_long_outlined), text: 'Orders'),
              Tab(icon: Icon(Icons.insights_outlined), text: 'Overview')
            ]),
          ),
          body: TabBarView(children: [
            _AdminCatalogTab(products: api.products),
            _AdminOrdersTab(orders: api.orders),
            _AdminOverviewTab(
                products: api.products,
                orders: api.orders,
                customers: api.customers,
                stock: stock,
                revenue: revenue),
          ]),
        ));
  }
}

class _AdminCatalogTab extends StatelessWidget {
  const _AdminCatalogTab({required this.products});
  final List<ShopProduct> products;
  @override
  Widget build(BuildContext context) {
    final api = StoreScope.of(context);
    return Column(children: [
      Padding(
          padding: const EdgeInsets.fromLTRB(16, 13, 16, 8),
          child: Row(children: [
            Expanded(
                child: Text(
                    '${products.length} products · ${products.fold<int>(0, (sum, product) => sum + product.stock)} units in stock',
                    style: const TextStyle(color: _muted, fontSize: 12))),
            FilledButton.icon(
                onPressed: () => _openProductEditor(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add product'))
          ])),
      Expanded(
          child: products.isEmpty
              ? const _EmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'No products yet',
                  message: 'Add your first Ajiomart product.')
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 9),
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return Card(
                        child: Padding(
                            padding: const EdgeInsets.all(9),
                            child: Row(children: [
                              ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: SizedBox(
                                      width: 73,
                                      height: 88,
                                      child: _ProductImage(
                                          url: product.imageUrl))),
                              const SizedBox(width: 11),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text(product.category.toUpperCase(),
                                        style: const TextStyle(
                                            color: _wine,
                                            fontSize: 9,
                                            letterSpacing: 1.1,
                                            fontWeight: FontWeight.w800)),
                                    const SizedBox(height: 3),
                                    Text(product.name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            color: _ink,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13)),
                                    const SizedBox(height: 5),
                                    Text(
                                        '${money(product.price)} · Stock ${product.stock}',
                                        style: const TextStyle(
                                            color: _muted, fontSize: 11)),
                                    if (product.badge.isNotEmpty)
                                      Text(product.badge,
                                          style: const TextStyle(
                                              color: _muted, fontSize: 10))
                                  ])),
                              PopupMenuButton<String>(
                                  onSelected: (value) async {
                                    if (value == 'edit') {
                                      await _openProductEditor(context,
                                          product: product);
                                      return;
                                    }
                                    if (value == 'delete' && context.mounted) {
                                      await _deleteProduct(
                                          context, api, product);
                                    }
                                  },
                                  itemBuilder: (_) => const [
                                        PopupMenuItem(
                                            value: 'edit',
                                            child: Text('Edit product')),
                                        PopupMenuItem(
                                            value: 'delete',
                                            child: Text('Delete product'))
                                      ]),
                            ])));
                  })),
    ]);
  }
}

Future<void> _openProductEditor(BuildContext context,
    {ShopProduct? product}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: const Color(0xFFFCF9F6),
    builder: (_) => _ProductEditor(product: product),
  );
}

Future<void> _deleteProduct(
    BuildContext context, AjiStoreApi api, ShopProduct product) async {
  final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
            title: const Text('Delete product?'),
            content: Text('Remove “${product.name}” from the storefront?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel')),
              FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Delete'))
            ],
          ));
  if (confirmed != true) return;
  try {
    await api.deleteProduct(product.id);
    if (context.mounted) _notice(context, 'Product removed.');
  } catch (error) {
    if (context.mounted) _notice(context, error.toString());
  }
}

class _ProductEditor extends StatefulWidget {
  const _ProductEditor({this.product});
  final ShopProduct? product;
  @override
  State<_ProductEditor> createState() => _ProductEditorState();
}

class _ProductEditorState extends State<_ProductEditor> {
  final _form = GlobalKey<FormState>();
  final _picker = ImagePicker();
  late final Map<String, TextEditingController> _fields;
  late String _category;
  late List<String> _imageUrls;
  final List<XFile> _newImages = [];
  bool _working = false;
  String _status = '';

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _category = product?.category ?? 'Dresses';
    _imageUrls = [...?product?.imageUrls];
    _fields = {
      'name': TextEditingController(text: product?.name ?? ''),
      'price':
          TextEditingController(text: product?.price.toStringAsFixed(0) ?? ''),
      'originalPrice': TextEditingController(
          text: product?.originalPrice.toStringAsFixed(0) ?? ''),
      'stock': TextEditingController(text: '${product?.stock ?? 1}'),
      'rating': TextEditingController(text: '${product?.rating ?? 4.5}'),
      'badge': TextEditingController(text: product?.badge ?? ''),
      'colors': TextEditingController(
          text: product?.colors.join(', ') ?? 'Black, Ivory'),
      'sizes':
          TextEditingController(text: product?.sizes.join(', ') ?? 'S, M, L'),
      'description': TextEditingController(text: product?.description ?? ''),
      'hsnCode': TextEditingController(text: product?.hsnCode ?? ''),
    };
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(
            left: 18,
            right: 18,
            top: 16,
            bottom: MediaQuery.viewInsetsOf(context).bottom + 18),
        child: Form(
            key: _form,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                Expanded(
                    child: Text(
                        widget.product == null ? 'Add product' : 'Edit product',
                        style: Theme.of(context).textTheme.headlineMedium)),
                IconButton(
                    onPressed: _working ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close))
              ]),
              Flexible(
                  child: ListView(
                      padding: const EdgeInsets.only(top: 9, bottom: 10),
                      shrinkWrap: true,
                      children: [
                    _editorField('name', 'Product name', required: true),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(
                          child: _editorField('price', 'Price (₹)',
                              keyboard: TextInputType.number, required: true)),
                      const SizedBox(width: 9),
                      Expanded(
                          child: _editorField('originalPrice', 'Original price',
                              keyboard: TextInputType.number))
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(
                          child: DropdownButtonFormField<String>(
                              value: _category,
                              decoration:
                                  const InputDecoration(labelText: 'Category'),
                              items: productCategories
                                  .map((category) => DropdownMenuItem(
                                      value: category, child: Text(category)))
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _category = value);
                                }
                              })),
                      const SizedBox(width: 9),
                      Expanded(
                          child: _editorField('stock', 'Stock',
                              keyboard: TextInputType.number, required: true))
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: _editorField('badge', 'Badge')),
                      const SizedBox(width: 9),
                      Expanded(
                          child: _editorField('rating', 'Rating (1–5)',
                              keyboard: const TextInputType.numberWithOptions(
                                  decimal: true)))
                    ]),
                    const SizedBox(height: 10),
                    _editorField(
                        'colors', 'Colours / shades (comma separated)'),
                    const SizedBox(height: 10),
                    _editorField(
                        'sizes', 'Sizes / pack names (comma separated)'),
                    const SizedBox(height: 10),
                    _editorField('description', 'Description',
                        required: true, lines: 3),
                    const SizedBox(height: 10),
                    _editorField('hsnCode', 'HSN code (Delhivery)',
                        keyboard: TextInputType.number),
                    const SizedBox(height: 13),
                    Row(children: [
                      const Expanded(
                          child: Text('Product images · up to 6',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, color: _ink))),
                      TextButton.icon(
                          onPressed: _working ? null : _pickImages,
                          icon: const Icon(Icons.add_photo_alternate_outlined),
                          label: const Text('Add'))
                    ]),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      ..._imageUrls.map((url) => _imagePreview(
                          _ProductImage(url: url),
                          () => setState(() => _imageUrls.remove(url)))),
                      ..._newImages.map((file) => FutureBuilder<Uint8List>(
                            future: file.readAsBytes(),
                            builder: (_, snapshot) => _imagePreview(
                              snapshot.hasData
                                  ? Image.memory(snapshot.data!,
                                      fit: BoxFit.cover)
                                  : const _ImagePlaceholder(),
                              () => setState(() => _newImages.remove(file)),
                            ),
                          )),
                    ]),
                    if (_status.isNotEmpty)
                      Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(_status,
                              style:
                                  const TextStyle(color: _wine, fontSize: 12))),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                        onPressed: _working ? null : _save,
                        icon: _working
                            ? const SizedBox(
                                width: 17,
                                height: 17,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.save_outlined),
                        label: Text(_working ? 'Saving…' : 'Save product')),
                  ])),
            ])),
      );

  Widget _editorField(String field, String label,
          {bool required = false, TextInputType? keyboard, int lines = 1}) =>
      TextFormField(
        controller: _fields[field],
        keyboardType: keyboard,
        maxLines: lines,
        decoration:
            InputDecoration(labelText: label, alignLabelWithHint: lines > 1),
        validator: (value) =>
            required && (value ?? '').trim().isEmpty ? 'Required' : null,
      );

  Widget _imagePreview(Widget image, VoidCallback remove) => Stack(children: [
        ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: SizedBox(width: 70, height: 82, child: image)),
        Positioned(
            right: 0,
            top: 0,
            child: IconButton.filledTonal(
                onPressed: remove,
                visualDensity: VisualDensity.compact,
                iconSize: 14,
                constraints:
                    const BoxConstraints.tightFor(width: 25, height: 25),
                icon: const Icon(Icons.close))),
      ]);

  Future<void> _pickImages() async {
    final remaining = 6 - _imageUrls.length - _newImages.length;
    if (remaining <= 0) return;
    final images = await _picker.pickMultiImage(
        imageQuality: 85, maxWidth: 1800, limit: remaining);
    if (!mounted) return;
    setState(() {
      _newImages.addAll(images.take(remaining));
      _status =
          '${images.length} image${images.length == 1 ? '' : 's'} selected.';
    });
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_imageUrls.isEmpty && _newImages.isEmpty) {
      setState(() => _status = 'Add at least one product image.');
      return;
    }
    final api = StoreScope.of(context);
    setState(() {
      _working = true;
      _status = 'Uploading images and saving product…';
    });
    try {
      await api.saveProduct(
        id: widget.product?.id,
        name: _fields['name']!.text,
        category: _category,
        price: double.parse(_fields['price']!.text),
        originalPrice: double.tryParse(_fields['originalPrice']!.text) ??
            double.parse(_fields['price']!.text),
        stock: int.tryParse(_fields['stock']!.text) ?? 0,
        rating: double.tryParse(_fields['rating']!.text) ?? 4.5,
        badge: _fields['badge']!.text,
        colors: _splitList(_fields['colors']!.text),
        sizes: _splitList(_fields['sizes']!.text),
        description: _fields['description']!.text,
        hsnCode: _fields['hsnCode']!.text,
        existingImageUrls: _imageUrls,
        newImages: _newImages,
      );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        setState(() {
          _working = false;
          _status = error.toString().replaceFirst('PostgrestException: ', '');
        });
      }
    }
  }

  List<String> _splitList(String value) => value
      .split(',')
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();
}

class _AdminOrdersTab extends StatelessWidget {
  const _AdminOrdersTab({required this.orders});
  final List<AjiOrder> orders;
  @override
  Widget build(BuildContext context) => orders.isEmpty
      ? const _EmptyState(
          icon: Icons.receipt_long_outlined,
          title: 'No customer orders yet',
          message: 'Orders will appear here as customers checkout.')
      : ListView.separated(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 26),
          itemCount: orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) => _AdminOrderCard(
              key: ValueKey(orders[index].id), order: orders[index]));
}

class _AdminOrderCard extends StatefulWidget {
  const _AdminOrderCard({super.key, required this.order});
  final AjiOrder order;
  @override
  State<_AdminOrderCard> createState() => _AdminOrderCardState();
}

class _AdminOrderCardState extends State<_AdminOrderCard> {
  late final Map<String, TextEditingController> _fields;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final order = widget.order;
    _fields = {
      'packageWeightG':
          TextEditingController(text: order.packageWeightG?.toString() ?? ''),
      'packageLengthCm':
          TextEditingController(text: order.packageLengthCm?.toString() ?? ''),
      'packageWidthCm':
          TextEditingController(text: order.packageWidthCm?.toString() ?? ''),
      'packageHeightCm':
          TextEditingController(text: order.packageHeightCm?.toString() ?? ''),
      'eWaybill': TextEditingController(text: order.eWaybill),
      'courierPartner': TextEditingController(text: order.courierPartner),
      'trackingNumber': TextEditingController(text: order.trackingNumber),
      'trackingUrl': TextEditingController(text: order.trackingUrl),
      'trackingNote': TextEditingController(text: order.trackingNote),
    };
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final api = StoreScope.of(context);
    final order = widget.order;
    final address = order.address.values
        .where((value) => '$value'.trim().isNotEmpty)
        .join(', ');
    return Card(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('${money(order.total)} · ${order.paymentMethod}',
                      style: const TextStyle(
                          color: _ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 15)),
                  const SizedBox(height: 3),
                  Text('${order.customerName} · ${order.customerPhone}',
                      style: const TextStyle(color: _muted, fontSize: 11)),
                  Text(
                      'Order #${order.id.substring(0, order.id.length > 10 ? 10 : order.id.length)} · ${order.items.length} item(s)',
                      style: const TextStyle(color: _muted, fontSize: 10))
                ])),
            IconButton(
                onPressed: () => _delete(context, api, order),
                tooltip: 'Delete order',
                icon: const Icon(Icons.delete_outline, color: _wine)),
          ])),
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(address,
              style:
                  const TextStyle(color: _muted, fontSize: 11, height: 1.35))),
      Padding(
        padding: const EdgeInsets.fromLTRB(10, 5, 10, 4),
        child: DropdownButtonFormField<String>(
          value: orderStatuses.contains(order.status) ? order.status : 'placed',
          decoration: const InputDecoration(
              labelText: 'Order status',
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 9)),
          items: orderStatuses
              .map((status) => DropdownMenuItem(
                  value: status, child: Text(prettyStatus(status))))
              .toList(),
          onChanged: (status) async {
            if (status == null) return;
            try {
              await api.updateOrder(order.id, {'status': status});
            } catch (error) {
              if (context.mounted) _notice(context, error.toString());
            }
          },
        ),
      ),
      if (order.items.isNotEmpty)
        Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
            child: Column(
                children: order.items
                    .map((item) => Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(children: [
                          Expanded(
                              child: Text(
                                  '${item.quantity} × ${item.name} · ${item.color} / ${item.size}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: _muted, fontSize: 11))),
                          Text(money(item.price * item.quantity),
                              style: const TextStyle(
                                  color: _ink,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11))
                        ])))
                    .toList())),
      ExpansionTile(
          title: const Text('Shipping & tracking',
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: _ink, fontSize: 13)),
          subtitle: Text(order.delhiveryStatus.isNotEmpty
              ? 'Delhivery · ${order.delhiveryStatus}'
              : (order.trackingNumber.isNotEmpty
                  ? '${order.courierPartner} · ${order.trackingNumber}'
                  : 'Package details and courier updates')),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          children: [
            Wrap(spacing: 9, runSpacing: 9, children: [
              _adminField('packageWeightG', 'Weight (g)', number: true),
              _adminField('packageLengthCm', 'Length (cm)', number: true),
              _adminField('packageWidthCm', 'Width (cm)', number: true),
              _adminField('packageHeightCm', 'Height (cm)', number: true),
              _adminField('eWaybill', 'E-way bill'),
              _adminField('courierPartner', 'Courier partner'),
              _adminField('trackingNumber', 'Tracking number'),
              _adminField('trackingUrl', 'Tracking URL'),
              _adminField('trackingNote', 'Customer tracking note'),
            ]),
            const SizedBox(height: 11),
            Wrap(spacing: 7, runSpacing: 7, children: [
              FilledButton.icon(
                  onPressed: _saving ? null : () => _saveTracking(context, api),
                  icon: const Icon(Icons.save_outlined, size: 17),
                  label: const Text('Save shipping details')),
              if (order.trackingNumber.isEmpty)
                OutlinedButton.icon(
                    onPressed: _saving || order.status == 'cancelled'
                        ? null
                        : () => _createShipment(context, api),
                    icon: const Icon(Icons.local_shipping_outlined, size: 17),
                    label: const Text('Create Delhivery shipment')),
              if (order.trackingNumber.isNotEmpty &&
                  order.courierPartner == 'Delhivery')
                OutlinedButton.icon(
                    onPressed:
                        _saving ? null : () => _refreshTracking(context, api),
                    icon: const Icon(Icons.refresh_rounded, size: 17),
                    label: const Text('Refresh tracking')),
            ]),
          ]),
    ]));
  }

  Widget _adminField(String key, String label, {bool number = false}) =>
      SizedBox(
          width: MediaQuery.sizeOf(context).width > 430
              ? (MediaQuery.sizeOf(context).width - 76) / 2
              : double.infinity,
          child: TextField(
              controller: _fields[key],
              keyboardType: number
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.text,
              decoration: InputDecoration(labelText: label, isDense: true)));

  Future<void> _saveTracking(BuildContext context, AjiStoreApi api) async {
    setState(() => _saving = true);
    try {
      await api.updateOrder(
          widget.order.id,
          _fields
              .map((key, controller) => MapEntry(key, controller.text.trim())));
      if (context.mounted) _notice(context, 'Shipping details saved.');
    } catch (error) {
      if (context.mounted) _notice(context, error.toString());
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _createShipment(BuildContext context, AjiStoreApi api) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
                title: const Text('Create live shipment?'),
                content: Text(
                    'Create a Delhivery shipment for order ${widget.order.id.substring(0, 10)}?'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: const Text('Create shipment'))
                ]));
    if (confirmed != true) return;
    setState(() => _saving = true);
    try {
      await api.updateOrder(
          widget.order.id,
          _fields
              .map((key, controller) => MapEntry(key, controller.text.trim())));
      final result = await api.createDelhiveryShipment(widget.order.id);
      if (context.mounted) {
        _notice(context, 'Shipment created. AWB ${result['waybill'] ?? ''}');
      }
    } catch (error) {
      if (context.mounted) _notice(context, error.toString());
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _refreshTracking(BuildContext context, AjiStoreApi api) async {
    setState(() => _saving = true);
    try {
      final result = await api.refreshDelhiveryTracking(widget.order.id);
      if (context.mounted) {
        _notice(context,
            'Tracking updated: ${result['status'] ?? 'latest scan received'}.');
      }
    } catch (error) {
      if (context.mounted) _notice(context, error.toString());
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _delete(
      BuildContext context, AjiStoreApi api, AjiOrder order) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
                title: const Text('Delete this order?'),
                content: const Text(
                    'This removes the order record and its line items.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: const Text('Delete'))
                ]));
    if (confirmed != true) return;
    try {
      await api.deleteOrder(order.id);
      if (context.mounted) _notice(context, 'Order deleted.');
    } catch (error) {
      if (context.mounted) _notice(context, error.toString());
    }
  }
}

class _AdminOverviewTab extends StatelessWidget {
  const _AdminOverviewTab(
      {required this.products,
      required this.orders,
      required this.customers,
      required this.stock,
      required this.revenue});
  final List<ShopProduct> products;
  final List<AjiOrder> orders;
  final List<AjiUser> customers;
  final int stock;
  final double revenue;
  @override
  Widget build(BuildContext context) {
    final average = orders.isEmpty ? 0.0 : revenue / orders.length;
    return ListView(
        padding: const EdgeInsets.fromLTRB(16, 13, 16, 24),
        children: [
          const _Eyebrow('Store performance'),
          const SizedBox(height: 5),
          const Text('Ajiomart overview',
              style: TextStyle(
                  color: _ink, fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 13),
          Wrap(spacing: 10, runSpacing: 10, children: [
            _MetricCard(
                icon: Icons.people_alt_outlined,
                title: 'Customers',
                value: '${customers.length}',
                caption: 'Registered profiles'),
            _MetricCard(
                icon: Icons.inventory_2_outlined,
                title: 'Products',
                value: '${products.length}',
                caption: '$stock units available'),
            _MetricCard(
                icon: Icons.receipt_long_outlined,
                title: 'Orders',
                value: '${orders.length}',
                caption: 'All order records'),
            _MetricCard(
                icon: Icons.currency_rupee,
                title: 'Revenue',
                value: money(revenue),
                caption: 'Average order ${money(average)}'),
          ]),
          const SizedBox(height: 17),
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Recent orders',
                            style: TextStyle(
                                color: _ink,
                                fontSize: 16,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        if (orders.isEmpty)
                          const Text('Orders will appear here after checkout.',
                              style: TextStyle(color: _muted, fontSize: 12)),
                        ...orders.take(5).map((order) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            child: Row(children: [
                              Expanded(
                                  child: Text(
                                      '${order.customerName} · ${prettyStatus(order.status)}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: _ink, fontSize: 12))),
                              Text(money(order.total),
                                  style: const TextStyle(
                                      color: _wine,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12))
                            ]))),
                      ]))),
        ]);
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(
      {required this.icon,
      required this.title,
      required this.value,
      required this.caption});
  final IconData icon;
  final String title;
  final String value;
  final String caption;
  @override
  Widget build(BuildContext context) => SizedBox(
      width: (MediaQuery.sizeOf(context).width - 42) / 2,
      child: Card(
          child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: _wine),
                    const SizedBox(height: 12),
                    Text(title.toUpperCase(),
                        style: const TextStyle(
                            color: _muted,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1)),
                    const SizedBox(height: 4),
                    Text(value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: _ink,
                            fontSize: 22,
                            fontWeight: FontWeight.w800)),
                    Text(caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _muted, fontSize: 10))
                  ]))));
}

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});
  final String productId;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  String? _selectedColor;
  String? _selectedSize;
  int _image = 0;
  bool _addingToBag = false;

  @override
  Widget build(BuildContext context) {
    final api = StoreScope.of(context);
    final product =
        api.products.where((item) => item.id == widget.productId).firstOrNull;
    if (product == null) {
      return Scaffold(
          appBar: AppBar(),
          body: _EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'This piece is unavailable',
              message:
                  'It may have sold out or been removed from the collection.',
              button: 'Back to shop',
              onPressed: () => Navigator.pop(context)));
    }
    final colors = product.colors.isEmpty ? ['Default'] : product.colors;
    final sizes = product.sizes.isEmpty ? ['One size'] : product.sizes;
    final selectedColor = _selectedColor ?? colors.first;
    final selectedSize = _selectedSize ?? sizes.first;
    final isSaved = api.wishlistIds.contains(product.id);
    final selectedVariantInBag = api.cart.any((line) =>
        line.product.id == product.id &&
        line.color == selectedColor &&
        line.size == selectedSize);
    return Scaffold(
      appBar: AppBar(title: const Text('Product details'), actions: [
        IconButton(
            onPressed: () => api.toggleWishlist(product.id),
            icon: Icon(isSaved ? Icons.favorite : Icons.favorite_border,
                color: _wine))
      ]),
      body: ListView(padding: const EdgeInsets.only(bottom: 30), children: [
        AspectRatio(
          aspectRatio: .92,
          child: Stack(children: [
            PageView.builder(
                itemCount:
                    product.imageUrls.isEmpty ? 1 : product.imageUrls.length,
                onPageChanged: (index) => setState(() => _image = index),
                itemBuilder: (_, index) => _ProductImage(
                    url: product.imageUrls.isEmpty
                        ? ''
                        : product.imageUrls[index])),
            if (product.imageUrls.length > 1)
              Positioned(
                bottom: 13,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    product.imageUrls.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: _image == i ? 19 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                          color: _image == i ? _wine : Colors.white,
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ),
          ]),
        ),
        Padding(
            padding: const EdgeInsets.fromLTRB(19, 22, 19, 0),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _Eyebrow(product.category),
              const SizedBox(height: 7),
              Text(product.name,
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 9),
              Row(children: [
                Text(money(product.price),
                    style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: _ink)),
                if (product.originalPrice > product.price) ...[
                  const SizedBox(width: 8),
                  Text(money(product.originalPrice),
                      style: const TextStyle(
                          fontSize: 14,
                          color: _muted,
                          decoration: TextDecoration.lineThrough)),
                  const SizedBox(width: 8),
                  Text(
                      '${((1 - product.price / product.originalPrice) * 100).round()}% off',
                      style: const TextStyle(
                          fontSize: 12,
                          color: _wine,
                          fontWeight: FontWeight.w700)),
                ],
                const Spacer(),
                const Icon(Icons.star_rounded,
                    color: Color(0xFFD29B45), size: 19),
                Text(' ${product.rating.toStringAsFixed(1)}',
                    style: const TextStyle(
                        color: _ink, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 13),
              Text(product.description,
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 20),
              _OptionChips(
                  label: 'Colour / shade',
                  options: colors,
                  value: selectedColor,
                  onSelected: (value) =>
                      setState(() => _selectedColor = value)),
              const SizedBox(height: 16),
              _OptionChips(
                  label: 'Size / pack',
                  options: sizes,
                  value: selectedSize,
                  onSelected: (value) => setState(() => _selectedSize = value)),
              const SizedBox(height: 14),
              Text(
                  product.stock > 0
                      ? '${product.stock} available'
                      : 'Currently out of stock',
                  style: TextStyle(
                      color:
                          product.stock > 0 ? const Color(0xFF50755D) : _wine,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: product.stock <= 0 || _addingToBag
                    ? null
                    : () async {
                        if (selectedVariantInBag) {
                          await Navigator.pushNamed(context, '/cart');
                          return;
                        }
                        if (api.user == null) {
                          await Navigator.pushNamed(context, '/auth');
                          if (!context.mounted || api.user == null) return;
                        }
                        final cartQuantity = api.cart
                            .where((line) => line.product.id == product.id)
                            .fold<int>(0, (sum, line) => sum + line.quantity);
                        if (cartQuantity >= product.stock) {
                          await Navigator.pushNamed(context, '/cart');
                          return;
                        }
                        setState(() => _addingToBag = true);
                        try {
                          await api.addToCart(product,
                              color: selectedColor, size: selectedSize);
                          if (context.mounted) {
                            setState(() => _addingToBag = false);
                            _notice(context, 'Added to your Ajiomart bag.');
                          }
                        } catch (error) {
                          if (context.mounted) {
                            setState(() => _addingToBag = false);
                            _notice(
                                context,
                                error
                                    .toString()
                                    .replaceFirst('FormatException: ', ''));
                          }
                        }
                      },
                icon: _addingToBag
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(selectedVariantInBag
                        ? Icons.shopping_bag
                        : Icons.shopping_bag_outlined),
                label: Text(_addingToBag
                    ? 'Adding…'
                    : product.stock <= 0
                        ? 'Sold out'
                        : selectedVariantInBag
                            ? 'Go to bag'
                            : 'Add to bag'),
              ),
              const SizedBox(height: 9),
              OutlinedButton.icon(
                  onPressed: () => _openWhatsApp(context,
                      'Hello Ajiomart, I am interested in ${product.name}.'),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Ask us on WhatsApp')),
              const SizedBox(height: 11),
              const _ServiceHighlights(),
            ])),
      ]),
    );
  }
}

class _OptionChips extends StatelessWidget {
  const _OptionChips(
      {required this.label,
      required this.options,
      required this.value,
      required this.onSelected});
  final String label;
  final List<String> options;
  final String value;
  final ValueChanged<String> onSelected;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                color: _ink, fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options
                .map((option) => ChoiceChip(
                    label: Text(option),
                    selected: value == option,
                    onSelected: (_) => onSelected(option),
                    selectedColor: const Color(0xFFF0DDE2)))
                .toList()),
      ]);
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _createAccount = false;
  bool _working = false;
  bool _obscure = true;
  String _message = '';

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Ajiomart account')),
      body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 36),
          children: [
            const _Eyebrow('A little more you'),
            const SizedBox(height: 8),
            Text(_createAccount ? 'Join the edit.' : 'Welcome back.',
                style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 8),
            Text(
                _createAccount
                    ? 'Create your account to save favourites and track every order.'
                    : 'Sign in to keep your bag, wishlist, and orders close.',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 23),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Sign in')),
                ButtonSegment(value: true, label: Text('Create account'))
              ],
              selected: {_createAccount},
              onSelectionChanged: (selected) => setState(() {
                _createAccount = selected.first;
                _message = '';
              }),
            ),
            const SizedBox(height: 19),
            Form(
                key: _formKey,
                child: Column(children: [
                  if (_createAccount) ...[
                    TextFormField(
                        controller: _name,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                            labelText: 'Full name',
                            prefixIcon: Icon(Icons.person_outline)),
                        validator: (v) => (v ?? '').trim().isEmpty
                            ? 'Enter your name.'
                            : null),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                          labelText: 'Email address',
                          prefixIcon: Icon(Icons.mail_outline)),
                      validator: (v) => (v ?? '').contains('@')
                          ? null
                          : 'Enter a valid email address.'),
                  if (_createAccount) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                            labelText: '10-digit mobile number',
                            prefixIcon: Icon(Icons.phone_outlined)),
                        validator: (v) =>
                            (v ?? '').replaceAll(RegExp(r'\D'), '').length >= 10
                                ? null
                                : 'Enter a valid Indian mobile number.'),
                  ],
                  const SizedBox(height: 12),
                  TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                              icon: Icon(_obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined))),
                      validator: (v) =>
                          (v ?? '').length >= (_createAccount ? 6 : 1)
                              ? null
                              : _createAccount
                                  ? 'Use at least 6 characters.'
                                  : 'Enter your password.'),
                ])),
            if (_message.isNotEmpty)
              Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Text(_message,
                      style: const TextStyle(color: _wine, fontSize: 13))),
            const SizedBox(height: 18),
            FilledButton(
                onPressed: _working ? null : _submit,
                child: _working
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(_createAccount ? 'Create account' : 'Sign in')),
            const SizedBox(height: 14),
            TextButton(
                onPressed: () => Navigator.pushNamed(context, '/privacy'),
                child: const Text(
                    'By continuing, you agree to our Privacy Policy')),
          ]),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final api = StoreScope.of(context);
    setState(() {
      _working = true;
      _message = '';
    });
    try {
      if (_createAccount) {
        final signedIn = await api.signUp(
            name: _name.text,
            email: _email.text,
            phone: _phone.text,
            password: _password.text);
        if (!signedIn && mounted) {
          setState(() => _message =
              'Account created. Check your email for the Supabase verification link, then sign in.');
        }
      } else {
        await api.signIn(_email.text, _password.text);
      }
      if (mounted && api.user != null && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _message = error
            .toString()
            .replaceFirst('AuthException: ', '')
            .replaceFirst('FormatException: ', ''));
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }
}
