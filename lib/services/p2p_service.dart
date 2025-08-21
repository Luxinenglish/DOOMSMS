import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:doomsms/models/message.dart';
import 'package:doomsms/models/contact.dart';

class P2PService {
  static const int _discoveryPort = 7001;
  static const int _messagePort = 7002;
  
  ServerSocket? _discoveryServer;
  ServerSocket? _messageServer;
  Timer? _discoveryTimer;
  
  final StreamController<Contact> _contactDiscoveredController = StreamController.broadcast();
  final StreamController<Message> _messageReceivedController = StreamController.broadcast();
  
  Stream<Contact> get contactDiscovered => _contactDiscoveredController.stream;
  Stream<Message> get messageReceived => _messageReceivedController.stream;
  
  String? _localIp;
  String _userId = '';
  String _userName = '';
  String _publicKey = '';

  void initialize(String userId, String userName, String publicKey) {
    _userId = userId;
    _userName = userName;
    _publicKey = publicKey;
  }

  /// Démarre le service P2P
  Future<void> start() async {
    await _getLocalIP();
    await _startDiscoveryServer();
    await _startMessageServer();
    _startPeriodicDiscovery();
  }

  /// Arrête le service P2P
  Future<void> stop() async {
    _discoveryTimer?.cancel();
    await _discoveryServer?.close();
    await _messageServer?.close();
    _discoveryServer = null;
    _messageServer = null;
  }

  /// Obtient l'IP locale
  Future<void> _getLocalIP() async {
    try {
      final info = NetworkInfo();
      _localIp = await info.getWifiIP();
      _localIp ??= '127.0.0.1';
    } catch (e) {
      _localIp = '127.0.0.1';
    }
  }

  /// Démarre le serveur de découverte
  Future<void> _startDiscoveryServer() async {
    try {
      _discoveryServer = await ServerSocket.bind(InternetAddress.anyIPv4, _discoveryPort);
      _discoveryServer!.listen((socket) => _handleDiscoveryConnection(socket));
    } catch (e) {
      print('Erreur serveur de découverte: \$e');
    }
  }

  /// Démarre le serveur de messages
  Future<void> _startMessageServer() async {
    try {
      _messageServer = await ServerSocket.bind(InternetAddress.anyIPv4, _messagePort);
      _messageServer!.listen((socket) => _handleMessageConnection(socket));
    } catch (e) {
      print('Erreur serveur de messages: \$e');
    }
  }

  /// Gère les connexions de découverte
  void _handleDiscoveryConnection(Socket socket) {
    socket.listen(
      (data) {
        try {
          final message = utf8.decode(data);
          final discoveryData = json.decode(message);
          
          if (discoveryData['type'] == 'discovery_request') {
            // Répondre avec nos informations
            final response = {
              'type': 'discovery_response',
              'userId': _userId,
              'userName': _userName,
              'publicKey': _publicKey,
              'ip': _localIp,
            };
            socket.write(json.encode(response));
          } else if (discoveryData['type'] == 'discovery_response') {
            // Traiter la découverte d'un peer
            final contact = Contact(
              id: discoveryData['userId'],
              name: discoveryData['userName'],
              publicKey: discoveryData['publicKey'],
              lastSeen: DateTime.now(),
              isOnline: true,
            );
            _contactDiscoveredController.add(contact);
          }
        } catch (e) {
          print('Erreur traitement découverte: \$e');
        }
      },
      onDone: () => socket.destroy(),
      onError: (error) => socket.destroy(),
    );
  }

  /// Gère les connexions de messages
  void _handleMessageConnection(Socket socket) {
    socket.listen(
      (data) {
        try {
          final messageJson = utf8.decode(data);
          final message = Message.fromJson(json.decode(messageJson));
          _messageReceivedController.add(message);
          
          // Confirmer la réception
          final ack = {'type': 'ack', 'messageId': message.id};
          socket.write(json.encode(ack));
        } catch (e) {
          print('Erreur traitement message: \$e');
        }
      },
      onDone: () => socket.destroy(),
      onError: (error) => socket.destroy(),
    );
  }

  /// Lance la découverte périodique
  void _startPeriodicDiscovery() {
    _discoveryTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _broadcastDiscovery();
    });
    
    // Première découverte immédiate
    _broadcastDiscovery();
  }

  /// Diffuse un message de découverte
  void _broadcastDiscovery() async {
    if (_localIp == null) return;
    
    final baseIp = _localIp!.substring(0, _localIp!.lastIndexOf('.'));
    final discoveryMessage = {
      'type': 'discovery_request',
      'userId': _userId,
      'userName': _userName,
      'publicKey': _publicKey,
      'ip': _localIp,
    };
    
    // Scanner le réseau local (ex: 192.168.1.1-254)
    for (int i = 1; i <= 254; i++) {
      final targetIp = '\$baseIp.\$i';
      if (targetIp == _localIp) continue;
      
      _sendDiscoveryToIP(targetIp, discoveryMessage);
    }
  }

  /// Envoie une découverte à une IP spécifique
  void _sendDiscoveryToIP(String ip, Map<String, dynamic> message) async {
    try {
      final socket = await Socket.connect(ip, _discoveryPort, timeout: const Duration(seconds: 2));
      socket.write(json.encode(message));
      await socket.flush();
      socket.destroy();
    } catch (e) {
      // IP non accessible, ignorer
    }
  }

  /// Envoie un message à un contact
  Future<bool> sendMessage(String contactIp, Message message) async {
    try {
      final socket = await Socket.connect(contactIp, _messagePort, timeout: const Duration(seconds: 5));
      socket.write(json.encode(message.toJson()));
      await socket.flush();
      
      // Attendre l'accusé de réception
      final completer = Completer<bool>();
      socket.listen(
        (data) {
          try {
            final response = json.decode(utf8.decode(data));
            if (response['type'] == 'ack' && response['messageId'] == message.id) {
              completer.complete(true);
            }
          } catch (e) {
            completer.complete(false);
          }
        },
        onDone: () {
          if (!completer.isCompleted) completer.complete(false);
          socket.destroy();
        },
        onError: (error) {
          if (!completer.isCompleted) completer.complete(false);
          socket.destroy();
        },
      );
      
      return await completer.future.timeout(const Duration(seconds: 10), onTimeout: () => false);
    } catch (e) {
      print('Erreur envoi message: \$e');
      return false;
    }
  }

  /// Génère un ID unique
  static String generateId() {
    final random = Random.secure();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return String.fromCharCodes(Iterable.generate(16, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }

  void dispose() {
    _contactDiscoveredController.close();
    _messageReceivedController.close();
  }
}