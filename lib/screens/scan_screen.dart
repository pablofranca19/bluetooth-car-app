import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

// Importando o serviço verdadeiro de onde ele deve estar!
import 'package:bluetooth_car_app/services/ble_service.dart'; 
import 'package:bluetooth_car_app/screens/control_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final BleService _bleService = BleService();

  @override
  void dispose() {
    _bleService.dispose();
    super.dispose();
  }

 
  void _handleConnection(BluetoothDevice device) async {
    if (_bleService.isScanning) {
      await _bleService.stopScan();
    }

    bool success = await _bleService.connectToDevice(device);
    
    if (success && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ControlScreen(bleService: _bleService),
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
   
    return ListenableBuilder(
      listenable: _bleService,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(title: const Text('BLE Scan')),
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 150,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_bleService.status, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        if (_bleService.isScanning) {
                          await _bleService.stopScan();
                        } else {
                          await _bleService.startScan();
                        }
                      },
                      child: Text(_bleService.isScanning ? 'Parar scan' : 'Escanear'),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: StreamBuilder<List<ScanResult>>(
                  stream: FlutterBluePlus.scanResults,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('Nenhum dispositivo encontrado.'));
                    }

                    final devices = snapshot.data!
                        .where((r) => r.device.platformName.isNotEmpty)
                        .toList();

                    return ListView.builder(
                      itemCount: devices.length,
                      padding: const EdgeInsets.all(8.0),
                      itemBuilder: (context, index) {
                        final device = devices[index].device;
                        return ListTile(
                          leading: const Icon(Icons.bluetooth),
                          title: Text(device.platformName),
                          trailing: ElevatedButton(
                            onPressed: () => _handleConnection(device),
                            child: const Text('Conectar'),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}