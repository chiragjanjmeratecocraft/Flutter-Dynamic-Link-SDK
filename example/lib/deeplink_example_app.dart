import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final screen = (payload['screen'] ?? payload['screen_name'])?.toString().trim().toLowerCase();
    final productId = (payload['product_id'] ?? payload['productId'])?.toString();
    final orderId = (payload['order_id'] ?? payload['orderId'])?.toString();
    final campaignId = (payload['campaign_id'] ?? payload['campaignId'])?.toString();

    if (screen == 'product' || screen == 'pages' || productId != null) {
      final id = productId ?? 'UNKNOWN';
      final product = _demoProducts.firstWhere(
        (p) => p.id == id,
        orElse: () => Product(id: id, name: 'Product $id', price: 0, description: 'Product opened from deep link'),
      );
      nav.push(MaterialPageRoute<void>(builder: (_) => ProductDetailsScreen(product: product)));
      return;
    }

    if (screen == 'order' || orderId != null) {
      final id = orderId ?? 'UNKNOWN';
      nav.push(MaterialPageRoute<void>(builder: (_) => OrderDetailsScreen(orderId: id)));
      return;
    }

    if (screen == 'campaign' || campaignId != null) {
      final id = campaignId ?? 'GENERIC';
      nav.push(MaterialPageRoute<void>(builder: (_) => CampaignScreen(campaignId: id)));
    }
  }

  @override
  void dispose() {
    MyDeeplinkSdk.stopSmartLinking();
    super.dispose();
  }

  Future<void> _shareProduct(BuildContext context, Product product) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await MyDeeplinkSdk.generatePublicLink(
        clientId: 'cli_8c3cc27f2c8f0e9fcec30f8f3b0044f00b6be4cd87929344e5d347b4cd8e219e',
        body: {
          "title": product.name,
          "description": product.description,
          "android_scheme": "TravelproductDetail",
          "ios_scheme": "TravelproductDetail",
          "data": {
            "screen_name": "product",
            "productId": product.id,
          },
        },
      );

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      final shortCode = response['data']['short_code'];
      final generatedLink = '$kDefaultDynamicLinkBaseUrl/$shortCode';

      if (mounted) {
        print("this is result $generatedLink");
        _showShareDialog(context, generatedLink);
      }
    } catch (e) {
      if (mounted) {
        // Close loading dialog if still open
        //Navigator.pop(context);
        print("this is error $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showShareDialog(BuildContext context, String link) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Product'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Link generated successfully:'),
            const SizedBox(height: 16),
            SelectableText(
              link,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: link)).then((_) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Link copied to clipboard')),
                  );
                }
              });
            },
            child: const Text('Copy Link'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      ShopHomeTab(
        products: _demoProducts,
        onShare: (ctx, p) => _shareProduct(ctx, p),
      ),
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
  const ShopHomeTab({
    super.key,
    required this.products,
    required this.onShare,
  });

  final List<Product> products;
  final Function(BuildContext, Product) onShare;

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
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('\$${p.price.toStringAsFixed(2)}'),
                IconButton(
                  icon: const Icon(Icons.share, size: 20),
                  onPressed: () => onShare(context, p),
                ),
              ],
            ),
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
