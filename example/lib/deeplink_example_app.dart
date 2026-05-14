import 'package:flutter/material.dart';
import 'package:my_deeplink_sdk/my_deeplink_sdk.dart';

import 'test_config_model.dart';

class DeeplinkExampleApp extends StatefulWidget {
  const DeeplinkExampleApp({super.key, required this.config});

  final DeeplinkTestConfig config;

  @override
  State<DeeplinkExampleApp> createState() => _DeeplinkExampleAppState();
}

class _DeeplinkExampleAppState extends State<DeeplinkExampleApp> {
  final _navKey = GlobalKey<NavigatorState>();
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _bootstrapSdk();
  }

  Future<void> _bootstrapSdk() async {
    await MyDeeplinkSdk.init(Map<String, dynamic>.from(widget.config.sdkInit));
    await MyDeeplinkSdk.startSmartLinking(
      options: SmartLinkingOptions(
        onSuccess: _routeFromDeepLink,
      ),
    );
  }

  void _routeFromDeepLink(DynamicLinkData data) {
    final nav = _navKey.currentState;
    if (nav == null) return;

    final payload = data.customData;
    final screen = payload['screen']?.toString().trim().toLowerCase();

    if (screen == 'product' || payload['product_id'] != null) {
      final id = payload['product_id']?.toString() ?? 'UNKNOWN';
      final product = _demoProducts.firstWhere(
        (p) => p.id == id,
        orElse: () => Product(id: id, name: 'Product $id', price: 0, description: 'Product opened from deep link'),
      );
      nav.push(MaterialPageRoute<void>(builder: (_) => ProductDetailsScreen(product: product)));
      return;
    }

    if (screen == 'order' || payload['order_id'] != null) {
      final orderId = payload['order_id']?.toString() ?? 'UNKNOWN';
      nav.push(MaterialPageRoute<void>(builder: (_) => OrderDetailsScreen(orderId: orderId)));
      return;
    }

    if (screen == 'campaign' || payload['campaign_id'] != null) {
      final campaignId = payload['campaign_id']?.toString() ?? 'GENERIC';
      nav.push(MaterialPageRoute<void>(builder: (_) => CampaignScreen(campaignId: campaignId)));
    }
  }

  @override
  void dispose() {
    MyDeeplinkSdk.stopSmartLinking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      ShopHomeTab(products: _demoProducts),
      const OrdersTab(),
      const ProfileTab(),
    ];

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: _navKey,
      title: 'My Shop',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('My Shop')),
        body: SafeArea(child: pages[_index]),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: 'Shop'),
            NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Orders'),
            NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

class ShopHomeTab extends StatelessWidget {
  const ShopHomeTab({super.key, required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final p = products[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(child: Text(p.name[0])),
            title: Text(p.name),
            subtitle: Text(p.description),
            trailing: Text('\$${p.price.toStringAsFixed(2)}'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => ProductDetailsScreen(product: p)),
              );
            },
          ),
        );
      },
    );
  }
}

class OrdersTab extends StatelessWidget {
  const OrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Card(
          child: ListTile(
            leading: Icon(Icons.local_shipping_outlined),
            title: Text('Order ORD-9012'),
            subtitle: Text('Shipped · Expected tomorrow'),
          ),
        ),
        Card(
          child: ListTile(
            leading: Icon(Icons.check_circle_outline),
            title: Text('Order ORD-9007'),
            subtitle: Text('Delivered'),
          ),
        ),
      ],
    );
  }
}


class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Profile, addresses, payment methods.'),
    );
  }
}

class ProductDetailsScreen extends StatelessWidget {
  const ProductDetailsScreen({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(product.name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('Product ID: ${product.id}'),
            const SizedBox(height: 8),
            Text(product.description),
            const SizedBox(height: 16),
            Text('Price: \$${product.price.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            FilledButton(onPressed: () {}, child: const Text('Add to cart')),
          ],
        ),
      ),
    );
  }
}

class OrderDetailsScreen extends StatelessWidget {
  const OrderDetailsScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order ID: $orderId', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('Status: Processing'),
            const Text('Estimated delivery: 2 days'),
          ],
        ),
      ),
    );
  }
}

class CampaignScreen extends StatelessWidget {
  const CampaignScreen({super.key, required this.campaignId});

  final String campaignId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Campaign')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Campaign: $campaignId', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text('Special offers unlocked from deep link.'),
          ],
        ),
      ),
    );
  }
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
  });

  final String id;
  final String name;
  final double price;
  final String description;
}

const List<Product> _demoProducts = [
  Product(
    id: 'SKU-10024',
    name: 'Wireless Earbuds',
    price: 49.99,
    description: 'Noise reduction and long battery life.',
  ),
  Product(
    id: 'SKU-10025',
    name: 'Smart Bottle',
    price: 29.50,
    description: 'Hydration reminders with LED indicator.',
  ),
  Product(
    id: 'SKU-10026',
    name: 'Travel Backpack',
    price: 64.00,
    description: 'Waterproof with laptop compartment.',
  ),
];
