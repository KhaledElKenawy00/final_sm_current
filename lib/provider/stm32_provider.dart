import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:serial_port_win32/serial_port_win32.dart';
import 'package:flutter_sqlite_auth_app/SQLite/store_data.dart';

class STM32Provider with ChangeNotifier {
  SerialPort? _port;
  SerialPort? _secondPort;
  Timer? _pollingTimer;
  Timer? _secondPollingTimer;
  Timer? _stm2TimeoutTimer;

  List<double> emg1History = [];
  List<double> emg2History = [];
  List<double> emg3History = [];
  List<double> signalHistory = [];
  final int maxPoints = 100;
  int signalValue = 0;

  String latestData = 'Waiting for STM1 data...';
  String latestDataSTM2 = 'Waiting for STM32 2 data...';

  final List<String> logs = [];
  final DatabaseService _dbService = DatabaseService();
  String _buffer = '';

  bool _stm2IsSending = false;

  // Method to process the incoming data from STM32
  void _processSTMBuffer(String data) async {
    final jsonRegex = RegExp(r'\{[^}]*\}');

    for (final match in jsonRegex.allMatches(data)) {
      final jsonString = match.group(0);
      if (jsonString != null) {
        try {
          final jsonMap = jsonDecode(jsonString);
          if (jsonMap is Map<String, dynamic>) {
            final bool isSTM1 = jsonMap.containsKey('EMG1') ||
                jsonMap.containsKey('EMG2') ||
                jsonMap.containsKey('EMG3');

            final device = isSTM1 ? 'STM1' : 'STM2';

            if (device == 'STM1') {
              // Prevent storing EMG data while STM2 is sending
              if (_stm2IsSending) {
                print("⏳ STM2 is sending, skip EMG save...");
                return;
              }

              latestData = jsonString;

              final emg1 = (jsonMap['EMG1'] ?? 0).toDouble();
              final emg2 = (jsonMap['EMG2'] ?? 0).toDouble();
              final emg3 = (jsonMap['EMG3'] ?? 0).toDouble();

              emg1History.add(emg1);
              emg2History.add(emg2);
              emg3History.add(emg3);

              if (emg1History.length > maxPoints) emg1History.removeAt(0);
              if (emg2History.length > maxPoints) emg2History.removeAt(0);
              if (emg3History.length > maxPoints) emg3History.removeAt(0);

              signalValue = jsonMap['Signal_Value'] ?? 0;
              signalHistory.add(signalValue.toDouble());
              if (signalHistory.length > maxPoints) signalHistory.removeAt(0);

              logs.insert(0, "$device: $jsonString");
              if (logs.length > 100) logs.removeLast();

              notifyListeners();
              await _dbService.insertReadingSTM1(jsonMap);
              print("✅ Stored STM1 Data: $jsonMap");
            } else {
              // STM2 is sending, pause STM1 data saving
              _stm2IsSending = true;

              // Reset the timer to resume storing EMG data if STM2 stops sending for 1 second
              _stm2TimeoutTimer?.cancel();
              _stm2TimeoutTimer = Timer(const Duration(seconds: 1), () {
                _stm2IsSending = false;
                print("🟢 STM2 stopped, resume EMG storing.");
              });

              latestDataSTM2 = jsonString;

              signalValue = jsonMap['Signal_Value'] ?? 0;
              signalHistory.add(signalValue.toDouble());
              if (signalHistory.length > maxPoints) signalHistory.removeAt(0);

              logs.insert(0, "$device: $jsonString");
              if (logs.length > 100) logs.removeLast();

              notifyListeners();
              await _dbService.insertReadingSTM2(jsonMap);
              print("✅ Stored STM2 Data: $jsonMap");
            }
          }
        } catch (e) {
          print("⚠️ JSON parse error: $e");
        }
      }
    }
  }

  // Start listening for data from STM32 (first device)
  void startListening() {
    final ports = SerialPort.getAvailablePorts();
    if (ports.isEmpty) {
      print("❌ No serial ports found.");
      return;
    }

    _port = SerialPort(ports.first)
      ..BaudRate = 115200
      ..StopBits = 2
      ..ByteSize = 8
      ..Parity = 0;

    if (!_port!.isOpened) {
      _port!.open();
      if (_port!.isOpened) {
        print("✅ Port opened: ${_port!.portName}");
      } else {
        print("❌ Failed to open port: ${_port!.portName}");
        return;
      }
    }

    _pollingTimer =
        Timer.periodic(const Duration(milliseconds: 10), (timer) async {
      try {
        Uint8List data = await _port!
            .readBytes(1024, timeout: const Duration(milliseconds: 1));
        if (data.isNotEmpty) {
          final decoded = utf8.decode(data, allowMalformed: true);
          _buffer += decoded;
          _processMainBuffer();
        }
      } catch (e) {
        print("❌ Read error: $e");
      }
    });
  }

  // Process the main buffer
  void _processMainBuffer() {
    final jsonRegex = RegExp(r'\{[^}]*\}');
    for (final match in jsonRegex.allMatches(_buffer)) {
      final jsonString = match.group(0);
      if (jsonString != null) {
        _processSTMBuffer(jsonString);
      }
    }

    final lastMatch = jsonRegex.allMatches(_buffer).lastOrNull;
    if (lastMatch != null) {
      _buffer = _buffer.substring(lastMatch.end);
    }
  }

  // Start second STM32 device (STM2)
  void startSecondSTM32() {
    final ports = SerialPort.getAvailablePorts();
    if (ports.length < 2) {
      print("❌ Less than 2 ports available. Cannot start second STM32.");
      return;
    }

    _secondPort = SerialPort(ports[1])
      ..BaudRate = 115200
      ..StopBits = 2
      ..ByteSize = 8
      ..Parity = 0;

    if (!_secondPort!.isOpened) {
      _secondPort!.open();
      if (_secondPort!.isOpened) {
        print("✅ Second port opened: ${_secondPort!.portName}");
      } else {
        print("❌ Failed to open second port: ${_secondPort!.portName}");
        return;
      }
    }

    _secondPollingTimer =
        Timer.periodic(const Duration(milliseconds: 50), (timer) async {
      try {
        Uint8List data = await _secondPort!
            .readBytes(1024, timeout: const Duration(milliseconds: 1));
        if (data.isNotEmpty) {
          final decoded = utf8.decode(data, allowMalformed: true);
          _processSTMBuffer(decoded);
        }
      } catch (e) {
        print("❌ STM2 Read Error: $e");
      }
    });
  }

  // Dispose resources properly
  @override
  void dispose() {
    _pollingTimer?.cancel();
    _secondPollingTimer?.cancel();
    _stm2TimeoutTimer?.cancel();
    _port?.close();
    _secondPort?.close();
    super.dispose();
  }
}
