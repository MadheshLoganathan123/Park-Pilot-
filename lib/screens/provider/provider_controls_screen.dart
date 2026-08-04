import 'package:flutter/material.dart';
import '../../services/parking_data_service.dart';

class ProviderControlsScreen extends StatelessWidget {
  const ProviderControlsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dataService = ParkingDataService();

    return AnimatedBuilder(
      animation: dataService,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Surge Control', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          body: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Enable Surge Pricing'),
                  value: dataService.isSurgePricingEnabled,
                  onChanged: (val) {
                    dataService.updateSurge(val, dataService.surgeMultiplier);
                  },
                ),
                const SizedBox(height: 20),
                const Text('Surge Multiplier'),
                Slider(
                  value: dataService.surgeMultiplier,
                  min: 1.0,
                  max: 2.5,
                  divisions: 15,
                  label: '${dataService.surgeMultiplier}x',
                  onChanged: (val) {
                    dataService.updateSurge(dataService.isSurgePricingEnabled, val);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
