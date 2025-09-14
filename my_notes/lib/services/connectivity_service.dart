import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  bool _isConnected = false;
  bool _isCheckConnection = true;
  bool get isCheckConnection => _isCheckConnection;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool get isConnected => _isConnected;

  // Singleton pattern ile tek instance
  static ConnectivityService get instance => _instance;

  // Callback function to notify when connectivity changes
  Future<void> Function(bool isConnected)? _onConnectivityChanged;

  // Başlangıçta bağlantıyı kontrol et
  Future<void> initialize({required Future<void> Function(bool isConnected) onConnectivityChanged}) async {
    _onConnectivityChanged = onConnectivityChanged;
    await _checkInitialConnection();
    _startListening();
  }

  void _startListening() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
  }

  Future<void> _checkInitialConnection() async {
    final connectivityResults = await Connectivity().checkConnectivity();
    await _updateConnectionStatus(connectivityResults);
  }

  Future<void> _updateConnectionStatus(List<ConnectivityResult> result) async {
    bool previousConnection = _isConnected;
    bool hasConnection =
        result.contains(ConnectivityResult.mobile) ||
        result.contains(ConnectivityResult.wifi);
    
    if (hasConnection) {
      try {
        // İnternet bağlantısını gerçekten test et
        final internetResult = await InternetAddress.lookup('google.com')
            .timeout(Duration(seconds: 5));
        _isConnected = internetResult.isNotEmpty && internetResult[0].rawAddress.isNotEmpty;
      } catch (e) {
        _isConnected = false;
      }
      _isCheckConnection = false;
    } else {
      _isConnected = false;
      _isCheckConnection = true;
    }
    
    // Bağlantı durumu değiştiyse callback'i çağır
    if (previousConnection != _isConnected && _onConnectivityChanged != null) {
      debugPrint("Bağlantı durumu değişti: $_isConnected");
      await _onConnectivityChanged!(_isConnected);
    }
  }

  // Manuel bağlantı kontrolü
  Future<bool> checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  void stopCheckConnection() {
    _connectivitySubscription.cancel();
  }

  void dispose() {
    stopCheckConnection();
  }
}
