import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/collection_item.dart';
import '../providers/collection_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_button.dart';
import '../widgets/location_picker_dialog.dart';

class AddEditItemScreen extends StatefulWidget {
  final CollectionItem? itemToEdit;

  const AddEditItemScreen({super.key, this.itemToEdit});

  @override
  State<AddEditItemScreen> createState() => _AddEditItemScreenState();
}

class _AddEditItemScreenState extends State<AddEditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _colorController;
  late TextEditingController _brandController;
  late TextEditingController _sizeController;
  late TextEditingController _positionController;
  late TextEditingController _notesController;

  String? _selectedCategoryId;
  String? _selectedLocationId;
  String? _selectedLocationName;
  String _selectedStatus = 'Available';

  String? _imageUrl;
  File? _localImageFile;
  bool _isUploadingImage = false;
  bool _isSaving = false;

  final List<String> _statusList = [
    'Available',
    'In Use',
    'In Laundry',
    'Ready to Store',
    'Unavailable',
  ];

  @override
  void initState() {
    super.initState();
    final item = widget.itemToEdit;
    _nameController = TextEditingController(text: item?.name ?? '');
    _colorController = TextEditingController(text: item?.color ?? '');
    _brandController = TextEditingController(text: item?.brand ?? '');
    _sizeController = TextEditingController(text: item?.size ?? '');
    _positionController = TextEditingController(text: item?.positionDetail ?? '');
    _notesController = TextEditingController(text: item?.notes ?? '');

    _selectedCategoryId = item?.categoryId;
    _selectedLocationId = item?.currentLocationId;
    _selectedLocationName = item?.currentLocation?.name;
    _selectedStatus = item?.availabilityStatus ?? 'Available';
    _imageUrl = item?.imageUrl;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final catProvider = context.read<CollectionProvider>();
      catProvider.loadCategories();
      if (_selectedCategoryId == null && catProvider.categories.isNotEmpty) {
        setState(() {
          _selectedCategoryId = catProvider.categories.first.id;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _colorController.dispose();
    _brandController.dispose();
    _sizeController.dispose();
    _positionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (picked != null) {
        setState(() {
          _localImageFile = File(picked.path);
          _isUploadingImage = true;
        });

        // Upload to backend
        try {
          final uploadedUrl = await ApiService().uploadImage(picked.path);
          setState(() {
            _imageUrl = uploadedUrl;
            _isUploadingImage = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Foto berhasil diunggah ✨')),
            );
          }
        } catch (e) {
          setState(() {
            _isUploadingImage = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gagal upload gambar: ${e.toString().replaceAll("Exception: ", "")}')),
            );
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak dapat membuka kamera/galeri: $e')),
      );
    }
  }

  void _showImagePickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Pilih Foto Barang',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                title: const Text('Ambil dari Kamera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickLocation() async {
    final selected = await LocationPickerDialog.show(
      context,
      initialSelectedId: _selectedLocationId,
    );

    if (selected != null) {
      setState(() {
        _selectedLocationId = selected.id;
        _selectedLocationName = selected.name;
      });
    }
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih kategori barang')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final itemData = {
      'name': _nameController.text.trim(),
      'category_id': _selectedCategoryId,
      'image_url': _imageUrl ?? '',
      'color': _colorController.text.trim(),
      'brand': _brandController.text.trim(),
      'size': _sizeController.text.trim(),
      'current_location_id': _selectedLocationId,
      'position_detail': _positionController.text.trim(),
      'availability_status': _selectedStatus,
      'notes': _notesController.text.trim(),
    };

    bool success;
    if (widget.itemToEdit != null) {
      success = await context.read<CollectionProvider>().updateItem(widget.itemToEdit!.id, itemData);
    } else {
      success = await context.read<CollectionProvider>().addItem(itemData);
    }

    setState(() => _isSaving = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.itemToEdit != null
                ? 'Barang berhasil diperbarui ✨'
                : 'Barang berhasil ditambahkan ke koleksi ✨'),
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.read<CollectionProvider>().errorMessage ?? 'Gagal menyimpan barang'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CollectionProvider>().categories;
    final isEditing = widget.itemToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Barang' : 'Tambah Barang Baru'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Image Picker Box
            GestureDetector(
              onTap: _isUploadingImage ? null : _showImagePickerSheet,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border, width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x083D2C2E),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: _isUploadingImage
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: AppColors.primary),
                            SizedBox(height: 12),
                            Text(
                              'Mengunggah foto...',
                              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      )
                    : _localImageFile != null
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(_localImageFile!, fit: BoxFit.cover),
                              _buildChangePhotoOverlay(),
                            ],
                          )
                        : _imageUrl != null && _imageUrl!.isNotEmpty
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  CachedNetworkImage(
                                    imageUrl: _imageUrl!,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => _buildPlaceholder(),
                                  ),
                                  _buildChangePhotoOverlay(),
                                ],
                              )
                            : _buildPlaceholder(),
              ),
            ),

            const SizedBox(height: 24),

            // Nama Barang (Wajib)
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Barang *',
                hintText: 'Contoh: Blouse Floral Pastel',
                prefixIcon: Icon(Icons.label_outline, color: AppColors.primary),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama barang wajib diisi';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Kategori (Wajib)
            DropdownButtonFormField<String>(
              value: _selectedCategoryId,
              decoration: const InputDecoration(
                labelText: 'Kategori *',
                prefixIcon: Icon(Icons.category_outlined, color: AppColors.primary),
              ),
              items: categories.map((cat) {
                return DropdownMenuItem<String>(
                  value: cat.id,
                  child: Text(cat.name),
                );
              }).toList(),
              onChanged: (val) {
                setState(() => _selectedCategoryId = val);
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Kategori wajib dipilih';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Lokasi Penyimpanan
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _pickLocation,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Lokasi Penyimpanan',
                  prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.primary),
                  suffixIcon: Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
                ),
                child: Text(
                  _selectedLocationName ?? 'Pilih tempat penyimpanan',
                  style: TextStyle(
                    color: _selectedLocationName != null
                        ? AppColors.textDark
                        : AppColors.textLight,
                    fontSize: 14,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Posisi Spesifik
            TextFormField(
              controller: _positionController,
              decoration: const InputDecoration(
                labelText: 'Detail Posisi Barang',
                hintText: 'Contoh: Gantungan baris ke-3, Laci 1 sisi kanan',
                prefixIcon: Icon(Icons.my_location_outlined, color: AppColors.primary),
              ),
            ),

            const SizedBox(height: 16),

            // Status Ketersediaan
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Status Ketersediaan',
                prefixIcon: Icon(Icons.info_outline, color: AppColors.primary),
              ),
              items: _statusList.map((st) {
                return DropdownMenuItem<String>(
                  value: st,
                  child: Text(st),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedStatus = val);
              },
            ),

            const SizedBox(height: 16),

            // Warna & Merek (Row)
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _colorController,
                    decoration: const InputDecoration(
                      labelText: 'Warna',
                      hintText: 'Soft Pink',
                      prefixIcon: Icon(Icons.palette_outlined, color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _brandController,
                    decoration: const InputDecoration(
                      labelText: 'Merek / Brand',
                      hintText: 'Zara',
                      prefixIcon: Icon(Icons.sell_outlined, color: AppColors.primary),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Ukuran
            TextFormField(
              controller: _sizeController,
              decoration: const InputDecoration(
                labelText: 'Ukuran / Size',
                hintText: 'Contoh: M, 38, All Size',
                prefixIcon: Icon(Icons.straighten_outlined, color: AppColors.primary),
              ),
            ),

            const SizedBox(height: 16),

            // Catatan
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Catatan Tambahan',
                hintText: 'Bahan pakaian, cara pencucian, atau memo penting...',
                prefixIcon: Icon(Icons.notes_outlined, color: AppColors.primary),
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 30),

            // Tombol Simpan
            CustomButton(
              text: isEditing ? 'Simpan Perubahan' : 'Tambahkan ke Koleksi',
              icon: Icons.check,
              isLoading: _isSaving,
              onPressed: _saveItem,
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.primaryLight.withOpacity(0.5),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo_outlined, size: 40, color: AppColors.primary),
          SizedBox(height: 10),
          Text(
            'Ambil / Pilih Foto Barang',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Bantu kenali barang secara visual',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildChangePhotoOverlay() {
    return Positioned(
      bottom: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.65),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.photo_camera, size: 14, color: Colors.white),
            SizedBox(width: 6),
            Text(
              'Ubah Foto',
              style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
