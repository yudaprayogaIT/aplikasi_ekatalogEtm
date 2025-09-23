// lib/features/product/ui/product_list_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ekatalog_etm/models/product.dart';
import 'package:ekatalog_etm/features/product/widgets/product_card.dart';
import 'package:ekatalog_etm/features/product/ui/product_detail_page.dart';

enum ProductListMode { filterable, newProducts }

enum SortOption { latest, oldest, aToZ, zToA }

extension SortOptionLabel on SortOption {
  String get label {
    switch (this) {
      case SortOption.latest:
        return 'Terbaru';
      case SortOption.oldest:
        return 'Terlama';
      case SortOption.aToZ:
        return 'A to Z';
      case SortOption.zToA:
        return 'Z to A';
    }
  }
}

class ProductListPage extends StatefulWidget {
  final ProductListMode mode;
  const ProductListPage({Key? key, this.mode = ProductListMode.filterable}) : super(key: key);

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  // data
  List<Product> _allProducts = [];
  List<Product> _visible = [];
  bool _loading = true;

  // search
  final TextEditingController _searchController = TextEditingController();

  // persistence keys
  static const _prefTipe = 'plp_tipe';
  static const _prefParents = 'plp_parents';
  static const _prefSubs = 'plp_subs';
  static const _prefColors = 'plp_colors';
  static const _prefSort = 'plp_sort';
  static const _prefSearch = 'plp_search';

  // filter state
  final Set<String> _selectedParents = {}; // "Material Springbed & Sofa", "Furniture"
  final Set<String> _selectedSubs = {};
  final Set<String> _selectedColors = {};
  SortOption _sort = SortOption.aToZ;

  // options (some built from JSON, some static as requested)
  List<String> _colorOptions = [];

  // Static category tree requested by user
  // Parent -> children (sub categories)
  final Map<String, List<String>> _categoryTree = {
    'Material Springbed & Sofa': [
      'Aksesoris',
      'Aksesoris Kaki',
      'Bahan Kimia',
      'Busa',
      'HDP',
      'Jasa Quilting',
      'Kain Polos Sofa',
      'Kain Polos Springbed',
      'Kain Quilting',
      'Kawat',
      'Non Woven',
      'Other',
      'Per Coil',
      'Pita List',
      'Plastik',
      'Stapless',
    ],
    'Furniture': [
      'Kasur',
      'Kitchen',
      'Kursi',
      'Lemari',
      'Meja',
      'Rak',
    ],
  };

  // UI constants
  final Color primaryColor = const Color(0xFFB11F23);

  @override
  void initState() {
    super.initState();
    if (widget.mode == ProductListMode.filterable) {
      _loadSavedFilters();
      _searchController.addListener(_onSearchChanged);
    }
    _loadProducts();
  }

  Future<void> _loadSavedFilters() async {
    final prefs = await SharedPreferences.getInstance();
    final parents = prefs.getStringList(_prefParents) ?? [];
    final subs = prefs.getStringList(_prefSubs) ?? [];
    final colors = prefs.getStringList(_prefColors) ?? [];
    final sortName = prefs.getString(_prefSort) ?? SortOption.aToZ.name;
    final search = prefs.getString(_prefSearch) ?? '';

    setState(() {
      _selectedParents.addAll(parents);
      _selectedSubs.addAll(subs);
      _selectedColors.addAll(colors);
      _sort = SortOption.values.firstWhere((e) => e.name == sortName, orElse: () => SortOption.aToZ);
      _searchController.text = search;
    });
  }

  Future<void> _saveFilters() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefParents, _selectedParents.toList());
    await prefs.setStringList(_prefSubs, _selectedSubs.toList());
    await prefs.setStringList(_prefColors, _selectedColors.toList());
    await prefs.setString(_prefSort, _sort.name);
    await prefs.setString(_prefSearch, _searchController.text.trim());
  }

  Future<void> _clearSavedFilters() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefParents);
    await prefs.remove(_prefSubs);
    await prefs.remove(_prefColors);
    await prefs.remove(_prefSort);
    await prefs.remove(_prefSearch);

    setState(() {
      _selectedParents.clear();
      _selectedSubs.clear();
      _selectedColors.clear();
      _searchController.clear();
      _sort = SortOption.aToZ;
    });

    _applyFilters();
  }

  Future<void> _loadProducts() async {
    setState(() => _loading = true);
    try {
      final jsonStr = await rootBundle.loadString('assets/data/products.json');
      final List<dynamic> arr = jsonDecode(jsonStr) as List<dynamic>;
      final products = arr.map((m) => Product.fromMap(m as Map<String, dynamic>)).toList();

      // collect color options from JSON
      final colorSet = <String>{};
      for (var p in products) {
        for (var c in p.colors) {
          if (c.name.trim().isNotEmpty) colorSet.add(c.name.trim());
        }
      }

      setState(() {
        _allProducts = products;
        _colorOptions = colorSet.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      });

      // initial filtering / sorting
      if (widget.mode == ProductListMode.newProducts) {
        // New products: default newest first
        _allProducts.sort((a, b) => b.id.compareTo(a.id));
        _visible = List.from(_allProducts);
      } else {
        // All products: default Title A→Z
        _applyFilters(); // will populate _visible
      }
    } catch (e) {
      debugPrint('Error loading products.json: $e');
      setState(() {
        _allProducts = [];
        _colorOptions = [];
        _visible = [];
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  void _onSearchChanged() {
    // save & apply as user types
    _saveFilters();
    _applyFilters();
  }

  void _applyFilters() {
    final q = _searchController.text.trim().toLowerCase();
    List<Product> filtered = _allProducts.where((p) {
      // search match
      final matchesQuery = q.isEmpty ||
          p.title.toLowerCase().contains(q) ||
          p.baseCode.toLowerCase().contains(q);

      // category/subcategory logic:
      // If no parent selected & no subs selected => match all categories
      // If parent(s) selected but no subs selected => include all children of selected parents
      // If subs selected => product.subCategory must be in selectedSubs
      bool matchesCategory = true;
      if (_selectedParents.isEmpty && _selectedSubs.isEmpty) {
        matchesCategory = true;
      } else if (_selectedSubs.isNotEmpty) {
        matchesCategory = _selectedSubs.contains(p.subCategory);
      } else if (_selectedParents.isNotEmpty) {
        // build list of allowed subs from selected parents
        final allowedSubs = <String>{};
        for (var parent in _selectedParents) {
          final children = _categoryTree[parent];
          if (children != null) allowedSubs.addAll(children);
        }
        matchesCategory = allowedSubs.contains(p.subCategory);
      } else {
        matchesCategory = true;
      }

      // color filter
      bool matchesColor = true;
      if (_selectedColors.isNotEmpty) {
        matchesColor = p.colors.any((c) => _selectedColors.contains(c.name));
      }

      return matchesQuery && matchesCategory && matchesColor;
    }).toList();

    // sort
    switch (_sort) {
      case SortOption.latest:
        filtered.sort((a, b) => b.id.compareTo(a.id));
        break;
      case SortOption.oldest:
        filtered.sort((a, b) => a.id.compareTo(b.id));
        break;
      case SortOption.aToZ:
        filtered.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case SortOption.zToA:
        filtered.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
        break;
    }

    setState(() => _visible = filtered);
  }

  // open modal filter UI (matching provided design)
  Future<void> _openFilterModal() async {
    if (widget.mode != ProductListMode.filterable) return;

    // working copies
    final workingParents = Set<String>.from(_selectedParents);
    final workingSubs = Set<String>.from(_selectedSubs);
    final workingColors = Set<String>.from(_selectedColors);
    SortOption workingSort = _sort;
    final searchSnapshot = _searchController.text;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14.0)),
      ),
      builder: (ctx) {
        // local stateful builder so modal can update
        return StatefulBuilder(builder: (context, setModalState) {
          Widget _sectionDivider() {
            return const Divider(height: 12, thickness: 1);
          }

          // Subcategory list with divider lines and checkbox on right
          Widget _subCategoryList() {
            // If parent(s) selected and you want to show only children of selected parent,
            // show the children of the currently selected parent; else show all subcategories grouped.
            List<Widget> rows = [];
            // If a single parent is selected and it exists, show header of that parent
            String? activeParent;
            if (workingParents.length == 1) {
              activeParent = workingParents.first;
            }

            final subsToShow = activeParent != null
                ? _categoryTree[activeParent] ?? []
                : // show union of all children if no single parent selected
                _categoryTree.values.expand((e) => e).toList();

            for (var i = 0; i < subsToShow.length; i++) {
              final sub = subsToShow[i];
              rows.add(Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: Row(
                  children: [
                    Expanded(child: Text(sub, style: const TextStyle(fontSize: 15))),
                    Checkbox(
                      value: workingSubs.contains(sub),
                      onChanged: (v) => setModalState(() {
                        if (v == true)
                          workingSubs.add(sub);
                        else
                          workingSubs.remove(sub);
                      }),
                    ),
                  ],
                ),
              ));
              if (i != subsToShow.length - 1) rows.add(const Divider(height: 1));
            }

            if (rows.isEmpty) rows.add(const Padding(padding: EdgeInsets.all(12), child: Text('Tidak ada sub kategori')));

            return Column(children: rows);
          }

          Widget _colorsList() {
            if (_colorOptions.isEmpty) {
              return const Padding(padding: EdgeInsets.all(12), child: Text('Tidak ada warna'));
            }
            final list = _colorOptions.map((c) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Row(
                  children: [
                    Expanded(child: Text(c)),
                    Checkbox(
                      value: workingColors.contains(c),
                      onChanged: (v) => setModalState(() {
                        if (v == true)
                          workingColors.add(c);
                        else
                          workingColors.remove(c);
                      }),
                    )
                  ],
                ),
              );
            }).toList();
            // add dividers between
            final children = <Widget>[];
            for (var i = 0; i < list.length; i++) {
              children.add(list[i]);
              if (i != list.length - 1) children.add(const Divider(height: 1));
            }
            return Column(children: children);
          }

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.86,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4)))),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        const Expanded(child: Text('Filter', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              workingParents.clear();
                              workingSubs.clear();
                              workingColors.clear();
                              workingSort = SortOption.aToZ;
                            });
                          },
                          child: Text('Reset', style: TextStyle(color: primaryColor, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        // Sort section
                        const Text('Sort', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        RadioListTile<SortOption>(
                          value: SortOption.latest,
                          groupValue: workingSort,
                          onChanged: (v) => setModalState(() => workingSort = v!),
                          title: const Text('Terbaru'),
                        ),
                        RadioListTile<SortOption>(
                          value: SortOption.oldest,
                          groupValue: workingSort,
                          onChanged: (v) => setModalState(() => workingSort = v!),
                          title: const Text('Terlama'),
                        ),
                        RadioListTile<SortOption>(
                          value: SortOption.aToZ,
                          groupValue: workingSort,
                          onChanged: (v) => setModalState(() => workingSort = v!),
                          title: const Text('A to Z'),
                        ),
                        RadioListTile<SortOption>(
                          value: SortOption.zToA,
                          groupValue: workingSort,
                          onChanged: (v) => setModalState(() => workingSort = v!),
                          title: const Text('Z to A'),
                        ),
                        const SizedBox(height: 8),
                        _sectionDivider(),

                        // Kategori (parents)
                        const Text('Kategori', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        // list parents with trailing checkbox
                        Column(
                          children: _categoryTree.keys.map((parent) {
                            final selected = workingParents.contains(parent);
                            return Column(
                              children: [
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(parent, style: const TextStyle(fontSize: 15)),
                                  trailing: Checkbox(
                                    value: selected,
                                    onChanged: (v) {
                                      setModalState(() {
                                        if (v == true) {
                                          workingParents.add(parent);
                                          // also ensure all children selected? per design selecting parent may indicate selecting parent (and maybe its children)
                                          // We'll not auto-select children to keep UX predictable; but selecting parent will allow filtering by all its children if no sub selected
                                        } else {
                                          workingParents.remove(parent);
                                        }
                                      });
                                    },
                                  ),
                                ),
                                const Divider(height: 1),
                              ],
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 8),
                        _sectionDivider(),

                        // Sub Kategori header + active parent label on right
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Sub Kategori', style: TextStyle(fontWeight: FontWeight.bold)),
                            // show selected parent if exactly one chosen
                            if (workingParents.length == 1) Text(workingParents.first, style: const TextStyle(color: Colors.black54)),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // listing sub categories with dividing lines and checkbox on right
                        _subCategoryList(),

                        const SizedBox(height: 12),
                        _sectionDivider(),

                        // Warna
                        const Text('Warna', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        _colorsList(),

                        const SizedBox(height: 24),
                      ]),
                    ),
                  ),

                  // buttons
                  SafeArea(
                    top: false,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.of(context).pop(false); // cancel
                              },
                              child: const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Text('Batal')),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                // apply -> write back to parent state then pop
                                setState(() {
                                  _selectedParents
                                    ..clear()
                                    ..addAll(workingParents);
                                  _selectedSubs
                                    ..clear()
                                    ..addAll(workingSubs);
                                  _selectedColors
                                    ..clear()
                                    ..addAll(workingColors);
                                  _sort = workingSort;
                                  // search remains unchanged here (the search input is separate)
                                });
                                _saveFilters();
                                _applyFilters();
                                Navigator.of(context).pop(true);
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                              child: const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Text('Apply Filter', style: TextStyle(color: Colors.white))),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );

    // if modal closed with result true (applied) then already updated; if not applied, do nothing
    // result handling done above inside modal
    if (result == true) {
      // already applied
    } else {
      // If modal dismissed without apply, optionally restore search (we didn't modify it in modal)
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildSearchAndFilterRow() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
            child: Row(
              children: [
                const Icon(Icons.search, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(hintText: 'Cari produk atau kode...', border: InputBorder.none, isDense: true),
                  ),
                ),
                if (_searchController.text.isNotEmpty) GestureDetector(onTap: () => _searchController.clear(), child: const Icon(Icons.close, size: 18, color: Colors.grey)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 44,
          height: 44,
          child: ElevatedButton(
            onPressed: _openFilterModal,
            style: ElevatedButton.styleFrom(padding: EdgeInsets.zero, backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), side: BorderSide(color: Colors.grey.shade200)),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.filter_list, color: Colors.black54),
                if (_selectedParents.isNotEmpty || _selectedSubs.isNotEmpty || _selectedColors.isNotEmpty)
                  const Positioned(right: 6, top: 6, child: CircleAvatar(radius: 6, backgroundColor: Colors.red)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFilterable = widget.mode == ProductListMode.filterable;
    final title = isFilterable ? 'Semua Produk' : 'Produk Baru';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        leading: const BackButton(color: Colors.white),
        title: Text(title),
        actions: [
          if (isFilterable)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Reset Filters'),
                    content: const Text('Hapus saved filters dan reset?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
                      ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Hapus')),
                    ],
                  ),
                );
                if (confirm == true) {
                  await _clearSavedFilters();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Filters cleared')));
                }
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  if (isFilterable) _buildSearchAndFilterRow(),
                  if (!isFilterable) // newProducts: subtitle only
                    Row(children: [Text('Menampilkan produk terbaru', style: TextStyle(color: Colors.grey.shade700))]),
                  const SizedBox(height: 12),

                  // Active chips bar
                  if (isFilterable && (_searchController.text.isNotEmpty || _selectedParents.isNotEmpty || _selectedSubs.isNotEmpty || _selectedColors.isNotEmpty))
                    SizedBox(
                      height: 46,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          const SizedBox(width: 4),
                          if (_searchController.text.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Chip(
                                backgroundColor: Colors.grey.shade100,
                                label: Row(
                                  children: [
                                    const Icon(Icons.search, size: 16, color: Colors.black54),
                                    const SizedBox(width: 6),
                                    Text(_searchController.text, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                onDeleted: () {
                                  _searchController.clear();
                                  _saveFilters();
                                  _applyFilters();
                                },
                              ),
                            ),
                          ..._selectedParents.map((p) => Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Chip(
                                  label: Text(p, style: const TextStyle(color: Colors.white)),
                                  backgroundColor: primaryColor,
                                  onDeleted: () {
                                    setState(() => _selectedParents.remove(p));
                                    _saveFilters();
                                    _applyFilters();
                                  },
                                ),
                              )),
                          ..._selectedSubs.map((s) => Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Chip(
                                  label: Text(s),
                                  onDeleted: () {
                                    setState(() => _selectedSubs.remove(s));
                                    _saveFilters();
                                    _applyFilters();
                                  },
                                ),
                              )),
                          ..._selectedColors.map((c) => Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Chip(
                                  label: Text(c),
                                  onDeleted: () {
                                    setState(() => _selectedColors.remove(c));
                                    _saveFilters();
                                    _applyFilters();
                                  },
                                ),
                              )),
                          TextButton(onPressed: () async => await _clearSavedFilters(), child: const Text('Hapus Semua')),
                        ],
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Grid
                  Expanded(
                    child: _visible.isEmpty
                        ? RefreshIndicator(
                            onRefresh: _loadProducts,
                            child: ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                                const Center(child: Text('Tidak ada produk', style: TextStyle(fontSize: 16))),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadProducts,
                            child: GridView.builder(
                              itemCount: _visible.length,
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                mainAxisExtent: productCardHeight,
                              ),
                              itemBuilder: (context, index) {
                                final p = _visible[index];
                                return ProductCard(
                                  product: p,
                                  isFavorite: false,
                                  onFavoriteChanged: (_, __) {},
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailPage(product: p))),
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
