
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ScanScreen extends StatefulWidget {

  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();

}

class _ScanScreenState extends State<ScanScreen> {

  bool _isBluetoothActive = false;
  List<ScanResult> _devices = [];
  String _status = '';
  BluetoothDevice? _device;
  StreamSubscription? _subscription;

  @override
  void initState(){
    super.initState();
    _checkBluetooth();
  }

  @override
  void dispose() {
    _subscription?.cancel();
     super.dispose();
  }


  Future<void> _checkBluetooth() async {
    var isSupported = await FlutterBluePlus.isSupported;
    if (!isSupported) {
      print('Esse dispositivo não é compatível com o Bluetooth!');
      setState(() => _status = 'Dispositivo não compatível!');
      return;
    }
    _listenAdapterState();
  }

  void _listenAdapterState() {
    _subscription = FlutterBluePlus.adapterState.listen((state) {
      setState(() {
        if (state == BluetoothAdapterState.on) {
        _isBluetoothActive = true;
        _status = 'Bluetooth ativo.';
      } else {
        _isBluetoothActive = false;
        _status = 'Bluetooth desligado.';
      }
      });
    });
  }


  Widget build(BuildContext buildContext) {
    return Scaffold(
      appBar: AppBar(title: const Text('BLE Controller'),),
      body: const Center(child: Text('Olá!'),),
    );
  } 

}