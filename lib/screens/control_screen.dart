
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ControlScreen extends StatefulWidget {

  final BluetoothDevice device;
  final BluetoothCharacteristic bluetoothCharacteristic;  
  ControlScreen({super.key, required this.device, required this.bluetoothCharacteristic});

  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {

    @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.device.platformName)),
      body: const Center(child: Text('Tela de Controle — em breve')),
    );
  }
}