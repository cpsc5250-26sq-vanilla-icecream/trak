import 'package:flutter/material.dart';
import '../widgets/inventory_list.dart';

class PowerupScreen extends StatelessWidget {
  const PowerupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Powerups')),
      body: const Padding(padding: EdgeInsets.all(16), child: InventoryList()),
    );
  }
}
