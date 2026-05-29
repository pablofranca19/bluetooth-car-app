#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>
#include <Arduino.h>

// UUIDs correspondentes ao aplicativo Flutter
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

// ====== ATENÇÃO: COLOQUE AQUI OS PINOS REAIS DA SUA PONTE H ======
#define ENA 13  // Pino PWM Motor A
#define ENB 12  // Pino PWM Motor B
#define IN1 14  // Sentido Motor A
#define IN2 27  // Sentido Motor A
#define IN3 26  // Sentido Motor B
#define IN4 25  // Sentido Motor B
// =================================================================

// Definição dos Estados da FSM (baseado no diagrama)
enum State {
  STATE_WAITING, // Aguardando conexão BLE
  STATE_IDLE,    // Conectado, carro parado
  STATE_MOVING,  // Executando comando F/B/L/R
  STATE_STOP,    // Comando S recebido, limpa e volta para Idle
  STATE_ERROR    // Conexão perdida, para motores
};

// Variáveis de controle de estado
State currentState = STATE_WAITING;
bool deviceConnected = false;
bool oldDeviceConnected = false;
String receivedCommand = "";

// Protótipos de funções de controle de motores
void pararMotores();
void moverFrente();
void moverTras();
void moverEsquerda();
void moverDireita();

// Callbacks do Servidor BLE para monitorar conexões
class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
    };

    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
    }
};

// Callbacks da Característica BLE para receber os comandos do Flutter
class MyCharacteristicCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      // CORREÇÃO: Usando String do Arduino para evitar o erro de conversão
      String value = pCharacteristic->getValue();
      if (value.length() > 0) {
        receivedCommand = value;
        Serial.print("Comando recebido: ");
        Serial.println(receivedCommand);
      }
    }
};

void setup() {
  Serial.begin(115200);

  // Configuração dos pinos da ponte H
  pinMode(ENA, OUTPUT);
  pinMode(ENB, OUTPUT);
  pinMode(IN1, OUTPUT);
  pinMode(IN2, OUTPUT);
  pinMode(IN3, OUTPUT);
  pinMode(IN4, OUTPUT);

  // Garante que os motores começam parados
  pararMotores();

  // Inicialização do BLE
  BLEDevice::init("ESP32_CarBot");
  BLEServer *pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  BLEService *pService = pServer->createService(SERVICE_UUID);
  BLECharacteristic *pCharacteristic = pService->createCharacteristic(
                                         CHARACTERISTIC_UUID,
                                         BLECharacteristic::PROPERTY_READ |
                                         BLECharacteristic::PROPERTY_WRITE
                                       );

  pCharacteristic->setCallbacks(new MyCharacteristicCallbacks());
  pService->start();

  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  BLEDevice::startAdvertising();

  Serial.println("FSM Inicializada. Estado: WAITING");
}

void loop() {
  // Execução da Máquina de Estados (FSM)
  switch (currentState) {

    case STATE_WAITING:
      if (deviceConnected) {
        Serial.println("Transição: Conectado! Indo para IDLE.");
        currentState = STATE_IDLE;
      }
      break;

    case STATE_IDLE:
      pararMotores();
      
      if (!deviceConnected) {
        currentState = STATE_ERROR;
        break;
      }

      if (receivedCommand == "F" || receivedCommand == "B" || 
          receivedCommand == "L" || receivedCommand == "R") {
        Serial.println("Transição: Comando de movimento recebido. Indo para MOVING.");
        currentState = STATE_MOVING;
      }
      break;

    case STATE_MOVING:
      if (!deviceConnected) {
        currentState = STATE_ERROR;
        break;
      }

      // Executa o movimento correspondente ao comando ativo
      if (receivedCommand == "F") moverFrente();
      else if (receivedCommand == "B") moverTras();
      else if (receivedCommand == "L") moverEsquerda();
      // CORREÇÃO: Mudado de rankedCommand para receivedCommand
      else if (receivedCommand == "R") moverDireita();

      if (receivedCommand == "S") {
        Serial.println("Transição: Comando S recebido. Indo para STOP.");
        currentState = STATE_STOP;
      }
      else if (receivedCommand == "") {
        Serial.println("Transição: Botão solto. Voltando para IDLE.");
        currentState = STATE_IDLE;
      }
      break;

    case STATE_STOP:
      pararMotores();
      receivedCommand = ""; 
      Serial.println("Transição: Comando S processado. Retornando para IDLE.");
      currentState = STATE_IDLE; 
      break;

    case STATE_ERROR:
      pararMotores(); 
      Serial.println("Transição: Conexão BLE perdida! Motores parados. Tentando reconectar...");
      receivedCommand = ""; 
      currentState = STATE_WAITING; 
      break;
  }

  // Gerenciamento de reconexão do Advertising do BLE
  if (!deviceConnected && oldDeviceConnected) {
    delay(500); 
    BLEDevice::startAdvertising(); 
    Serial.println("Sinal BLE reativado para novas conexões.");
    oldDeviceConnected = deviceConnected;
  }
  
  if (deviceConnected && !oldDeviceConnected) {
    oldDeviceConnected = deviceConnected;
  }

  delay(20); 
}

// --- Funções de Controle dos Motores ---
void pararMotores() {
  analogWrite(ENA, 0);
  analogWrite(ENB, 0);
  digitalWrite(IN1, LOW);
  digitalWrite(IN2, LOW);
  digitalWrite(IN3, LOW);
  digitalWrite(IN4, LOW);
}

void moverFrente() {
  analogWrite(ENA, 255);
  analogWrite(ENB, 255);
  digitalWrite(IN1, HIGH);
  digitalWrite(IN2, LOW);
  digitalWrite(IN3, HIGH);
  digitalWrite(IN4, LOW);
}

void moverTras() {
  analogWrite(ENA, 255);
  analogWrite(ENB, 255);
  digitalWrite(IN1, LOW);
  digitalWrite(IN2, HIGH);
  digitalWrite(IN3, LOW);
  digitalWrite(IN4, HIGH);
}

void moverEsquerda() {
  analogWrite(ENA, 255);
  analogWrite(ENB, 255);
  digitalWrite(IN1, LOW);
  digitalWrite(IN2, HIGH);
  digitalWrite(IN3, HIGH);
  digitalWrite(IN4, LOW);
}

void moverDireita() {
  analogWrite(ENA, 255);
  analogWrite(ENB, 255);
  digitalWrite(IN1, HIGH);
  digitalWrite(IN2, LOW);
  digitalWrite(IN3, LOW);
  digitalWrite(IN4, HIGH);
}