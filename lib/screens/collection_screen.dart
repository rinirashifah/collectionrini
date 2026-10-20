import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/collection_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/empty_state.dart';
import '../widgets/item_card.dart';
import 'add_edit_item_screen.dart';
import 'item_detail_screen.dart';

class CollectionScreen extends StatefulWidget {
  final String? initialStatusFilter;
  final String? initialSearch;

  const CollectionScreen({
    super.key,
    this.initialStatusFilter,
    this.initialSearch,
  });

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<String> _statusOptions = [
    'Semua',
    'Available',
    'In Use',
    'In Laundry',
    'Ready to Store',
    'Unavailable',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialSearch != null) {
      _searchController.text = widget.initialSearch!;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CollectionProvider>();
      if (widget.initialStatusFilter != null) {
        provider.setStatusFilter(widget.initialStatusFilter);
      }
      if (widget.initialSearch != null && widget.initialSearch!.isNotEmpty) {
        provider.setSearchQuery(widget.initialSearch!);
      }
      provider.fetchItems();
      provider.loadCategories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddCategoryDialog() {
    final catController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Tambah Kategori Baru',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        content: TextField(
          controller: catController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Nama kategori (misal: Outerwear)',
            labelText: 'Kategori',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = catController.text.trim();
              if (name.isNotEmpty) {
                final success = await context.read<CollectionProvider>().addCategory(name);
                if (mounted) {
                  Navigator.pop(context);
                  if (!success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.read<CollectionProvider>().errorMessage ?? 'Gagal menambah kategori')),
                    );
                  }
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final collectionProvider = context.watch<CollectionProvider>();
    final items = collectionProvider.items;
    final categories = collectionProvider.categories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Collection'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
            tooltip: 'Tambah Kategori',
            onPressed: _showAddCategoryDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => collectionProvider.setSearchQuery(value),
                decoration: InputDecoration(
                  hintText: 'Cari nama, merek, warna...',
                  hintStyle: const TextStyle(fontSize: 13, color: AppColors.textLight),
                  prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.primary),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18, color: AppColors.textLight),
                          onPressed: () {
                            _searchController.clear();
                            collectionProvider.setSearchQuery('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),

          // Horizontal Category Pills
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // "Semua" pill
                _buildCategoryPill(
                  title: 'Semua Kategori',
                  isSelected: collectionProvider.selectedCategoryId == null,
                  onTap: () => collectionProvider.setCategoryFilter(null),
                ),
                ...categories.map((cat) {
                  final isSelected = collectionProvider.selectedCategoryId == cat.id;
                  return _buildCategoryPill(
                    title: cat.name,
                    isSelected: isSelected,
                    onTap: () => collectionProvider.setCategoryFilter(cat.id),
                  );
                }),
                // Quick add category pill
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: _showAddCategoryDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primary.withOpacity(0.5)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.add, size: 14, color: AppColors.primary),
                          SizedBox(width: 4),
                          Text(
                            'Kategori',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Horizontal Status Filter Chips
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _statusOptions.map((statusName) {
                final isAll = statusName == 'Semua';
                final isSelected = isAll
                    ? collectionProvider.selectedStatus == null
                    : collectionProvider.selectedStatus == statusName;

                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(statusName),
                    selected: isSelected,
                    onSelected: (_) {
                      collectionProvider.setStatusFilter(isAll ? null : statusName);
                    },
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white : AppColors.textDark,
                    ),
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.border,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 12),

          // Items Grid / List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => collectionProvider.fetchItems(),
              color: AppColors.primary,
              child: collectionProvider.isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : items.isEmpty
                      ? EmptyState(
                          icon: Icons.inventory_2_outlined,
                          title: 'Barang Tidak Ditemukan',
                          message: collectionProvider.searchQuery.isNotEmpty ||
                                  collectionProvider.selectedCategoryId != null ||
                                  collectionProvider.selectedStatus != null
                              ? 'Tidak ada barang yang cocok dengan filter atau pencarian Anda.'
                              : 'Koleksi masih kosong. Tambahkan barang pertamamu sekarang!',
                          buttonText: collectionProvider.searchQuery.isNotEmpty ||
                                  collectionProvider.selectedCategoryId != null ||
                                  collectionProvider.selectedStatus != null
                              ? 'Hapus Filter'
                              : 'Tambah Barang',
                          onButtonPressed: () {
                            if (collectionProvider.searchQuery.isNotEmpty ||
                                collectionProvider.selectedCategoryId != null ||
                                collectionProvider.selectedStatus != null) {
                              _searchController.clear();
                              collectionProvider.clearFilters();
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AddEditItemScreen(),
                                ),
                              ).then((_) => collectionProvider.fetchItems());
                            }
                          },
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
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
                                  MaterialPageRoute(
                                    builder: (context) => ItemDetailScreen(itemId: item.id),
                                  ),
                                ).then((_) => collectionProvider.fetchItems());
                              },
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEditItemScreen()),
          ).then((_) => collectionProvider.fetchItems());
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryPill({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.textDark,
            ),
          ),
        ),
      ),
    );
  }
}
