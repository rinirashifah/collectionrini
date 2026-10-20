import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/collection_provider.dart';
import '../providers/laundry_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/item_card.dart';
import 'add_edit_item_screen.dart';
import 'item_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(int) onNavigateTab;
  final Function(String) onSearchCollection;
  final Function(String) onFilterStatus;

  const HomeScreen({
    super.key,
    required this.onNavigateTab,
    required this.onSearchCollection,
    required this.onFilterStatus,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh();
    });
  }

  Future<void> _refresh() async {
    await Future.wait([
      context.read<CollectionProvider>().loadDashboard(),
      context.read<CollectionProvider>().fetchItems(),
      context.read<CollectionProvider>().loadCategories(),
      context.read<LaundryProvider>().fetchLaundryItems(),
    ]);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final collectionProvider = context.watch<CollectionProvider>();
    final dashboard = collectionProvider.dashboardData;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            // Aesthetic Header
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.background,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  padding: const EdgeInsets.fromLTRB(16, 36, 16, 16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFBECEF), AppColors.background],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primary, width: 2),
                            ),
                            child: const CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColors.primaryLight,
                              child: Text(
                                'R',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Welcome to Rini's Collection ✨",
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const Text(
                                'Lemari digital & manajemen barang pribadi',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Search bar trigger
                      Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0A3D2C2E),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (value) {
                            if (value.trim().isNotEmpty) {
                              widget.onSearchCollection(value.trim());
                            }
                          },
                          decoration: InputDecoration(
                            hintText: 'Cari baju, hijab, tas, atau sepatu...',
                            hintStyle: const TextStyle(fontSize: 12, color: AppColors.textLight),
                            prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.primary),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.arrow_forward_rounded, size: 18, color: AppColors.primary),
                              onPressed: () {
                                if (_searchController.text.trim().isNotEmpty) {
                                  widget.onSearchCollection(_searchController.text.trim());
                                }
                              },
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Content Body
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),

                    // Quick Action Shortcuts
                    Row(
                      children: [
                        _buildQuickAction(
                          icon: Icons.add_circle_outline_rounded,
                          title: 'Tambah Barang',
                          color: AppColors.primary,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AddEditItemScreen()),
                            ).then((_) => _refresh());
                          },
                        ),
                        const SizedBox(width: 12),
                        _buildQuickAction(
                          icon: Icons.inventory_2_outlined,
                          title: 'Jelajah Lokasi',
                          color: const Color(0xFF8B6B9B),
                          onTap: () => widget.onNavigateTab(2), // Locations tab
                        ),
                        const SizedBox(width: 12),
                        _buildQuickAction(
                          icon: Icons.local_laundry_service_outlined,
                          title: 'Area Laundry',
                          color: const Color(0xFFD67B8E),
                          onTap: () => widget.onNavigateTab(3), // Laundry tab
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Status Summary Section
                    Text(
                      'Ringkasan Koleksi',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Status Cards Row / Grid
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatusCard(
                            title: 'Available',
                            count: dashboard?.summary.available ?? 0,
                            icon: Icons.check_circle_outline_rounded,
                            bg: AppColors.statusAvailableBg,
                            textCol: AppColors.statusAvailableText,
                            onTap: () => widget.onFilterStatus('Available'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildStatusCard(
                            title: 'In Use',
                            count: dashboard?.summary.inUse ?? 0,
                            icon: Icons.accessibility_new_rounded,
                            bg: AppColors.statusInUseBg,
                            textCol: AppColors.statusInUseText,
                            onTap: () => widget.onFilterStatus('In Use'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatusCard(
                            title: 'In Laundry',
                            count: dashboard?.summary.inLaundry ?? 0,
                            icon: Icons.local_laundry_service_outlined,
                            bg: AppColors.statusInLaundryBg,
                            textCol: AppColors.statusInLaundryText,
                            onTap: () => widget.onFilterStatus('In Laundry'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildStatusCard(
                            title: 'Ready to Store',
                            count: dashboard?.summary.readyToStore ?? 0,
                            icon: Icons.iron_outlined,
                            bg: AppColors.statusReadyToStoreBg,
                            textCol: AppColors.statusReadyToStoreText,
                            onTap: () => widget.onFilterStatus('Ready to Store'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Laundry Alert Banners
                    if ((dashboard?.summary.readyToStore ?? 0) > 0)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.statusReadyToStoreBg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.statusReadyToStoreBorder),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.iron_outlined,
                                color: AppColors.statusReadyToStoreText,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${dashboard!.summary.readyToStore} Barang Selesai Dicuci',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: AppColors.statusReadyToStoreText,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Barang bersih menunggu disimpan kembali ke lemari',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () => widget.onNavigateTab(3),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.statusReadyToStoreText,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                              ),
                              child: const Text('Simpan >', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),

                    if ((dashboard?.summary.inLaundry ?? 0) > 0)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.statusInLaundryBg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.statusInLaundryBorder),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.local_laundry_service_outlined,
                                color: AppColors.statusInLaundryText,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${dashboard!.summary.inLaundry} Barang Sedang Dicuci',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: AppColors.statusInLaundryText,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Pantau proses pencucian pakaian di Laundry Tracker',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () => widget.onNavigateTab(3),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.statusInLaundryText,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                              ),
                              child: const Text('Lihat >', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Recent Items Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Barang Terbaru',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        TextButton(
                          onPressed: () => widget.onNavigateTab(1), // Collection tab
                          child: const Text(
                            'Lihat Semua',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Recent Items Grid
                    if (collectionProvider.items.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            const Icon(
                              Icons.checkroom_outlined,
                              size: 40,
                              color: AppColors.primary,
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Belum ada koleksi tersimpan',
                              style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Mulai mencatat koleksi pakaian dan barang pribadimu',
                              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const AddEditItemScreen()),
                                ).then((_) => _refresh());
                              },
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Tambah Barang Pertama'),
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
                        itemCount: collectionProvider.items.length > 6 ? 6 : collectionProvider.items.length,
                        itemBuilder: (context, index) {
                          final item = collectionProvider.items[index];
                          return ItemCard(
                            item: item,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ItemDetailScreen(itemId: item.id),
                                ),
                              ).then((_) => _refresh());
                            },
                          );
                        },
                      ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x063D2C2E),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard({
    required String title,
    required int count,
    required IconData icon,
    required Color bg,
    required Color textCol,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: textCol),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    count.toString(),
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
