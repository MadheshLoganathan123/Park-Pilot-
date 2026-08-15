import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/parking_lot.dart';
import '../../services/osm_map_service.dart';
import '../../services/parking_data_service.dart';

class ManageParkingSpaceScreen extends StatefulWidget {
  final ParkingLot? existingLot;

  const ManageParkingSpaceScreen({
    super.key,
    this.existingLot,
  });

  @override
  State<ManageParkingSpaceScreen> createState() => _ManageParkingSpaceScreenState();
}

class _ManageParkingSpaceScreenState extends State<ManageParkingSpaceScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _slotsController;
  late TextEditingController _priceController;
  late TextEditingController _hoursController;
  late TextEditingController _descController;
  late TextEditingController _latController;
  late TextEditingController _lngController;

  String _selectedType = 'COVERED';
  bool _isSaving = false;
  bool _isDeleting = false;

  bool get _isEditing => widget.existingLot != null;

  @override
  void initState() {
    super.initState();
    final lot = widget.existingLot;

    _nameController = TextEditingController(text: lot?.name ?? '');
    _addressController = TextEditingController(text: lot?.address ?? '');
    _slotsController = TextEditingController(text: lot != null ? '${lot.totalSlotsCount}' : '50');
    _priceController = TextEditingController(text: lot != null ? '${lot.hourlyRate.toInt()}' : '50');
    _hoursController = TextEditingController(text: '24/7');
    _descController = TextEditingController(text: '');
    _latController = TextEditingController(text: lot != null ? '${lot.latitude}' : '13.0827');
    _lngController = TextEditingController(text: lot != null ? '${lot.longitude}' : '80.2707');

    if (lot != null) {
      final typeUpper = lot.type.toUpperCase().replaceAll('-', '_').replaceAll(' ', '_');
      if (['COVERED', 'MULTI_LEVEL', 'OPEN', 'VALET'].contains(typeUpper)) {
        _selectedType = typeUpper;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _slotsController.dispose();
    _priceController.dispose();
    _hoursController.dispose();
    _descController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final dataService = ParkingDataService();

    try {
      final name = _nameController.text.trim();
      final address = _addressController.text.trim();
      final totalSlots = int.tryParse(_slotsController.text.trim()) ?? 50;
      final pricePerHour = double.tryParse(_priceController.text.trim()) ?? 50.0;
      final hours = _hoursController.text.trim().isNotEmpty ? _hoursController.text.trim() : '24/7';
      final desc = _descController.text.trim();
      final lat = double.tryParse(_latController.text.trim()) ?? 13.0827;
      final lng = double.tryParse(_lngController.text.trim()) ?? 80.2707;

      if (_isEditing) {
        final success = await dataService.updateParkingSpaceApi(
          spaceId: widget.existingLot!.id,
          name: name,
          address: address,
          totalSlots: totalSlots,
          pricePerHour: pricePerHour,
          parkingType: _selectedType,
          operatingHours: hours,
          description: desc.isNotEmpty ? desc : null,
          latitude: lat,
          longitude: lng,
        );

        if (!mounted) return;
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Parking facility updated successfully!'),
              backgroundColor: Color(0xFF16A34A),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        final newLot = await dataService.createParkingSpaceApi(
          name: name,
          address: address,
          latitude: lat,
          longitude: lng,
          totalSlots: totalSlots,
          pricePerHour: pricePerHour,
          parkingType: _selectedType,
          operatingHours: hours,
          description: desc.isNotEmpty ? desc : null,
        );

        if (!mounted) return;
        if (newLot != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Parking Space "${newLot.name}" created successfully!'),
              backgroundColor: const Color(0xFF16A34A),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save space: ${e.toString().replaceFirst('Exception: ', '')}'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Parking Space', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to permanently remove "${widget.existingLot?.name}"? All associated bookings will be impacted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isDeleting = true);
    final dataService = ParkingDataService();

    try {
      final success = await dataService.deleteParkingSpaceApi(widget.existingLot!.id);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Parking space deleted.'),
            backgroundColor: Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete space: $e'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditing ? 'Edit Parking Facility' : 'Add Parking Facility',
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          if (_isEditing)
            IconButton(
              icon: _isDeleting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFEF4444)))
                  : const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
              tooltip: 'Delete Parking Space',
              onPressed: _isDeleting || _isSaving ? null : _handleDelete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF005DAC), Color(0xFF0284C7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF005DAC).withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.local_parking_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEditing ? 'Update Space Details' : 'Onboard New Parking Lot',
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Changes reflect immediately in customer search & discovery',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Basic Info Section
              _buildSectionTitle('Basic Information'),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _nameController,
                label: 'Facility Name',
                hint: 'e.g. Nexus Grand Multi-Level Parking',
                icon: Icons.business_rounded,
                validator: (val) => val == null || val.trim().length < 3 ? 'Enter at least 3 characters' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _addressController,
                label: 'Complete Address',
                hint: 'e.g. 120 Anna Salai, Royapettah, Chennai',
                icon: Icons.location_on_outlined,
                maxLines: 2,
                validator: (val) => val == null || val.trim().length < 5 ? 'Enter a valid detailed address' : null,
              ),
              const SizedBox(height: 24),

              // Capacity & Pricing Section
              _buildSectionTitle('Capacity & Hourly Pricing'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _slotsController,
                      label: 'Total Capacity',
                      hint: '50',
                      icon: Icons.grid_view_rounded,
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        final numVal = int.tryParse(val ?? '');
                        if (numVal == null || numVal <= 0) return 'Must be > 0';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildTextField(
                      controller: _priceController,
                      label: 'Base Rate (₹/hr)',
                      hint: '50',
                      icon: Icons.currency_rupee_rounded,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (val) {
                        final numVal = double.tryParse(val ?? '');
                        if (numVal == null || numVal <= 0) return 'Must be > 0';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Parking Type & Schedule
              _buildSectionTitle('Parking Type & Operating Hours'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedType,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF005DAC)),
                    items: const [
                      DropdownMenuItem(value: 'COVERED', child: Text('Covered Parking')),
                      DropdownMenuItem(value: 'MULTI_LEVEL', child: Text('Multi-Level Complex')),
                      DropdownMenuItem(value: 'OPEN', child: Text('Open Lot Parking')),
                      DropdownMenuItem(value: 'VALET', child: Text('Valet Parking Service')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedType = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _hoursController,
                label: 'Operating Hours Summary',
                hint: '24/7 or Mon-Sat 08:00-23:00',
                icon: Icons.access_time_rounded,
              ),
              const SizedBox(height: 24),

              // Geolocation Coordinates & Interactive Map Pin Picker
              _buildSectionTitle('GPS Map Coordinates & Pin Location'),
              const SizedBox(height: 8),
              const Text(
                'Tap anywhere on the live map below or drag coordinates to set your facility entry point.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: StatefulBuilder(
                    builder: (context, setMapState) {
                      final currentLat = double.tryParse(_latController.text) ?? 13.0827;
                      final currentLng = double.tryParse(_lngController.text) ?? 80.2707;
                      final pinLocation = LatLng(currentLat, currentLng);

                      return FlutterMap(
                        options: MapOptions(
                          initialCenter: pinLocation,
                          initialZoom: 14.0,
                          onTap: (_, tappedPoint) {
                            setState(() {
                              _latController.text = tappedPoint.latitude.toStringAsFixed(6);
                              _lngController.text = tappedPoint.longitude.toStringAsFixed(6);
                            });
                            setMapState(() {});
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: OsmMapService.tileUrlTemplate,
                            userAgentPackageName: 'com.parkpilot.app',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: pinLocation,
                                width: 44,
                                height: 44,
                                child: const Icon(
                                  Icons.location_on_rounded,
                                  color: Color(0xFFEF4444),
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _latController,
                      label: 'Latitude',
                      hint: '13.0827',
                      icon: Icons.explore_outlined,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (val) => double.tryParse(val ?? '') == null ? 'Invalid Lat' : null,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildTextField(
                      controller: _lngController,
                      label: 'Longitude',
                      hint: '80.2707',
                      icon: Icons.explore_outlined,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (val) => double.tryParse(val ?? '') == null ? 'Invalid Lng' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _descController,
                label: 'Facility Highlights & Amenities Description',
                hint: 'e.g. CCTV monitored, EV Charging bay on Level 1, 24/7 Security.',
                icon: Icons.info_outline_rounded,
                maxLines: 2,
              ),
              const SizedBox(height: 32),

              // Save Action Button
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _handleSave,
                icon: _isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle_rounded, size: 20),
                label: Text(
                  _isSaving
                      ? 'Saving Facility Details...'
                      : (_isEditing ? 'Save Changes' : 'Create & Publish Parking Space'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF005DAC),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: Color(0xFF0F172A),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          icon: Icon(icon, color: const Color(0xFF005DAC), size: 20),
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
