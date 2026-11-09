import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_zxing/flutter_zxing.dart';

import '../data/food_repository.dart';
import '../models/product.dart';
import 'product_form_page.dart';
import 'strings.dart';

class ProductPickerPage extends StatefulWidget {
  const ProductPickerPage({super.key, required this.repository});
  final FoodRepository repository;

  @override
  State<ProductPickerPage> createState() => _ProductPickerPageState();
}

class _ProductPickerPageState extends State<ProductPickerPage> {
  final _search = TextEditingController();
  List<Product> _products = [];
  bool _loading = false;
  int _request = 0;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() => _loading = true);
    try {
      final products = await widget.repository.search(_search.text);
      if (mounted && request == _request) setState(() => _products = products);
    } catch (error) {
      _error(error);
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    setState(() {});
    _searchDebounce = Timer(const Duration(milliseconds: 250), _load);
  }

  void _error(Object error) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(S.of(context).error(error))));
    }
  }

  Future<void> _create({String? barcode}) async {
    final product = await Navigator.push<Product>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ProductFormPage(repository: widget.repository, barcode: barcode),
      ),
    );
    if (product != null && mounted) {
      Navigator.pop(context, product);
    }
  }

  Future<void> _scan() async {
    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const ScannerPage()),
    );
    if (barcode == null || !mounted) return;
    try {
      final product = await widget.repository.findBarcode(barcode);
      if (!mounted) return;
      if (product != null) {
        Navigator.pop(context, product);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(S.of(context).unknownBarcode)));
        await _create(barcode: barcode);
      }
    } catch (error) {
      _error(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.chooseProduct)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _search,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: s.searchHint,
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: s.clearSearch,
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchDebounce?.cancel();
                          _search.clear();
                          setState(() {});
                          _load();
                        },
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _scan,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: Text(s.scan),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _create(),
                    icon: const Icon(Icons.add),
                    label: Text(s.newProduct),
                  ),
                ),
              ],
            ),
          ),
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          if (!_loading && _products.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
              child: Text(
                _search.text.isEmpty ? s.recentFoods : s.searchResults,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          Expanded(
            child: _products.isEmpty && !_loading
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 40,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 12),
                          Text(s.notFound, textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: () => _create(),
                            icon: const Icon(Icons.add_rounded),
                            label: Text(s.newProduct),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final product = _products[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 3,
                        ),
                        title: Text(product.displayName(s.languageCode)),
                        subtitle: Text(
                          '${s.protein} ${product.protein} · ${s.fat} ${product.fat} · ${s.carbs} ${product.carbs} ${s.per100}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          '${product.calories.toStringAsFixed(0)} ${s.kcal}',
                        ),
                        onTap: () => Navigator.pop(context, product),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});
  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  bool _found = false;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.scanBarcode)),
      body: Stack(
        children: [
          ReaderWidget(
            showGallery: false,
            onScan: (code) {
              if (_found) return;
              final rawValue = code.text;
              if (!code.isValid || rawValue == null) return;
              // ZXing returns UPC-A as a 13-digit GTIN with a leading zero.
              final value = code.format == Format.upca &&
                      rawValue.length == 13 &&
                      rawValue.startsWith('0')
                  ? rawValue.substring(1)
                  : rawValue;
              if (!RegExp(r'^\d{8,14}$').hasMatch(value)) return;
              _found = true;
              Navigator.pop(context, value);
            },
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                s.pointCamera,
                style: const TextStyle(
                  color: Colors.white,
                  backgroundColor: Colors.black54,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
