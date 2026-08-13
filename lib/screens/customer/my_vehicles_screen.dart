import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyVehiclesScreen extends StatefulWidget {
  const MyVehiclesScreen({super.key});

  @override
  State<MyVehiclesScreen> createState() => _MyVehiclesScreenState();
}

class _MyVehiclesScreenState extends State<MyVehiclesScreen> {
  final List<Map<String, String>> _vehicles = [];
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs?.getString('vehicles');
    if (raw != null && raw.isNotEmpty) {
      final list = jsonDecode(raw) as List<dynamic>;
      setState(() => _vehicles.addAll(list.map((e) => Map<String, String>.from(e as Map))));
    }
  }

  Future<void> _save() async {
    await _prefs?.setString('vehicles', jsonEncode(_vehicles));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Vehicles')), 
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _vehicles.isEmpty
                  ? const Center(child: Text('No vehicles yet. Tap + to add.'))
                  : ListView.builder(
                      itemCount: _vehicles.length,
                      itemBuilder: (context, i) {
                        final v = _vehicles[i];
                        return ListTile(
                          leading: const Icon(Icons.directions_car, color: Color(0xFF005DAC)),
                          title: Text(v['name'] ?? ''),
                          subtitle: Text(v['plate'] ?? ''),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _showEdit(i),
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF005DAC), foregroundColor: Colors.white),
                icon: const Icon(Icons.add),
                label: const Text('Add Vehicle'),
                onPressed: _addVehicle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addVehicle() async {
    final result = await showDialog<Map<String, String>>(context: context, builder: (c) => _vehicleDialog());
    if (result != null) setState(() {
      _vehicles.add(result);
      _save();
    });
  }

  void _showEdit(int index) async {
    final result = await showDialog<Map<String, String>>(context: context, builder: (c) => _vehicleDialog(initial: _vehicles[index]));
    if (result != null) setState(() {
      _vehicles[index] = result;
      _save();
    });
  }

  Widget _vehicleDialog({Map<String, String>? initial}) {
    final nameCtrl = TextEditingController(text: initial?['name']);
    final plateCtrl = TextEditingController(text: initial?['plate']);
    return AlertDialog(
      title: Text(initial == null ? 'Add Vehicle' : 'Edit Vehicle'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name (e.g., Swift)')),
          TextField(controller: plateCtrl, decoration: const InputDecoration(labelText: 'License plate')),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, {'name': nameCtrl.text.trim(), 'plate': plateCtrl.text.trim()}), child: const Text('Save')),
      ],
    );
  }
}
