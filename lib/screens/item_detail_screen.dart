import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/collection_item.dart';
import '../models/laundry_history.dart';
import '../models/location_history.dart';
import '../providers/collection_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_button.dart';
import '../widgets/location_picker_dialog.dart';
import '../widgets/status_badge.dart';
import 'add_edit_item_screen.dart';

class ItemDetailScreen extends StatefulWidget {
  final String itemId;

  const ItemDetailScreen({super.key, required this.itemId});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _api = ApiService();

  CollectionItem? _item;
  List<LocationHistory> _locationHistories = [];
  List<LaundryHistory> _laundryHistories = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDetail();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final detail = await _api.getItemDetail(widget.itemId);
      setState(() {
        _item = detail['item'];
        _locationHistories = detail['location_histories'] ?? [];
        _laundryHistories = detail['laundry_histories'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  // Action: Mark In Use
  Future<void> _markInUse() async {
    try {
      await _api.updateStatus(_item!.id, 'In Use', notes: 'Barang sedang dipakai');
      await _loadDetail();
      if (mounted) {
        context.read<CollectionProvider>().fetchItems();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status barang: In Use (Sedang Dipakai)')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e')),
      );
    }
  }

  // Action: Mark In Laundry
  Future<void> _startLaundry() async {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Kirim ke Laundry',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Barang akan ditandai "In Laundry" dan siklus pencucian baru akan dicatat.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
                hintText: 'Misal: Cuci terpisah, rendam sebentar',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _api.startLaundry(_item!.id, notes: noteController.text.trim());
                await _loadDetail();
                if (mounted) {
                  context.read<CollectionProvider>().fetchItems();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Barang masuk ke daftar pencucian')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal: $e')),
                  );
                }
              }
            },
            child: const Text('Kirim ke Laundry'),
          ),
        ],
      ),
    );
  }

  // Action: Complete Laundry -> Ready to Store
  Future<void> _completeLaundry() async {
    try {
      await _api.completeLaundry(_item!.id, notes: 'Selesai dicuci dan dijemur');
      await _loadDetail();
      if (mounted) {
        context.read<CollectionProvider>().fetchItems();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cucian selesai! Barang kini Ready to Store ✨')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e')),
      );
    }
  }

  // Action: Store Item & Mark Available
  Future<void> _storeItem() async {
    final selectedLocation = await LocationPickerDialog.show(
      context,
      initialSelectedId: _item?.currentLocationId,
      title: 'Pilih Tempat Penyimpanan Utama',
    );

    if (selectedLocation != null) {
      try {
        await _api.storeItem(_item!.id, selectedLocation.id, notes: 'Disimpan kembali ke lemari');
        await _loadDetail();
        if (mounted) {
          context.read<CollectionProvider>().fetchItems();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Barang berhasil disimpan & siap digunakan (Available) ✨')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal: $e')),
          );
        }
      }
    }
  }

  // Action: Move Location
  Future<void> _moveLocation() async {
    final selectedLocation = await LocationPickerDialog.show(
      context,
      initialSelectedId: _item?.currentLocationId,
      title: 'Pindahkan ke Lokasi Baru',
    );

    if (selectedLocation != null) {
      final posController = TextEditingController(text: _item?.positionDetail ?? '');
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Konfirmasi Pemindahan',
            style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Lokasi baru: ${selectedLocation.name}'),
              const SizedBox(height: 12),
              TextField(
                controller: posController,
                decoration: const InputDecoration(
                  labelText: 'Posisi Spesifik (opsional)',
                  hintText: 'Misal: Laci 2 sisi kiri',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await _api.moveLocation(
                    _item!.id,
                    selectedLocation.id,
                    positionDetail: posController.text.trim(),
                  );
                  await _loadDetail();
                  if (mounted) {
                    context.read<CollectionProvider>().fetchItems();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Lokasi berhasil dipindahkan ✨')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal memindahkan: $e')),
                    );
                  }
                }
              },
              child: const Text('Pindahkan'),
            ),
          ],
        ),
      );
    }
  }

  // Action: Delete Item
  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Hapus Barang?',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
        ),
        content: Text('Apakah kamu yakin ingin menghapus "${_item?.name}" dari koleksi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
            onPressed: () async {
              Navigator.pop(context);
              final success = await context.read<CollectionProvider>().deleteItem(_item!.id);
              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Barang berhasil dihapus')),
                  );
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gagal menghapus barang')),
                  );
                }
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_error != null || _item == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error ?? 'Barang tidak ditemukan'),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _loadDetail, child: const Text('Coba Lagi')),
            ],
          ),
        ),
      );
    }

    final item = _item!;
    final dateFormat = DateFormat('d MMM yyyy, HH:mm');

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Collapsible Image Header
          SliverAppBar(
            expandedHeight: 340,
            pinned: true,
            backgroundColor: AppColors.background,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddEditItemScreen(itemToEdit: item),
                    ),
                  ).then((_) => _loadDetail());
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Color(0xFFD32F2F)),
                onPressed: _confirmDelete,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: item.imageUrl != null && item.imageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.imageUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _buildImagePlaceholder(),
                    )
                  : _buildImagePlaceholder(),
            ),
          ),

          // Details Body
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category & Status Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (item.category != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            item.category!.name.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      StatusBadge(status: item.availabilityStatus),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Item Name
                  Text(
                    item.name,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Adaptive Quick Action Buttons
                  _buildAdaptiveActions(),

                  const SizedBox(height: 24),

                  // Current Storage Location Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.location_on, color: AppColors.primary, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Lokasi Penyimpanan Saat Ini',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: _moveLocation,
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(50, 30),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Pindahkan',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.currentLocation?.name ?? 'Belum ditentukan',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        if (item.positionDetail != null && item.positionDetail!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Posisi: ${item.positionDetail!}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Metadata Specs Grid
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        _buildSpecRow('Warna', item.color?.isNotEmpty == true ? item.color! : '-'),
                        const Divider(height: 16, color: AppColors.border),
                        _buildSpecRow('Merek / Brand', item.brand?.isNotEmpty == true ? item.brand! : '-'),
                        const Divider(height: 16, color: AppColors.border),
                        _buildSpecRow('Ukuran / Size', item.size?.isNotEmpty == true ? item.size! : '-'),
                        if (item.updatedAt != null) ...[
                          const Divider(height: 16, color: AppColors.border),
                          _buildSpecRow('Terakhir Diperbarui', dateFormat.format(item.updatedAt!)),
                        ],
                      ],
                    ),
                  ),

                  if (item.notes != null && item.notes!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Catatan Tambahan',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.notes!,
                            style: const TextStyle(fontSize: 13, color: AppColors.textDark, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  // History Tabs (Lokasi & Laundry)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: AppColors.primary,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textMuted,
                      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      tabs: const [
                        Tab(text: 'Riwayat Lokasi'),
                        Tab(text: 'Riwayat Laundry'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Tab Views
                  SizedBox(
                    height: 280,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Tab 1: Location History
                        _buildLocationHistoryList(),
                        // Tab 2: Laundry History
                        _buildLaundryHistoryList(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdaptiveActions() {
    final status = _item!.availabilityStatus;

    if (status == 'Available') {
      return Row(
        children: [
          Expanded(
            child: CustomButton(
              text: 'Pakai Barang',
              icon: Icons.accessibility_new_rounded,
              backgroundColor: AppColors.statusInUseText,
              onPressed: _markInUse,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: CustomButton(
              text: 'Kirim Laundry',
              icon: Icons.local_laundry_service_outlined,
              backgroundColor: AppColors.statusInLaundryText,
              onPressed: _startLaundry,
            ),
          ),
        ],
      );
    } else if (status == 'In Use') {
      return Row(
        children: [
          Expanded(
            child: CustomButton(
              text: 'Selesai & Simpan',
              icon: Icons.check_circle_outline,
              backgroundColor: AppColors.statusAvailableText,
              onPressed: _storeItem,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: CustomButton(
              text: 'Kirim Laundry',
              icon: Icons.local_laundry_service_outlined,
              backgroundColor: AppColors.statusInLaundryText,
              onPressed: _startLaundry,
            ),
          ),
        ],
      );
    } else if (status == 'In Laundry') {
      return CustomButton(
        text: 'Selesai Dicuci',
        icon: Icons.iron_outlined,
        backgroundColor: AppColors.statusReadyToStoreText,
        onPressed: _completeLaundry,
      );
    } else if (status == 'Ready to Store') {
      return CustomButton(
        text: 'Simpan & Tandai Available',
        icon: Icons.check_circle_outline,
        backgroundColor: AppColors.statusAvailableText,
        onPressed: _storeItem,
      );
    } else {
      return CustomButton(
        text: 'Tandai Siap Digunakan (Available)',
        icon: Icons.check,
        backgroundColor: AppColors.primary,
        onPressed: () => _api.updateStatus(_item!.id, 'Available').then((_) => _loadDetail()),
      );
    }
  }

  Widget _buildSpecRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationHistoryList() {
    if (_locationHistories.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada riwayat perpindahan lokasi',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      );
    }

    final dateFormat = DateFormat('d MMM yyyy, HH:mm');

    return ListView.builder(
      itemCount: _locationHistories.length,
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        final h = _locationHistories[index];
        final prevName = h.previousLocation?.name ?? 'Baru';
        final newName = h.newLocation?.name ?? 'Dihapus';

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.sync_alt, size: 14, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$prevName  ➔  $newName',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateFormat.format(h.movedAt),
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                    if (h.notes != null && h.notes!.isNotEmpty)
                      Text(
                        h.notes!,
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLaundryHistoryList() {
    if (_laundryHistories.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada riwayat siklus pencucian',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      );
    }

    final dateFormat = DateFormat('d MMM yyyy, HH:mm');

    return ListView.builder(
      itemCount: _laundryHistories.length,
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        final l = _laundryHistories[index];
        final isFinished = l.completedAt != null;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isFinished ? AppColors.statusAvailableBg : AppColors.statusInLaundryBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isFinished ? Icons.check_circle_outline : Icons.local_laundry_service_outlined,
                  size: 14,
                  color: isFinished ? AppColors.statusAvailableText : AppColors.statusInLaundryText,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isFinished ? 'Siklus Cuci Selesai' : 'Sedang Dicuci (Aktif)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isFinished ? AppColors.statusAvailableText : AppColors.statusInLaundryText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Mulai: ${dateFormat.format(l.startedAt)}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                    if (isFinished)
                      Text(
                        'Selesai: ${dateFormat.format(l.completedAt!)}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    if (l.notes != null && l.notes!.isNotEmpty)
                      Text(
                        l.notes!,
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: AppColors.primaryLight,
      child: const Center(
        child: Icon(Icons.checkroom_outlined, size: 70, color: AppColors.primary),
      ),
    );
  }
}
