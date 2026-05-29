import 'package:flutter/material.dart';
import 'package:bluetooth_car_app/services/ble_service.dart';

class ControlScreen extends StatelessWidget {
  final BleService bleService;

  const ControlScreen({super.key, required this.bleService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Controle do Carrinho'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bluetooth_disabled, color: Colors.red),
            onPressed: () async {
              await bleService.disconnect();
              if (!context.mounted) return;
              Navigator.pop(context); 
            },
          )
        ],
      ),
      body: ListenableBuilder(
        listenable: bleService,
        builder: (context, child) {
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: bleService.connectedDevice != null ? Colors.green.shade100 : Colors.red.shade100,
                width: double.infinity,
                child: Text(
                  bleService.status,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              
              const Spacer(),

              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  
                  _ControlButton(
                    label: 'Frente', 
                    icon: Icons.arrow_upward, 
                    command: 'F', 
                    bleService: bleService,
                  ),
                  const SizedBox(height: 10),
                  
                 
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ControlButton(
                        label: 'Esq', 
                        icon: Icons.turn_left, 
                        command: 'L', 
                        bleService: bleService,
                      ),
                      const SizedBox(width: 20),
                  
                      _ControlButton(
                        label: 'Parar', 
                        icon: Icons.stop, 
                        command: 'S', 
                        color: Colors.red, 
                        bleService: bleService,
                      ),
                      const SizedBox(width: 20),
                      _ControlButton(
                        label: 'Dir', 
                        icon: Icons.turn_right, 
                        command: 'R', 
                        bleService: bleService,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  
                  // Botão Baixo
                  _ControlButton(
                    label: 'Trás', 
                    icon: Icons.arrow_downward, 
                    command: 'B', 
                    bleService: bleService,
                  ),
                ],
              ),
              const Spacer(),
            ],
          );
        }
      ),
    );
  }
}


class _ControlButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final String command;
  final Color color;
  final BleService bleService;

  const _ControlButton({
    required this.label,
    required this.icon,
    required this.command,
    this.color = Colors.blue,
    required this.bleService,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      
      onTapDown: (_) { 
        bleService.sendCommand(command); 
      },
      onTapUp: (_) { 
        bleService.sendCommand('S'); 
      },
      onTapCancel: () { 
        bleService.sendCommand('S'); 
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.2 * 255).round()),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 36),
            Text(
              label, 
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}