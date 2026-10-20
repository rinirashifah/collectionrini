import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/storage_location.dart';
import '../providers/location_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/empty_state.dart';
import '../widgets/item_card.dart';
import 'item_detail_screen.dart';

class LocationsScreen extends StatefulWidget {
  const LocationsScreen({super.key});

  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationProvider>().fetchLocations();
    });
  }

  void _showAddLocationDialog({String? parentId, String? parentName}) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    String selectedType = 'Ruangan';

    final types = [
      'Rumah',
      'Ruangan',
      'Furnitur',
      'Bagian Penyimpanan',
      'Posisi Spesifik',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            parentId != null ? 'Tambah Sub-Lokasi' : 'Tambah Lokasi Utama',
            style: GoogleFonts.playfairDisplay(
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (parentName != null) ...[
                  Text(
                    'Induk: $parentName',
                    style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: nameController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Nama Tempat *',
                    hintText: 'Misal: Lemari Pakaian, Laci 1',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Tipe Lokasi'),
                  items: types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedType = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi (opsional)',
                    hintText: 'Keterangan tambahan letak fisik',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  final data = {
                    'name': name,
                    'location_type': selectedType,
                    'description': descController.text.trim(),
                    if (parentId != null) 'parent_location_id': parentId,
                  };
                  final success = await context.read<LocationProvider>().createLocation(data);
                  if (mounted) {
                    Navigator.pop(context);
                    if (!success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(context.read<LocationProvider>().errorMessage ?? 'Gagal membuat lokasi')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Lokasi berhasil ditambahkan ✨')),
                      );
                    }
                  }
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteLocation(StorageLocation loc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Hapus Lokasi?',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
        ),
        content: Text('Apakah kamu yakin ingin menghapus "${loc.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
            onPressed: () async {
              Navigator.pop(context);
              final success = await context.read<LocationProvider>().deleteLocation(loc.id);
              if (mounted) {
                if (!success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.read<LocationProvider>().errorMessage ?? 'Gagal menghapus lokasi'),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lokasi berhasil dihapus')),
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
    final locationProvider = context.watch<LocationProvider>();
    final isDrilledDown = locationProvider.currentLocation != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isDrilledDown ? locationProvider.currentLocation!.name : 'Storage Explorer'),
        leading: isDrilledDown
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () {
                  // Navigate up breadcrumb
                  final crumbs = locationProvider.currentBreadcrumbs;
                  if (crumbs.length > 1) {
                    locationProvider.selectLocation(crumbs[crumbs.length - 2].id);
                  } else {
                    locationProvider.clearSelectedLocation();
                  }
                },
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location_alt_outlined, color: AppColors.primary),
            tooltip: 'Tambah Lokasi',
            onPressed: () {
              if (isDrilledDown) {
                _showAddLocationDialog(
                  parentId: locationProvider.currentLocation!.id,
                  parentName: locationProvider.currentLocation!.name,
                );
              } else {
                _showAddLocationDialog();
              }
            },
          ),
          if (isDrilledDown)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Color(0xFFD32F2F)),
              tooltip: 'Hapus Lokasi Ini',
              onPressed: () => _confirmDeleteLocation(locationProvider.currentLocation!),
            ),
        ],
      ),
      body: locationProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : isDrilledDown
              ? _buildDrillDownView(locationProvider)
              : _buildRootTree(locationProvider),
    );
  }

  // Root Tree View
  Widget _buildRootTree(LocationProvider provider) {
    final rootLocations = provider.locationTree;

    if (rootLocations.isEmpty) {
      return EmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'Belum Ada Lokasi',
        message: 'Buat struktur tempat penyimpanan lemari pakaianmu.',
        buttonText: 'Tambah Lokasi Utama',
        onButtonPressed: () => _showAddLocationDialog(),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.fetchLocations(),
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: rootLocations.length,
        itemBuilder: (context, index) {
          final root = rootLocations[index];
          return _buildLocationCard(root, provider);
        },
      ),
    );
  }

  Widget _buildLocationCard(StorageLocation loc, LocationProvider provider) {
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
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_getTypeIcon(loc.locationType), color: AppColors.primary, size: 20),
          ),
          title: Text(
            loc.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
          ),
          subtitle: Row(
            children: [
              if (loc.locationType != null)
                Text(
                  loc.locationType!,
                  style: const TextStyle(fontSize: 11, color: AppColors.primary),
                ),
              if (loc.itemCount > 0) ...[
                const Text(' • ', style: TextStyle(color: AppColors.textMuted)),
                Text(
                  '${loc.itemCount} barang',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.primary),
                tooltip: 'Buka Detail Lokasi',
                onPressed: () => provider.selectLocation(loc.id),
              ),
            ],
          ),
          children: loc.children.map((child) => _buildSubLocationTile(child, provider, indent: 1)).toList(),
        ),
      ),
    );
  }

  Widget _buildSubLocationTile(StorageLocation loc, LocationProvider provider, {int indent = 1}) {
    return Padding(
      padding: EdgeInsets.only(left: 16.0 * indent, right: 12, bottom: 6),
      child: Material(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => provider.selectLocation(loc.id),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(_getTypeIcon(loc.locationType), size: 16, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.name,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
                      ),
                      if (loc.locationType != null)
                        Text(
                          loc.locationType!,
                          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                        ),
                    ],
                  ),
                ),
                if (loc.itemCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${loc.itemCount} barang',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right, size: 18, color: AppColors.textLight),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Drill Down View: Breadcrumbs, Sub-locations & Items stored here
  Widget _buildDrillDownView(LocationProvider provider) {
    final breadcrumbs = provider.currentBreadcrumbs;
    final children = provider.currentChildren;
    final items = provider.currentItems;
    final currentLoc = provider.currentLocation!;

    return RefreshIndicator(
      onRefresh: () => provider.selectLocation(currentLoc.id),
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Breadcrumbs Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                InkWell(
                  onTap: () => provider.clearSelectedLocation(),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                    child: Icon(Icons.home, size: 18, color: AppColors.primary),
                  ),
                ),
                ...breadcrumbs.map((crumb) {
                  final isLast = crumb.id == currentLoc.id;
                  return Row(
                    children: [
                      const Icon(Icons.chevron_right, size: 16, color: AppColors.textLight),
                      InkWell(
                        onTap: isLast ? null : () => provider.selectLocation(crumb.id),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          child: Text(
                            crumb.name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isLast ? FontWeight.bold : FontWeight.w500,
                              color: isLast ? AppColors.primary : AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Location Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      currentLoc.name,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    if (currentLoc.locationType != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          currentLoc.locationType!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                if (currentLoc.description != null && currentLoc.description!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    currentLoc.description!,
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ],
            ),
          ),

          // Sub-locations Section
          if (children.isNotEmpty) ...[
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sub-Lokasi Penyimpanan (${children.length})',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                TextButton.icon(
                  onPressed: () => _showAddLocationDialog(
                    parentId: currentLoc.id,
                    parentName: currentLoc.name,
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Sub-Lokasi', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...children.map((child) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => provider.selectLocation(child.id),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Icon(_getTypeIcon(child.locationType), size: 18, color: AppColors.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    child.name,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
                                  ),
                                  if (child.description != null && child.description!.isNotEmpty)
                                    Text(
                                      child.description!,
                                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                    ),
                                ],
                              ),
                            ),
                            if (child.itemCount > 0)
                              Text(
                                '${child.itemCount} barang',
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textLight),
                          ],
                        ),
                      ),
                    ),
                  ),
                )),
          ],

          const SizedBox(height: 24),

          // Items Stored Here Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Barang yang Tersimpan (${items.length})',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (items.isEmpty)
            Container(
              padding: const EdgeInsets.all(28),
              alignment: Alignment.center,
              child: const Column(
                children: [
                  Icon(Icons.inventory_2_outlined, size: 36, color: AppColors.textLight),
                  SizedBox(height: 8),
                  Text(
                    'Tidak ada barang di lokasi ini saat ini',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.72,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return ItemCard(
                  item: item,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ItemDetailScreen(itemId: item.id)),
                    ).then((_) => provider.selectLocation(currentLoc.id));
                  },
                );
              },
            ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  IconData _getTypeIcon(String? type) {
    switch (type) {
      case 'Rumah':
        return Icons.home_outlined;
      case 'Ruangan':
        return Icons.meeting_room_outlined;
      case 'Furnitur':
        return Icons.inventory_2_outlined;
      case 'Bagian Penyimpanan':
        return Icons.vertical_split_outlined;
      case 'Posisi Spesifik':
      default:
        return Icons.place_outlined;
    }
  }
}
