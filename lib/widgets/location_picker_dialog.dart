import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/storage_location.dart';
import '../providers/location_provider.dart';
import '../theme/app_colors.dart';

class LocationPickerDialog extends StatefulWidget {
  final String? initialSelectedId;
  final String title;

  const LocationPickerDialog({
    super.key,
    this.initialSelectedId,
    this.title = 'Pilih Lokasi Penyimpanan',
  });

  static Future<StorageLocation?> show(
    BuildContext context, {
    String? initialSelectedId,
    String title = 'Pilih Lokasi Penyimpanan',
  }) {
    return showModalBottomSheet<StorageLocation>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LocationPickerDialog(
        initialSelectedId: initialSelectedId,
        title: title,
      ),
    );
  }

  @override
  State<LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<LocationPickerDialog> {
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.initialSelectedId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationProvider>().fetchLocations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = context.watch<LocationProvider>();
    final locations = locationProvider.locations;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          // Locations List
          Expanded(
            child: locationProvider.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : locations.isEmpty
                    ? const Center(
                        child: Text(
                          'Belum ada lokasi penyimpanan',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      )
                    : ListView.builder(
                        itemCount: locations.length,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemBuilder: (context, index) {
                          final loc = locations[index];
                          final isSelected = loc.id == _selectedId;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Material(
                              color: isSelected
                                  ? AppColors.primaryLight
                                  : AppColors.background,
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () {
                                  setState(() {
                                    _selectedId = loc.id;
                                  });
                                  Navigator.pop(context, loc);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppColors.primary
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          _getLocationIcon(loc.locationType),
                                          size: 18,
                                          color: isSelected
                                              ? Colors.white
                                              : AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              loc.name,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.w500,
                                                color: isSelected
                                                    ? AppColors.primaryDark
                                                    : AppColors.textDark,
                                              ),
                                            ),
                                            if (loc.description != null &&
                                                loc.description!.isNotEmpty)
                                              Text(
                                                loc.description!,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors.textMuted,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                          ],
                                        ),
                                      ),
                                      if (loc.locationType != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: AppColors.border,
                                            ),
                                          ),
                                          child: Text(
                                            loc.locationType!,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: AppColors.textMuted,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      if (isSelected) ...[
                                        const SizedBox(width: 8),
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          color: AppColors.primary,
                                          size: 20,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  IconData _getLocationIcon(String? type) {
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
