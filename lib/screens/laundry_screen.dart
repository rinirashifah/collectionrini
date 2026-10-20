import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/collection_item.dart';
import '../providers/collection_provider.dart';
import '../providers/laundry_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/empty_state.dart';
import '../widgets/location_picker_dialog.dart';
import 'item_detail_screen.dart';

class LaundryScreen extends StatefulWidget {
  const LaundryScreen({super.key});

  @override
  State<LaundryScreen> createState() => _LaundryScreenState();
}

class _LaundryScreenState extends State<LaundryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LaundryProvider>().fetchLaundryItems();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _completeLaundry(CollectionItem item) async {
    final success = await context.read<LaundryProvider>().completeLaundry(
      item.id,
      notes: 'Pencucian selesai, dipindahkan ke area jemuran/setrika',
    );
    if (mounted) {
      if (success) {
        context.read<CollectionProvider>().loadDashboard();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${item.name}" selesai dicuci & kini Ready to Store ✨')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.read<LaundryProvider>().errorMessage ?? 'Gagal memperbarui status')),
        );
      }
    }
  }

  Future<void> _storeItem(CollectionItem item) async {
    final selectedLocation = await LocationPickerDialog.show(
      context,
      initialSelectedId: item.currentLocationId,
      title: 'Simpan ke Lemari / Lokasi Utama',
    );

    if (selectedLocation != null) {
      final success = await context.read<LaundryProvider>().storeItem(
        item.id,
        selectedLocation.id,
        notes: 'Disimpan kembali ke tempat penyimpanan',
      );
      if (mounted) {
        if (success) {
          context.read<CollectionProvider>().loadDashboard();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('"${item.name}" disimpan ke ${selectedLocation.name} & siap dipakai (Available) ✨')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.read<LaundryProvider>().errorMessage ?? 'Gagal menyimpan barang')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final laundryProvider = context.watch<LaundryProvider>();
    final inLaundryItems = laundryProvider.inLaundryItems;
    final readyToStoreItems = laundryProvider.readyToStoreItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laundry Tracker'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Sedang Dicuci'),
                  if (inLaundryItems.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: const BoxDecoration(
                        color: AppColors.statusInLaundryBg,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        inLaundryItems.length.toString(),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.statusInLaundryText),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Siap Disimpan'),
                  if (readyToStoreItems.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: const BoxDecoration(
                        color: AppColors.statusReadyToStoreBg,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        readyToStoreItems.length.toString(),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.statusReadyToStoreText),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: laundryProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Sedang Dicuci (In Laundry)
                _buildInLaundryTab(inLaundryItems),
                // Tab 2: Selesai Dicuci, Belum Disimpan (Ready to Store)
                _buildReadyToStoreTab(readyToStoreItems),
              ],
            ),
    );
  }

  Widget _buildInLaundryTab(List<CollectionItem> items) {
    if (items.isEmpty) {
      return const EmptyState(
        icon: Icons.local_laundry_service_outlined,
        title: 'Tidak Ada Cucian',
        message: 'Semua pakaian dalam keadaan bersih dan tersimpan rapi.',
      );
    }

    final dateFormat = DateFormat('d MMM, HH:mm');

    return RefreshIndicator(
      onRefresh: () => context.read<LaundryProvider>().fetchLaundryItems(),
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(color: Color(0x063D2C2E), blurRadius: 6, offset: Offset(0, 2)),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Photo thumbnail
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ItemDetailScreen(itemId: item.id)),
                      ).then((_) => context.read<LaundryProvider>().fetchLaundryItems());
                    },
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: item.imageUrl!,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => const Icon(Icons.checkroom, color: AppColors.primary),
                            )
                          : const Icon(Icons.checkroom, color: AppColors.primary),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Item Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item.category != null)
                          Text(
                            item.category!.name.toUpperCase(),
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        Text(
                          item.name,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 12, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              item.updatedAt != null ? dateFormat.format(item.updatedAt!) : 'Baru saja',
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Quick Action: Selesai Dicuci
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.statusReadyToStoreText,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: () => _completeLaundry(item),
                    icon: const Icon(Icons.check, size: 14),
                    label: const Text('Selesai', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReadyToStoreTab(List<CollectionItem> items) {
    if (items.isEmpty) {
      return const EmptyState(
        icon: Icons.check_circle_outline_rounded,
        title: 'Semua Telah Disimpan',
        message: 'Tidak ada pakaian yang menunggu untuk disimpan kembali ke lemari.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<LaundryProvider>().fetchLaundryItems(),
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(color: Color(0x063D2C2E), blurRadius: 6, offset: Offset(0, 2)),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Photo thumbnail
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ItemDetailScreen(itemId: item.id)),
                      ).then((_) => context.read<LaundryProvider>().fetchLaundryItems());
                    },
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: item.imageUrl!,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => const Icon(Icons.checkroom, color: AppColors.primary),
                            )
                          : const Icon(Icons.checkroom, color: AppColors.primary),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Item Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item.category != null)
                          Text(
                            item.category!.name.toUpperCase(),
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        Text(
                          item.name,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        const Row(
                          children: [
                            Icon(Icons.iron_outlined, size: 12, color: AppColors.statusReadyToStoreText),
                            SizedBox(width: 4),
                            Text(
                              'Sudah kering & bersih',
                              style: TextStyle(fontSize: 11, color: AppColors.statusReadyToStoreText, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Quick Action: Simpan ke Lemari & Available
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.statusAvailableText,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: () => _storeItem(item),
                    icon: const Icon(Icons.archive_outlined, size: 14),
                    label: const Text('Simpan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
