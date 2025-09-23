// lib/features/product/ui/product_list_page.dart
// import 'dart:json';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ekatalog_etm/models/product.dart';
import 'package:ekatalog_etm/features/product/widgets/product_card.dart';
import 'package:ekatalog_etm/features/product/ui/product_detail_page.dart';

const double productCardHeight = 260;

enum ProductListMode { filterable, newProducts }

enum SortOption { latest, oldest, aToZ, zToA }

class ProductListPage extends StatefulWidget {
  final ProductListMode mode;
  const ProductListPage({Key? key, this.mode = ProductListMode.filterable})
    : super(key: key);

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage>
    with TickerProviderStateMixin {
  List<Product> _allProducts = [];
  List<Product> _visible = [];
  bool _loading = true;

  final TextEditingController _searchController = TextEditingController();

  static const _prefParents = 'plp_parents';
  static const _prefSubs = 'plp_subs';
  static const _prefSort = 'plp_sort';
  static const _prefSearch = 'plp_search';

  final Set<String> _selectedParents = {};
  final Set<String> _selectedSubs = {};
  final Set<int> _favoriteIds = {}; // local favorite tracking for demo
  SortOption _sort = SortOption.aToZ;

  bool _collapseTipe = false;
  bool _collapseKategori = false;

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
    'Furniture': ['Kasur', 'Kitchen', 'Kursi', 'Lemari', 'Meja', 'Rak'],
  };

  final Color accentYellow = const Color(0xFFFDD100);
  final Color primaryColor = const Color(0xFFB11F23);

  late final AnimationController _enterController;
  late final AnimationController _modalAnimController;

  @override
  void initState() {
    super.initState();
    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _modalAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    if (widget.mode == ProductListMode.filterable) {
      _loadSavedFilters();
      _searchController.addListener(_onSearchChanged);
    }
    _loadProducts();

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _enterController.forward(),
    );
  }

  @override
  void dispose() {
    _enterController.dispose();
    _modalAnimController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedFilters() async {
    final prefs = await SharedPreferences.getInstance();
    final parents = prefs.getStringList(_prefParents) ?? [];
    final subs = prefs.getStringList(_prefSubs) ?? [];
    final sortName = prefs.getString(_prefSort) ?? SortOption.aToZ.name;
    final search = prefs.getString(_prefSearch) ?? '';

    setState(() {
      _selectedParents.addAll(parents);
      _selectedSubs.addAll(subs);
      _sort = SortOption.values.firstWhere(
        (e) => e.name == sortName,
        orElse: () => SortOption.aToZ,
      );
      _searchController.text = search;
    });
  }

  Future<void> _saveFilters() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefParents, _selectedParents.toList());
    await prefs.setStringList(_prefSubs, _selectedSubs.toList());
    await prefs.setString(_prefSort, _sort.name);
    await prefs.setString(_prefSearch, _searchController.text.trim());
  }

  Future<void> _clearSavedFilters() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefParents);
    await prefs.remove(_prefSubs);
    await prefs.remove(_prefSort);
    await prefs.remove(_prefSearch);

    setState(() {
      _selectedParents.clear();
      _selectedSubs.clear();
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
      final products = arr
          .map((m) => Product.fromMap(m as Map<String, dynamic>))
          .toList();

      setState(() {
        _allProducts = products;
      });

      if (widget.mode == ProductListMode.newProducts) {
        _allProducts.sort((a, b) => b.id.compareTo(a.id));
        setState(() => _visible = List.from(_allProducts));
      } else {
        _applyFilters();
      }
    } catch (e) {
      debugPrint('Error loading products.json: $e');
      setState(() {
        _allProducts = [];
        _visible = [];
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  void _onSearchChanged() {
    _saveFilters();
    _applyFilters();
  }

  String _norm(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
  bool _fuzzyMatch(String a, String b) {
    final na = _norm(a);
    final nb = _norm(b);
    return na == nb || na.contains(nb) || nb.contains(na);
  }

  bool _productMatchesCategory(Product p) {
    if (_selectedParents.isEmpty && _selectedSubs.isEmpty) return true;

    final prodCat = p.category ?? '';
    final prodSub = p.subCategory ?? '';

    if (_selectedSubs.isNotEmpty) {
      for (var s in _selectedSubs) {
        if (_fuzzyMatch(s, prodCat) || _fuzzyMatch(s, prodSub)) return true;
      }
      return false;
    }

    final allowed = <String>{};
    for (var parent in _selectedParents) {
      final children = _categoryTree[parent];
      if (children != null) allowed.addAll(children);
    }

    for (var a in allowed) {
      if (_fuzzyMatch(a, prodCat) || _fuzzyMatch(a, prodSub)) return true;
    }

    return false;
  }

  void _applyFilters() {
    final q = _searchController.text.trim().toLowerCase();
    List<Product> filtered = _allProducts.where((p) {
      final matchesQuery = q.isEmpty || p.title.toLowerCase().contains(q);
      final matchesCategory = _productMatchesCategory(p);
      return matchesQuery && matchesCategory;
    }).toList();

    switch (_sort) {
      case SortOption.latest:
        filtered.sort((a, b) => b.id.compareTo(a.id));
        break;
      case SortOption.oldest:
        filtered.sort((a, b) => a.id.compareTo(b.id));
        break;
      case SortOption.aToZ:
        filtered.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
        break;
      case SortOption.zToA:
        filtered.sort(
          (a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()),
        );
        break;
    }

    setState(() => _visible = filtered);
  }

  Future<void> _openFilterModal() async {
    if (widget.mode != ProductListMode.filterable) return;

    final workingParents = Set<String>.from(_selectedParents);
    final workingSubs = Set<String>.from(_selectedSubs);
    SortOption workingSort = _sort;
    bool workingCollapseTipe = _collapseTipe;
    bool workingCollapseKategori = _collapseKategori;

    _modalAnimController.forward(from: 0.0);

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return AnimatedBuilder(
          animation: _modalAnimController,
          builder: (c, child) {
            final t = Curves.easeOut.transform(_modalAnimController.value);
            return Opacity(
              opacity: t,
              child: Transform.scale(scale: 0.98 + 0.02 * t, child: child),
            );
          },
          child: _buildFilterSheet(
            workingParents,
            workingSubs,
            workingSort,
            workingCollapseTipe,
            workingCollapseKategori,
          ),
        );
      },
    );

    if (result == true) {}
    _modalAnimController.reverse();
  }

  Widget _buildFilterSheet(
    Set<String> workingParents,
    Set<String> workingSubs,
    SortOption workingSort,
    bool workingCollapseTipe,
    bool workingCollapseKategori,
  ) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.86,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              void toggleParent(String label) {
                setModalState(() {
                  if (workingParents.contains(label))
                    workingParents.remove(label);
                  else
                    workingParents.add(label);

                  final allowed = <String>{};
                  for (var p in workingParents)
                    allowed.addAll(_categoryTree[p] ?? []);
                  if (allowed.isNotEmpty)
                    workingSubs.retainWhere((s) => allowed.contains(s));
                });
              }

              final materialSelected = workingParents.contains(
                'Material Springbed & Sofa',
              );
              final furnitureSelected = workingParents.contains('Furniture');

              Widget parentTile(String label, bool selected) {
                return GestureDetector(
                  onTap: () => toggleParent(label),
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? accentYellow : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? accentYellow : Colors.grey.shade300,
                        width: 1.4,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            style: TextStyle(
                              color: selected ? Colors.black : Colors.black87,
                              fontWeight: FontWeight.w600,
                              fontSize: 13, fontFamily: 'poppins'
                            ),
                          ),
                        ),
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: selected ? Colors.black : Colors.transparent,
                            border: Border.all(
                              color: selected
                                  ? Colors.black
                                  : Colors.grey.shade400,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: selected
                              ? const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                );
              }

              Widget subsChips(List<String> subs, bool enabled) {
                final sorted = subs.toList()
                  ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: sorted.map((s) {
                    final sel = workingSubs.contains(s);
                    return GestureDetector(
                      onTap: enabled
                          ? () => setModalState(() {
                              if (sel)
                                workingSubs.remove(s);
                              else
                                workingSubs.add(s);
                            })
                          : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: sel
                              ? accentYellow
                              : enabled
                              ? Colors.white
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: sel
                                ? Colors.black
                                : (enabled
                                      ? Colors.black
                                      : Colors.grey.shade300),
                          ),
                        ),
                        child: Text(
                          s,
                          style: TextStyle(
                            color: sel
                                ? Colors.black
                                : (enabled
                                      ? Colors.black87
                                      : Colors.grey.shade600),
                            fontWeight: sel ? FontWeight.w700 : FontWeight.w600,
                            fontSize: 12, fontFamily: 'poppins',
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              }

              return SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 48,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Filter',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold, fontFamily: 'poppins')
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    setModalState(() {
                                      workingParents.clear();
                                      workingSubs.clear();
                                      workingSort = SortOption.aToZ;
                                    });
                                  },
                                  child: Text(
                                    'Reset',
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            GestureDetector(
                              onTap: () => setModalState(
                                () =>
                                    workingCollapseTipe = !workingCollapseTipe,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Tipe',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12, fontFamily: 'poppins'
                                    ),
                                  ),
                                  Icon(
                                    workingCollapseTipe
                                        ? Icons.keyboard_arrow_up
                                        : Icons.keyboard_arrow_down,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (!workingCollapseTipe)
                              Column(
                                children: [
                                  parentTile(
                                    'Material Springbed & Sofa',
                                    materialSelected,
                                  ),
                                  parentTile('Furniture', furnitureSelected),
                                ],
                              ),

                            const SizedBox(height: 14),
                            const Divider(),
                            const SizedBox(height: 12),

                            GestureDetector(
                              onTap: () => setModalState(
                                () => workingCollapseKategori =
                                    !workingCollapseKategori,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Kategori',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12, fontFamily: 'poppins'
                                    ),
                                  ),
                                  Icon(
                                    workingCollapseKategori
                                        ? Icons.keyboard_arrow_up
                                        : Icons.keyboard_arrow_down,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (!workingCollapseKategori) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Material Springbed & Sofa',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500, fontFamily: 'poppins',
                                  color: materialSelected || !furnitureSelected
                                      ? Colors.black87
                                      : Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              subsChips(
                                _categoryTree['Material Springbed & Sofa'] ??
                                    [],
                                materialSelected || !furnitureSelected,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Furniture',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: furnitureSelected || !materialSelected
                                      ? Colors.black87
                                      : Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              subsChips(
                                _categoryTree['Furniture'] ?? [],
                                furnitureSelected || !materialSelected,
                              ),
                            ],

                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 12),

                            const Text(
                              'Sort',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Radio<SortOption>(
                                value: SortOption.latest,
                                groupValue: workingSort,
                                onChanged: (v) =>
                                    setModalState(() => workingSort = v!),
                              ),
                              title: const Text('Terbaru'),
                              onTap: () => setModalState(
                                () => workingSort = SortOption.latest,
                              ),
                            ),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Radio<SortOption>(
                                value: SortOption.oldest,
                                groupValue: workingSort,
                                onChanged: (v) =>
                                    setModalState(() => workingSort = v!),
                              ),
                              title: const Text('Terlama'),
                              onTap: () => setModalState(
                                () => workingSort = SortOption.oldest,
                              ),
                            ),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Radio<SortOption>(
                                value: SortOption.aToZ,
                                groupValue: workingSort,
                                onChanged: (v) =>
                                    setModalState(() => workingSort = v!),
                              ),
                              title: const Text('A → Z'),
                              onTap: () => setModalState(
                                () => workingSort = SortOption.aToZ,
                              ),
                            ),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Radio<SortOption>(
                                value: SortOption.zToA,
                                groupValue: workingSort,
                                onChanged: (v) =>
                                    setModalState(() => workingSort = v!),
                              ),
                              title: const Text('Z → A'),
                              onTap: () => setModalState(
                                () => workingSort = SortOption.zToA,
                              ),
                            ),

                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(false),
                               style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 14),
                                child: Text('Batal', style: TextStyle(color: Colors.black),),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _selectedParents
                                    ..clear()
                                    ..addAll(workingParents);
                                  _selectedSubs
                                    ..clear()
                                    ..addAll(workingSubs);
                                  _sort = workingSort;
                                  _collapseTipe = workingCollapseTipe;
                                  _collapseKategori = workingCollapseKategori;
                                });
                                _saveFilters();
                                _applyFilters();
                                Navigator.of(context).pop(true);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xffFDD100),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 14),
                                child: Text(
                                  'Terapkan',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSearchAndFilterRow() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black),
            ),
            child: Row(
              children: [
                // const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Cari produk atau kode...',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) {
                      _saveFilters();
                      _applyFilters();
                    },
                  ),
                ),
                const Icon(Icons.search, size: 18, color: Colors.black),
                if (_searchController.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      _saveFilters();
                      _applyFilters();
                    },
                    child: const Icon(
                      Icons.close,
                      size: 18,
                      color: Colors.grey,
                    ),
                  ),
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
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Image.asset(
              'assets/icons/filter.png',
              width: 24,
              height: 24,
              color: Colors.black, // kalau mau kasih warna overlay
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveFiltersArea() {
    final materialSelected = _selectedParents.contains(
      'Material Springbed & Sofa',
    );
    final furnitureSelected = _selectedParents.contains('Furniture');

    return AnimatedSize(
      duration: const Duration(milliseconds: 260),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text('Tipe', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),

          // parents (Tipe) — aligned left
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedParents.isNotEmpty
                ? _selectedParents
                      .map(
                        (p) => Chip(
                          label: Text(
                            p,
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          backgroundColor: accentYellow,
                          onDeleted: () {
                            setState(() => _selectedParents.remove(p));
                            _saveFilters();
                            _applyFilters();
                          },
                        ),
                      )
                      .toList()
                : [Chip(label: const Text('Semua Kategori'), onDeleted: null)],
          ),

          const SizedBox(height: 10),

          // Sub kategori title
          const Text('Kategori', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),

          // box containing sub categories (selected) or suggestion
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(2),
            child: _selectedSubs.isNotEmpty
                ? SizedBox(
                    height: 44, // cukup untuk memuat Chip secara horizontal
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      // padding: const EdgeInsets.symmetric(horizontal: 4),
                      itemCount: _selectedSubs.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final subs = _selectedSubs.toList();
                        final s = subs[index];
                        return Chip(
                          label: Text(
                            s,
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onDeleted: () {
                            setState(() => _selectedSubs.remove(s));
                            _saveFilters();
                            _applyFilters();
                          },
                          backgroundColor: accentYellow,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        );
                      },
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isFilterable = widget.mode == ProductListMode.filterable;
    final title = isFilterable ? 'Semua Produk' : 'Produk Baru';

    final pageFade = CurvedAnimation(
      parent: _enterController,
      curve: Curves.easeOut,
    );
    final pageSlide = Tween<Offset>(
      begin: const Offset(0, 0.02),
      end: Offset.zero,
    ).animate(pageFade);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'poppins',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryColor,
        leading: IconButton(
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
          icon: const Icon(FontAwesomeIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        toolbarHeight: 80, // <--- tinggi AppBar
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12),
              child: FadeTransition(
                opacity: pageFade,
                child: SlideTransition(
                  position: pageSlide,
                  child: Column(
                    children: [
                      if (isFilterable) _buildSearchAndFilterRow(),
                      const SizedBox(height: 12),

                      if (isFilterable &&
                          (_searchController.text.isNotEmpty ||
                              _selectedParents.isNotEmpty ||
                              _selectedSubs.isNotEmpty))
                        _buildActiveFiltersArea(),

                      const SizedBox(height: 12),

                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 320),
                          child: _visible.isEmpty
                              ? RefreshIndicator(
                                  onRefresh: _loadProducts,
                                  key: ValueKey('empty-${_visible.length}'),
                                  child: ListView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    children: [
                                      SizedBox(
                                        height:
                                            MediaQuery.of(context).size.height *
                                            0.2,
                                      ),
                                      const Center(
                                        child: Text(
                                          'Tidak ada produk',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : RefreshIndicator(
                                  onRefresh: _loadProducts,
                                  key: ValueKey('list-${_visible.length}'),
                                  child: GridView.builder(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    itemCount: _visible.length,
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          mainAxisSpacing: 16,
                                          crossAxisSpacing: 16,
                                          mainAxisExtent: productCardHeight,
                                        ),
                                    itemBuilder: (context, index) {
                                      final p = _visible[index];
                                      return TweenAnimationBuilder<double>(
                                        key: ValueKey(
                                          'card-${p.id}-${_visible.length}',
                                        ),
                                        tween: Tween(begin: 0.96, end: 1.0),
                                        duration: Duration(
                                          milliseconds: 260 + (index % 6) * 30,
                                        ),
                                        curve: Curves.easeOutBack,
                                        builder: (context, scale, child) =>
                                            Transform.scale(
                                              scale: scale,
                                              child: child,
                                            ),
                                        child: ProductCard(
                                          product: p,
                                          isFavorite: _favoriteIds.contains(
                                            p.id,
                                          ),
                                          onFavoriteChanged: (id, fav) {
                                            setState(() {
                                              if (fav)
                                                _favoriteIds.add(id);
                                              else
                                                _favoriteIds.remove(id);
                                            });
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  fav
                                                      ? 'Ditambahkan ke wishlist'
                                                      : 'Dihapus dari wishlist',
                                                ),
                                              ),
                                            );
                                          },
                                          onTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  ProductDetailPage(product: p),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
