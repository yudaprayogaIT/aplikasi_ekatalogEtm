// lib/screens/register_form.dart
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/primary_button.dart';
import '../common/status_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class RegistrationFormScreen extends StatefulWidget {
  final String phone;
  const RegistrationFormScreen({super.key, required this.phone});

  @override
  State<RegistrationFormScreen> createState() => _RegistrationFormScreenState();
}

class _RegistrationFormScreenState extends State<RegistrationFormScreen> {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  // Company controllers
  final companyNameCtrl = TextEditingController();
  final companyAddressCtrl = TextEditingController();
  final foundedIsoCtrl = TextEditingController(); // YYYY-MM-DD (saved)
  final foundedDisplayCtrl = TextEditingController(); // friendly display
  final manualBranchCtrl = TextEditingController();

  // Owner controllers
  final ownerNameCtrl = TextEditingController();
  final birthIsoCtrl = TextEditingController();
  final birthDisplayCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final confirmPasswordCtrl = TextEditingController();

  // gender - use simple selected variable to avoid Dropdown assertion
  String? selectedGender;

  // Focus nodes
  final companyNameFocus = FocusNode();
  final companyAddressFocus = FocusNode();
  final foundedFocus = FocusNode();
  final manualBranchFocus = FocusNode();
  final ownerNameFocus = FocusNode();
  final birthFocus = FocusNode();
  final passwordFocus = FocusNode();
  final confirmFocus = FocusNode();

  bool loading = false;

  // branches
  List<Map<String, String>> branches = [];
  bool loadingBranches = true;
  String? selectedBranchId;
  String? selectedBranchName;
  String? selectedBranchAddress;
  String? selectedBranchDaerah;

  bool allowManualBranch = false;
  bool branchFieldFocused = false;

  bool _showPassword = false;
  bool _showConfirm = false;

  final Color primaryColor = const Color(0xFFB11F23);

  @override
  void initState() {
    super.initState();
    _loadBranches();

    // listeners for UI updates (clear icon visibility)
    companyNameCtrl.addListener(_onCtrlChanged);
    companyAddressCtrl.addListener(_onCtrlChanged);
    foundedIsoCtrl.addListener(_onCtrlChanged);
    foundedDisplayCtrl.addListener(_onCtrlChanged);
    manualBranchCtrl.addListener(_onCtrlChanged);
    ownerNameCtrl.addListener(_onCtrlChanged);
    birthIsoCtrl.addListener(_onCtrlChanged);
    birthDisplayCtrl.addListener(_onCtrlChanged);
    passwordCtrl.addListener(_onCtrlChanged);
    confirmPasswordCtrl.addListener(_onCtrlChanged);

    companyNameFocus.addListener(_onFocusChanged);
    companyAddressFocus.addListener(_onFocusChanged);
    foundedFocus.addListener(_onFocusChanged);
    manualBranchFocus.addListener(_onFocusChanged);
    ownerNameFocus.addListener(_onFocusChanged);
    birthFocus.addListener(_onFocusChanged);
    passwordFocus.addListener(_onFocusChanged);
    confirmFocus.addListener(_onFocusChanged);
  }

  void _onCtrlChanged() {
    if (mounted) setState(() {});
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    companyNameCtrl.dispose();
    companyAddressCtrl.dispose();
    foundedIsoCtrl.dispose();
    foundedDisplayCtrl.dispose();
    manualBranchCtrl.dispose();
    ownerNameCtrl.dispose();
    birthIsoCtrl.dispose();
    birthDisplayCtrl.dispose();
    passwordCtrl.dispose();
    confirmPasswordCtrl.dispose();

    companyNameFocus.dispose();
    companyAddressFocus.dispose();
    foundedFocus.dispose();
    manualBranchFocus.dispose();
    ownerNameFocus.dispose();
    birthFocus.dispose();
    passwordFocus.dispose();
    confirmFocus.dispose();

    super.dispose();
  }

  // ---------------------------
  // Date helpers (Indonesia)
  // ---------------------------
  String _toIsoDate(DateTime dt) =>
      "${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";

  String _prettyDateIndonesia(DateTime dt) {
    const monthNames = [
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return "${dt.day} ${monthNames[dt.month]} ${dt.year}";
  }

  Future<void> _showCupertinoDatePicker({
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    required String title,
    required void Function(DateTime picked) onConfirm,
  }) async {
    DateTime temp = initialDate;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            height: MediaQuery.of(ctx).size.height * 0.42,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Batal'),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          onConfirm(temp);
                        },
                        child: Text(
                          'Pilih',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: CupertinoTheme(
                    data: CupertinoThemeData(primaryColor: primaryColor),
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.date,
                      initialDateTime: initialDate,
                      minimumDate: firstDate,
                      maximumDate: lastDate,
                      use24hFormat: true,
                      onDateTimeChanged: (d) {
                        temp = d;
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickFoundedDate() async {
    final now = DateTime.now();
    DateTime inicial = now;
    if (foundedIsoCtrl.text.isNotEmpty) {
      try {
        inicial = DateTime.parse(foundedIsoCtrl.text);
      } catch (_) {
        inicial = now;
      }
    }
    await _showCupertinoDatePicker(
      initialDate: inicial,
      firstDate: DateTime(1900),
      lastDate: now,
      title: 'Pilih Tanggal Berdiri',
      onConfirm: (d) {
        foundedIsoCtrl.text = _toIsoDate(d);
        foundedDisplayCtrl.text = _prettyDateIndonesia(d);
        setState(() {});
      },
    );
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    DateTime inicial = DateTime(now.year - 25);
    if (birthIsoCtrl.text.isNotEmpty) {
      try {
        inicial = DateTime.parse(birthIsoCtrl.text);
      } catch (_) {
        inicial = DateTime(now.year - 25);
      }
    }
    await _showCupertinoDatePicker(
      initialDate: inicial,
      firstDate: DateTime(1900),
      lastDate: now,
      title: 'Pilih Tanggal Lahir',
      onConfirm: (d) {
        birthIsoCtrl.text = _toIsoDate(d);
        birthDisplayCtrl.text = _prettyDateIndonesia(d);
        setState(() {});
      },
    );
  }

  // ---------------------------
  // Helpers: capitalization
  // ---------------------------
  String _capitalizeWords(String s) {
    return s
        .split(' ')
        .map((w) {
          if (w.trim().isEmpty) return '';
          final lower = w.toLowerCase();
          return lower[0].toUpperCase() +
              (lower.length > 1 ? lower.substring(1) : '');
        })
        .where((p) => p.isNotEmpty)
        .join(' ');
  }

  String _capitalizeFirst(String s) {
    if (s.trim().isEmpty) return '';
    final trimmed = s.trim();
    final first = trimmed[0].toUpperCase();
    final rest = trimmed.substring(1).toLowerCase();
    return '$first$rest';
  }

  // ---------------------------
  // Branch helpers & loader
  // ---------------------------
  String _formatBranchDisplay(String? name, String? daerah) {
    if (name == null || name.isEmpty) return '';
    if (daerah != null && daerah.isNotEmpty) {
      return "$name - ${_capitalizeWords(daerah)}";
    }
    return name;
  }

  Future<void> _loadBranches() async {
    setState(() {
      loadingBranches = true;
      branches = [];
      selectedBranchId = null;
      selectedBranchName = null;
      selectedBranchAddress = null;
      selectedBranchDaerah = null;
      allowManualBranch = false;
    });

    try {
      List<String> tries = [
        'id,branch_name,address,daerah',
        'id,name,address,daerah',
        '*',
      ];
      dynamic res;
      Exception? lastException;

      for (var q in tries) {
        try {
          res = await supabase
              .from('branch')
              .select(q)
              .order('branch_name', ascending: true);
        } catch (e) {
          lastException = Exception('select("$q") gagal: $e');
          res = null;
        }
        if (res != null) break;
      }

      if (res is List && res.isNotEmpty) {
        final parsed = <Map<String, String>>[];
        for (var e in res) {
          final id = (e['id'] ?? '').toString();
          String name = '';
          String address = '';
          String daerah = '';

          if (e.containsKey('branch_name') && e['branch_name'] != null) {
            name = e['branch_name'].toString();
          } else if (e.containsKey('name') && e['name'] != null) {
            name = e['name'].toString();
          } else if (e.containsKey('branch') && e['branch'] != null) {
            name = e['branch'].toString();
          } else if (e is Map) {
            for (var k in e.keys) {
              final val = e[k];
              if (val is String && val.isNotEmpty && k != 'id') {
                name = val;
                break;
              }
            }
          }

          if (e.containsKey('address') && e['address'] != null) {
            address = e['address'].toString();
          } else if (e.containsKey('alamat') && e['alamat'] != null) {
            address = e['alamat'].toString();
          } else if (e.containsKey('location') && e['location'] != null) {
            address = e['location'].toString();
          }

          if (e.containsKey('daerah') && e['daerah'] != null) {
            daerah = e['daerah'].toString();
          } else if (e.containsKey('city') && e['city'] != null) {
            daerah = e['city'].toString();
          }

          if (id.isNotEmpty && name.isNotEmpty) {
            parsed.add({
              'id': id,
              'name': name,
              'address': address,
              'daerah': daerah,
            });
          }
        }
        branches = parsed;
      } else if (res is List && res.isEmpty) {
        branches = [];
      } else if (res is Map) {
        final e = res;
        final id = (e['id'] ?? '').toString();
        final name = (e['branch_name'] ?? e['name'] ?? '').toString();
        final addr = (e['address'] ?? e['alamat'] ?? '').toString();
        final daerah = (e['daerah'] ?? e['city'] ?? '').toString();
        if (id.isNotEmpty && name.isNotEmpty)
          branches = [
            {'id': id, 'name': name, 'address': addr, 'daerah': daerah},
          ];
      } else {
        branches = [];
      }

      if (branches.isEmpty) {
        allowManualBranch = true;
        final debugMsg = lastException != null
            ? lastException.toString()
            : 'Tidak ada data cabang yang dikembalikan.';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Daftar cabang kosong atau tidak bisa dibaca. $debugMsg',
              ),
            ),
          );
        }
      }
    } catch (e) {
      branches = [];
      allowManualBranch = true;
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mengambil cabang: $e')));
      }
    } finally {
      if (mounted) setState(() => loadingBranches = false);
    }
  }

  Future<void> _openBranchPicker() async {
    final searchCtrl = TextEditingController();
    setState(() => branchFieldFocused = true);
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx2, setModalState) {
              final q = searchCtrl.text.trim().toLowerCase();
              final filtered = q.isEmpty
                  ? branches
                  : branches.where((b) {
                      final name = (b['name'] ?? '').toLowerCase();
                      final addr = (b['address'] ?? '').toLowerCase();
                      final daerah = (b['daerah'] ?? '').toLowerCase();
                      return name.contains(q) ||
                          addr.contains(q) ||
                          daerah.contains(q);
                    }).toList();

              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx2).viewInsets.bottom,
                ),
                child: SizedBox(
                  height: MediaQuery.of(ctx2).size.height * 0.62,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 8, 8),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Pilih Cabang',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh),
                              onPressed: () async => await _loadBranches(),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.of(ctx2).pop(),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: TextField(
                          controller: searchCtrl,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search),
                            hintText: 'Cari cabang atau alamat...',
                          ),
                          onChanged: (_) => setModalState(() {}),
                        ),
                      ),
                      Expanded(
                        child: loadingBranches
                            ? const Center(child: CircularProgressIndicator())
                            : filtered.isEmpty
                            ? Center(
                                child: Text(
                                  'Tidak ada hasil${branches.isEmpty ? ' (coba refresh)' : ''}',
                                ),
                              )
                            : ListView.separated(
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, idx) {
                                  final item = filtered[idx];
                                  final displayLine1 = _formatBranchDisplay(
                                    item['name'],
                                    item['daerah'],
                                  );
                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    title: Text(
                                      displayLine1,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    subtitle:
                                        (item['address'] != null &&
                                            item['address']!.isNotEmpty)
                                        ? Padding(
                                            padding: const EdgeInsets.only(
                                              top: 4,
                                            ),
                                            child: Text(
                                              item['address']!,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                                height: 1.2,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          )
                                        : null,
                                    onTap: () {
                                      selectedBranchId = item['id'];
                                      selectedBranchName = item['name'];
                                      selectedBranchAddress = item['address'];
                                      selectedBranchDaerah = item['daerah'];
                                      Navigator.of(ctx2).pop();
                                      setState(() {});
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    } finally {
      setState(() => branchFieldFocused = false);
    }
  }

  // ---------------------------
  // Password validation
  // ---------------------------
  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Kata sandi wajib diisi';
    if (v.length < 8) return 'Minimal 8 karakter';
    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(v);
    final hasSymbol = RegExp(r'[^A-Za-z0-9]').hasMatch(v);
    if (!hasLetter || !hasSymbol)
      return 'Harus mengandung minimal 1 huruf dan 1 simbol';
    return null;
  }

  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) return;

    if (passwordCtrl.text != confirmPasswordCtrl.text) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Password tidak cocok')));
      return;
    }

    if (selectedGender == null || selectedGender!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pilih jenis kelamin')));
      return;
    }

    // branch selection: must get a UUID branch_id
    final hasManualBranchInput =
        manualBranchCtrl.text.trim().isNotEmpty && allowManualBranch;
    if ((selectedBranchId == null || selectedBranchId!.isEmpty) &&
        !hasManualBranchInput) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih atau masukkan cabang terdekat')),
      );
      return;
    }

    // formatting before save
    final formattedCompanyName = _capitalizeWords(companyNameCtrl.text.trim());
    final formattedCompanyAddress = _capitalizeFirst(
      companyAddressCtrl.text.trim(),
    );
    final formattedOwnerName = _capitalizeWords(ownerNameCtrl.text.trim());

    companyNameCtrl.text = formattedCompanyName;
    companyAddressCtrl.text = formattedCompanyAddress;
    ownerNameCtrl.text = formattedOwnerName;

    // ensure founded_date is set (fallback to today) to avoid NOT NULL DB errors
    final foundedIsoValue = foundedIsoCtrl.text.isNotEmpty
        ? foundedIsoCtrl.text
        : DateTime.now().toIso8601String().split('T').first;

    // ensure birth_date is set (fallback to today) to avoid NOT NULL DB errors
    final birthIsoValue = birthIsoCtrl.text.isNotEmpty
        ? birthIsoCtrl.text
        : DateTime.now().toIso8601String().split('T').first;

    setState(() => loading = true);

    try {
      // If user provided manual branch text, create branch record first and get id
      String branchIdToUse = selectedBranchId ?? '';

      if ((branchIdToUse.isEmpty) && hasManualBranchInput) {
        // try to insert into branch table (fields may vary depending on schema)
        final branchPayload = {
          // insert common fields, adjust if your branch table uses different column names
          'branch_name': manualBranchCtrl.text.trim(),
          'name': manualBranchCtrl.text.trim(),
          'address': companyAddressCtrl.text.trim(),
          'daerah': '',
        };

        // Use .single() to get single record back and avoid .first issues
        final branchInsertRes = await supabase
            .from('branch')
            .insert(branchPayload)
            .select()
            .single();

        // debug
        // ignore: avoid_print
        print(
          '[DEBUG] insert branch response -> ${const JsonEncoder.withIndent('  ').convert(branchInsertRes)}',
        );

        if (branchInsertRes == null ||
            (branchInsertRes is Map && (branchInsertRes['id'] == null))) {
          throw 'Gagal membuat cabang (response tidak valid): $branchInsertRes';
        }

        branchIdToUse = (branchInsertRes['id'] ?? '').toString();
        if (branchIdToUse.isEmpty) {
          throw 'Gagal mengambil id cabang yang baru dibuat.';
        }
      }

      // if selectedBranchId was present use it
      if ((branchIdToUse.isEmpty) && (selectedBranchId != null)) {
        branchIdToUse = selectedBranchId!;
      }

      if (branchIdToUse.isEmpty) {
        throw 'branch_id belum tersedia.';
      }

      // prepare company payload
      final companyPayload = {
        'company_name': companyNameCtrl.text.trim(),
        'address': companyAddressCtrl.text.trim(),
        'founded_date': foundedIsoValue,
        'branch_id': branchIdToUse,
        'phone_number': widget.phone,
        // let DB fill status default if not provided
      };

      // DEBUG: company payload
      // ignore: avoid_print
      print(
        '[DEBUG] companyPayload -> ${const JsonEncoder.withIndent('  ').convert(companyPayload)}',
      );

      // insert company and get single object back
      final insertRes = await supabase
          .from('companies')
          .insert(companyPayload)
          .select()
          .single();

      // ignore: avoid_print
      print('[DEBUG] insert companies response -> $insertRes');

      if (insertRes == null || (insertRes is Map && insertRes['id'] == null)) {
        throw 'Insert perusahaan gagal (response tidak valid): $insertRes';
      }

      final companyId = (insertRes['id'] ?? '').toString();
      // ignore: avoid_print
      print('[DEBUG] created company id -> $companyId');

      // prepare owner payload according to new owners table
      final ownerPayload = {
        'owner_name': ownerNameCtrl.text.trim(),
        'birth_date': birthIsoValue,
        'gender': selectedGender ?? '',
        'phone_number': widget.phone,
        'password': passwordCtrl.text,
        'status': 'pending',
        // created_at / updated_at handled by DB default
      };

      // DEBUG owner payload
      // ignore: avoid_print
      print(
        '[DEBUG] ownerPayload -> ${const JsonEncoder.withIndent('  ').convert(ownerPayload)}',
      );

      // insert owner and get single object back
      final ownerRes = await supabase
          .from('owners')
          .insert(ownerPayload)
          .select()
          .single();

      // ignore: avoid_print
      print('[DEBUG] insert owners response -> $ownerRes');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registrasi berhasil. Menunggu persetujuan admin.'),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => StatusScreen(phone: widget.phone)),
      );
    } catch (e, st) {
      // ignore: avoid_print
      print('[DEBUG] _saveData error: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // Input decoration helper to match visual style
  InputDecoration inputDecoration({
    required String label,
    TextEditingController? controller,
    FocusNode? focusNode,
    Widget? prefix,
    Widget? extraSuffix,
    String? hint,
  }) {
    final showClear =
        controller != null &&
        focusNode != null &&
        controller.text.isNotEmpty &&
        focusNode.hasFocus;

    final suffixWidgets = <Widget>[];
    if (extraSuffix != null) suffixWidgets.add(extraSuffix);
    if (showClear) {
      suffixWidgets.add(
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            if (controller != null) controller.clear();
            if (controller == foundedDisplayCtrl) foundedIsoCtrl.clear();
            if (controller == birthDisplayCtrl) birthIsoCtrl.clear();
            if (controller == manualBranchCtrl) {
              selectedBranchId = null;
              selectedBranchName = null;
              selectedBranchAddress = null;
              selectedBranchDaerah = null;
            }
            setState(() {});
          },
        ),
      );
    }

    Widget? suffix;
    if (suffixWidgets.isNotEmpty) {
      suffix = Row(mainAxisSize: MainAxisSize.min, children: suffixWidgets);
    } else {
      suffix = null;
    }

    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      prefixIcon: prefix,
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black12),
      ),
    );
  }

  Widget _buildBranchFieldDisplay() {
    final displayLine1 = _formatBranchDisplay(
      selectedBranchName,
      selectedBranchDaerah,
    );
    final displayLine1Fallback = loadingBranches
        ? 'Memuat...'
        : 'Pilih cabang terdekat';

    return GestureDetector(
      onTap: loadingBranches
          ? null
          : () async {
              setState(() => branchFieldFocused = true);
              await _openBranchPicker();
            },
      child: InputDecorator(
        decoration: inputDecoration(label: 'Pilih Cabang Terdekat'),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (selectedBranchName != null &&
                            selectedBranchName!.isNotEmpty)
                        ? displayLine1
                        : displayLine1Fallback,
                    style: TextStyle(
                      fontSize: 14,
                      color: selectedBranchName == null
                          ? Colors.grey[500]
                          : Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (selectedBranchAddress != null &&
                      selectedBranchAddress!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      selectedBranchAddress!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (branchFieldFocused && selectedBranchName != null)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    selectedBranchId = null;
                    selectedBranchName = null;
                    selectedBranchAddress = null;
                    selectedBranchDaerah = null;
                  });
                },
              )
            else
              const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
          leading: IconButton(
          padding: const EdgeInsets.symmetric(vertical: 35),
          icon: const Icon(FontAwesomeIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header merah (judul + subjudul)
          Container(
            width: double.infinity,
            color: primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Daftar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'poppins',
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Lengkapi Profil Anda',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 15),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // Company card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Identitas Perusahaan',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: companyNameCtrl,
                            focusNode: companyNameFocus,
                            decoration: inputDecoration(
                              label: 'Nama Perusahaan',
                              controller: companyNameCtrl,
                              focusNode: companyNameFocus,
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Nama perusahaan wajib diisi'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: companyAddressCtrl,
                            focusNode: companyAddressFocus,
                            decoration: inputDecoration(
                              label: 'Alamat',
                              controller: companyAddressCtrl,
                              focusNode: companyAddressFocus,
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Alamat wajib diisi'
                                : null,
                            minLines: 1,
                            maxLines: 3,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: foundedDisplayCtrl,
                            focusNode: foundedFocus,
                            readOnly: true,
                            onTap: () {
                              FocusScope.of(context).requestFocus(foundedFocus);
                              _pickFoundedDate();
                            },
                            decoration: inputDecoration(
                              label: 'Tanggal Berdiri',
                              controller: foundedDisplayCtrl,
                              focusNode: foundedFocus,
                              extraSuffix: IconButton(
                                icon: const Icon(FontAwesomeIcons.solidCalendarDays, size: 22),
                                onPressed: () {
                                  FocusScope.of(context).requestFocus(foundedFocus);
                                  _pickFoundedDate();
                                },
                              ),
                              hint: 'DD-MM-YYYY',
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Branch selector or manual
                          loadingBranches
                              ? SizedBox(
                                  height: 56,
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : (branches.isNotEmpty
                                    ? _buildBranchFieldDisplay()
                                    : Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Cabang Terdekat',
                                            style: TextStyle(
                                              color: Colors.grey[700],
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          TextFormField(
                                            controller: manualBranchCtrl,
                                            focusNode: manualBranchFocus,
                                            decoration: inputDecoration(
                                              label:
                                                  'Masukkan nama cabang (manual)',
                                              controller: manualBranchCtrl,
                                              focusNode: manualBranchFocus,
                                            ),
                                            validator: (v) {
                                              if ((selectedBranchId == null) &&
                                                  (v == null ||
                                                      v.trim().isEmpty)) {
                                                return 'Masukkan nama cabang atau refresh daftar';
                                              }
                                              return null;
                                            },
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: OutlinedButton.icon(
                                                  onPressed: _loadBranches,
                                                  icon: const Icon(
                                                    Icons.refresh,
                                                  ),
                                                  label: const Text(
                                                    'Refresh daftar cabang',
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      )),
                          const SizedBox(height: 12),
                          // Debug info area (shows count & peek)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 12,
                            ),
                            // decoration: BoxDecoration(
                            //   color: Colors.grey.shade50,
                            //   borderRadius: BorderRadius.circular(8),
                            // ),
                            child: Row(
                              children: [
                                // Expanded(
                                //   child: Text(
                                //     'Jumlah cabang: ${branches.length}',
                                //   ),
                                // ),
                                // ElevatedButton(
                                //   onPressed: branches.isEmpty
                                //       ? null
                                //       : () {
                                //           final peek = branches
                                //               .take(5)
                                //               .toList();
                                //           showDialog(
                                //             context: context,
                                //             builder: (_) => AlertDialog(
                                //               title: const Text(
                                //                 '5 cabang pertama',
                                //               ),
                                //               content: SizedBox(
                                //                 width: double.maxFinite,
                                //                 child: SingleChildScrollView(
                                //                   child: Text(
                                //                     const JsonEncoder.withIndent(
                                //                       '  ',
                                //                     ).convert(peek),
                                //                   ),
                                //                 ),
                                //               ),
                                //               actions: [
                                //                 TextButton(
                                //                   onPressed: () =>
                                //                       Navigator.pop(context),
                                //                   child: const Text('Tutup'),
                                //                 ),
                                //               ],
                                //             ),
                                //           );
                                //         },
                                //   child: const Text('Tampilkan 5'),
                                // ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Owner card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Identitas Pemilik',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: ownerNameCtrl,
                            focusNode: ownerNameFocus,
                            decoration: inputDecoration(
                              label: 'Nama Pemilik',
                              controller: ownerNameCtrl,
                              focusNode: ownerNameFocus,
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Nama pemilik wajib diisi'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: birthDisplayCtrl,
                            focusNode: birthFocus,
                            readOnly: true,
                            onTap: () {
                              FocusScope.of(context).requestFocus(birthFocus);
                              _pickBirthDate();
                            },
                            decoration: inputDecoration(
                              label: 'Tanggal Lahir',
                              controller: birthDisplayCtrl,
                              focusNode: birthFocus,
                              extraSuffix: IconButton(
                                icon: const Icon(FontAwesomeIcons.solidCalendarDays, size: 22),
                                onPressed: () {
                                  FocusScope.of(
                                    context,
                                  ).requestFocus(birthFocus);
                                  _pickBirthDate();
                                },
                              ),
                              hint: 'DD-MM-YYYY',
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Gender dropdown
                          DropdownButtonFormField<String>(
                            initialValue: selectedGender,
                            decoration: inputDecoration(label: 'Jenis Kelamin').copyWith(
                              labelStyle: TextStyle(color: Colors.grey[600]),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'Laki-laki',
                                child: Text('Laki-laki'),
                              ),
                              DropdownMenuItem(
                                value: 'Perempuan',
                                child: Text('Perempuan'),
                              ),
                            ],
                            onChanged: (v) {
                              setState(() => selectedGender = v);
                            },
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Pilih jenis kelamin'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            initialValue: widget.phone,
                            readOnly: true,
                            decoration: inputDecoration(label: 'Nomor Telepon'),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: passwordCtrl,
                            focusNode: passwordFocus,
                            obscureText: !_showPassword,
                            decoration: inputDecoration(
                              label: 'Kata Sandi',
                              controller: passwordCtrl,
                              focusNode: passwordFocus,
                              extraSuffix: IconButton(
                                icon: Icon(
                                  _showPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () => setState(
                                  () => _showPassword = !_showPassword,
                                ),
                              ),
                            ),
                            validator: _validatePassword,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: confirmPasswordCtrl,
                            focusNode: confirmFocus,
                            obscureText: !_showConfirm,
                            decoration: inputDecoration(
                              label: 'Konfirmasi Kata Sandi',
                              controller: confirmPasswordCtrl,
                              focusNode: confirmFocus,
                              extraSuffix: IconButton(
                                icon: Icon(
                                  _showConfirm
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () => setState(
                                  () => _showConfirm = !_showConfirm,
                                ),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return 'Konfirmasi wajib diisi';
                              if (v != passwordCtrl.text)
                                return 'Konfirmasi tidak cocok';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: PrimaryButton(
                        label: loading ? 'Menyimpan...' : 'Simpan & Daftar',
                        onTap: loading ? null : _saveData,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
