import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyVehiclesScreen extends StatefulWidget {
  const MyVehiclesScreen({super.key});

  @override
  State<MyVehiclesScreen> createState() => _MyVehiclesScreenState();
}

class _MyVehiclesScreenState extends State<MyVehiclesScreen> {
  final List<Map<String, String>> _vehicles = [];
  String? _defaultPlate;
  SharedPreferences? _prefs;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    setState(() => _isLoading = true);
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs?.getString('vehicles');
    _defaultPlate = _prefs?.getString('defaultVehicle');

    _vehicles.clear();
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        _vehicles.addAll(list.map((e) => Map<String, String>.from(e as Map)));
      } catch (_) {}
    }

    // Default sample if completely empty on first launch
    if (_vehicles.isEmpty) {
      _vehicles.add({
        'plate': 'TN09AB1234',
        'type': 'Sedan',
        'label': 'My Honda City',
      });
      _defaultPlate ??= 'TN09AB1234';
      _save();
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _save() async {
    await _prefs?.setString('vehicles', jsonEncode(_vehicles));
    if (_defaultPlate != null) {
      await _prefs?.setString('defaultVehicle', _defaultPlate!);
    }
  }

  Future<void> _setDefaultVehicle(String plate) async {
    setState(() {
      _defaultPlate = plate;
    });
    await _prefs?.setString('defaultVehicle', plate);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$plate set as primary vehicle for reservations'),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF005DAC),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _showAddVehicleDialog({Map<String, String>? initial, int? editIndex}) async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _VehicleModalSheet(initial: initial),
    );

    if (result != null) {
      setState(() {
        if (editIndex != null) {
          _vehicles[editIndex] = result;
        } else {
          _vehicles.add(result);
          _defaultPlate ??= result['plate'];
        }
      });
      await _save();
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Saved Vehicles',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 18),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  color: const Color(0xFFDBEAFE),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: Color(0xFF005DAC), size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your default vehicle will auto-fill at checkout. Swipe to delete.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF005DAC), fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _vehicles.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF1F5F9),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.directions_car_filled_outlined, size: 48, color: Color(0xFF94A3B8)),
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'No saved vehicles yet',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF475569)),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Add your car or two-wheeler for 1-tap bookings',
                                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _vehicles.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final v = _vehicles[index];
                            final plate = v['plate'] ?? '';
                            final label = v['label'] ?? 'Vehicle';
                            final type = v['type'] ?? 'Sedan';
                            final isDefault = plate == _defaultPlate;

                            return Dismissible(
                              key: Key(plate + index.toString()),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    SizedBox(width: 8),
                                    Icon(Icons.delete_sweep_rounded, color: Colors.white),
                                  ],
                                ),
                              ),
                              onDismissed: (direction) {
                                final removed = _vehicles.removeAt(index);
                                if (isDefault && _vehicles.isNotEmpty) {
                                  _defaultPlate = _vehicles.first['plate'];
                                }
                                _save();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${removed['label']} removed'),
                                    action: SnackBarAction(
                                      label: 'Undo',
                                      textColor: Colors.amber,
                                      onPressed: () {
                                        setState(() {
                                          _vehicles.insert(index, removed);
                                          if (isDefault) _defaultPlate = plate;
                                        });
                                        _save();
                                      },
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDefault ? const Color(0xFF005DAC) : const Color(0xFFE2E8F0),
                                    width: isDefault ? 1.5 : 1.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.02),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: isDefault ? const Color(0xFFDBEAFE) : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        type == 'Motorcycle'
                                            ? Icons.two_wheeler_rounded
                                            : type == 'EV'
                                                ? Icons.electric_car_rounded
                                                : type == 'SUV'
                                                    ? Icons.directions_car_filled
                                                    : Icons.directions_car_rounded,
                                        color: isDefault ? const Color(0xFF005DAC) : const Color(0xFF64748B),
                                        size: 26,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                label,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                              ),
                                              if (isDefault) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFDCFCE7),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: const Text(
                                                    'DEFAULT',
                                                    style: TextStyle(
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.w900,
                                                      color: Color(0xFF166534),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            plate,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              letterSpacing: 0.5,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF475569),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        isDefault ? Icons.star_rounded : Icons.star_border_rounded,
                                        color: isDefault ? const Color(0xFFEAB308) : const Color(0xFFCBD5E1),
                                        size: 24,
                                      ),
                                      tooltip: isDefault ? 'Default Vehicle' : 'Set as Default',
                                      onPressed: () => _setDefaultVehicle(plate),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: Color(0xFF94A3B8), size: 20),
                                      onPressed: () => _showAddVehicleDialog(initial: v, editIndex: index),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF005DAC),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add New Vehicle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      onPressed: () => _showAddVehicleDialog(),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _VehicleModalSheet extends StatefulWidget {
  final Map<String, String>? initial;

  const _VehicleModalSheet({this.initial});

  @override
  State<_VehicleModalSheet> createState() => _VehicleModalSheetState();
}

class _VehicleModalSheetState extends State<_VehicleModalSheet> {
  final _labelCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  String _selectedType = 'Sedan';

  final List<String> _types = ['Sedan', 'SUV', 'Hatchback', 'EV', 'Motorcycle'];

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      _labelCtrl.text = widget.initial!['label'] ?? '';
      _plateCtrl.text = widget.initial!['plate'] ?? '';
      _selectedType = widget.initial!['type'] ?? 'Sedan';
    }
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _plateCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final label = _labelCtrl.text.trim();
    final plate = _plateCtrl.text.trim().replaceAll(' ', '').toUpperCase();

    if (plate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a license plate number.')),
      );
      return;
    }

    Navigator.pop(context, {
      'label': label.isNotEmpty ? label : 'My Vehicle',
      'plate': plate,
      'type': _selectedType,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.initial == null ? 'Add Vehicle' : 'Edit Vehicle',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text('Nickname / Model', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
          const SizedBox(height: 4),
          TextField(
            controller: _labelCtrl,
            decoration: InputDecoration(
              hintText: 'e.g. Red Swift, Honda City',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text('License Plate Number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
          const SizedBox(height: 4),
          TextField(
            controller: _plateCtrl,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s]')),
              LengthLimitingTextInputFormatter(13),
            ],
            decoration: InputDecoration(
              hintText: 'e.g. TN09AB1234',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Vehicle Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: _types.map((type) {
              final isSel = _selectedType == type;
              return ChoiceChip(
                label: Text(type),
                selected: isSel,
                selectedColor: const Color(0xFFDBEAFE),
                labelStyle: TextStyle(
                  color: isSel ? const Color(0xFF005DAC) : const Color(0xFF475569),
                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (val) {
                  if (val) setState(() => _selectedType = type);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF005DAC),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _submit,
            child: const Text('Save Vehicle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ],
      ),
    );
  }
}
