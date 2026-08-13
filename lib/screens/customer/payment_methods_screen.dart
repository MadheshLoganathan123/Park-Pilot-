import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final List<String> _methods = [];
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs?.getString('payment_methods');
    if (raw != null && raw.isNotEmpty) {
      final list = jsonDecode(raw) as List<dynamic>;
      setState(() => _methods.addAll(list.map((e) => e as String)));
    }
  }

  Future<void> _save() async {
    await _prefs?.setString('payment_methods', jsonEncode(_methods));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Methods')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _methods.isEmpty
                  ? const Center(child: Text('No payment methods added.'))
                  : ListView.builder(
                      itemCount: _methods.length,
                      itemBuilder: (context, i) => ListTile(
                        leading: const Icon(Icons.payment_outlined, color: Color(0xFF005DAC)),
                        title: Text(_methods[i]),
                        trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => setState(() => _methods.removeAt(i))),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF005DAC), foregroundColor: Colors.white),
                icon: const Icon(Icons.add),
                label: const Text('Add Payment Method'),
                onPressed: _addMethod,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addMethod() async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Add Payment Method'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Description (e.g., Visa ****1234)')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(c, ctrl.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) setState(() {
      _methods.add(result);
      _save();
    });
  }
}
