
import 'dart:async';

import 'package:bluetooth_car_app/screens/control_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ScanScreen extends StatefulWidget {

  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();

}

class _ScanScreenState extends State<ScanScreen> {

  bool _isBluetoothActive = false;
  bool _isScanning = false;
  String _status = '';
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

  Future<void> _startScan() async {
    try {
    setState(() {
    _isScanning = true;
    _status = 'Escaneando dispositivos próximos...';  
    });
    await FlutterBluePlus.startScan(timeout: Duration(seconds: 5));
    setState(() {
      _isScanning = false;
      _status = 'Scan completo!';
    });
    } catch (error) {
      setState(() => _status = 'Erro ao iniciar scan, verifique se concedeu permissão ao app para usar o Bluetooth.');
    }
  }

  Future<void> _stopScan () async {
    try {
    await FlutterBluePlus.stopScan();
    setState(() {
    _isScanning = false;
    _status = 'Scan interrompido!';  
    });
    } catch (error) {
      setState(() => _status = 'Não foi possível parar o scan, espere alguns segundos e tente novamente.');
    }
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

  Future<void> _connectToDevice (BluetoothDevice device) async {
    setState(() => _status = 'Conectando a(o) ${device.platformName}...');
    try {
    await device.connect(license: License.free, timeout: Duration(seconds: 10));
    } catch (error) {
      setState(() => _status = 'Erro ao tentar conexão no dispositivo com ID:  ${device.remoteId}.');
    }
    if (mounted) {
      setState(() {
      _status = 'Conectado ao dispositivo!';
    });
    Navigator.push(context, MaterialPageRoute(builder:(context) => ControlScreen(device: device)));
    }
  }

  @override
  Widget build(BuildContext buildContext) {
    return Scaffold(
      appBar: AppBar(title: const Text('BLE Scan'),),
      body: Column(children: 
      [Text(_status) ,ElevatedButton(onPressed: () => _isScanning ? _stopScan() : _startScan() ,child: Text(_isScanning ? 'Parar scan' : 'Escanear')), Expanded(child: StreamBuilder(stream: FlutterBluePlus.scanResults, builder: (buildContext, snapshot) {
        if (!snapshot.hasData) {
          return Text('Nenhum dispositivo encontrado.');
        } else {
          final devices = snapshot.data!.where((name) => name.device.platformName.isNotEmpty).toList(); // o ! é um assert operator que garante null-safety.
          return ListView.builder(itemCount: devices.length ,padding: const EdgeInsets.all(8.0) ,itemBuilder: (context, index) {
            final device = devices[index].device;
            return ListTile(leading: Icon(Icons.bluetooth), title: Text(device.platformName), trailing: ElevatedButton(onPressed: () => _connectToDevice(device), child: Text('Conectar ao dispositivo')),);
          },);
        }
      }))],));
  } 

}