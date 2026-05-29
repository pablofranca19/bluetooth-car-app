import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleService extends ChangeNotifier {
  bool isBluetoothActive = false;
  bool isScanning = false;
  String status = '';
  StreamSubscription? _subscription;

  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? _controlCharacteristic;

  final String characteristicUuid = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

  BleService() {
    _checkBluetooth();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    
    unawaited(stopScan());
    unawaited(disconnect());
    
    super.dispose();
  }

  Future<void> _checkBluetooth() async {
    var isSupported = await FlutterBluePlus.isSupported;
    if (!isSupported) {
      status = 'Dispositivo não compatível!';
      notifyListeners(); 
      return;
    }
    _listenAdapterState();
  }

  void _listenAdapterState() {
    _subscription = FlutterBluePlus.adapterState.listen((state) {
      if (state == BluetoothAdapterState.on) {
        isBluetoothActive = true;
        status = 'Bluetooth ativo.';
      } else {
        isBluetoothActive = false;
        status = 'Bluetooth desligado.';
      }
      notifyListeners();
    });
  }

  Future<void> startScan() async {
    try {
      isScanning = true;
      status = 'Escaneando dispositivos próximos...';
      notifyListeners();

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
      
      isScanning = false;
      status = 'Scan completo!';
      notifyListeners();
    } catch (error) {
      status = 'Erro ao iniciar scan. Verifique as permissões de Bluetooth.';
      isScanning = false;
      notifyListeners();
    }
  }

  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
      isScanning = false;
      status = 'Scan interrompido!';
      notifyListeners();
    } catch (error) {
      status = 'Não foi possível parar o scan. Tente novamente.';
      notifyListeners();
    }
  }

  Future<bool> connectToDevice(BluetoothDevice device) async {
    status = 'Conectando a(o) ${device.platformName}...';
    notifyListeners();

    try {
      await device.connect(license: License.free, timeout: const Duration(seconds: 10));
      connectedDevice = device;
      status = 'Conectado! Buscando serviços...';
      notifyListeners();
      
      await _discoverServices();
      
      return true; 
    } catch (error) {
      status = 'Erro ao tentar conexão no dispositivo com ID: ${device.remoteId}.';
      notifyListeners();
      return false; 
    }
  }

  Future<void> _discoverServices() async {
    if (connectedDevice == null) return;

    try {
      final services = await connectedDevice!.discoverServices();
      
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid.toString() == characteristicUuid) {
            _controlCharacteristic = characteristic;
            status = 'Carrinho pronto para controle!';
            notifyListeners();
            return; 
          }
        }
      }
      status = 'Erro: Característica de controle não encontrada.';
      notifyListeners();
    } catch (error) {
      status = 'Erro ao descobrir serviços do ESP32.';
      notifyListeners();
    }
  }

  Future<void> sendCommand(String cmd) async {
    if (_controlCharacteristic == null) return;
    
    List<int> bytes = cmd.codeUnits; 
    
    try {
      await _controlCharacteristic!.write(bytes, withoutResponse: true);
    } catch (error) {
      print("Erro ao enviar comando para o carrinho: $error");
    }
  }

  Future<void> disconnect() async {
    if (connectedDevice != null) {
      await connectedDevice!.disconnect();
      connectedDevice = null;
      _controlCharacteristic = null;
      status = 'Desconectado';
      notifyListeners();
    }
  }
}