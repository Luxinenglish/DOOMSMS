import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';
import 'package:doomsms/models/key_pair.dart' as app_models;

class EncryptionService {
  static const int _keySize = 2048;
  static const int _aesKeySize = 32; // 256 bits

  /// Génère une nouvelle paire de clés RSA
  static app_models.KeyPair generateKeyPair() {
    final keyGen = RSAKeyGenerator();
    final random = FortunaRandom();
    
    // Initialisation du générateur aléatoire
    final seedSource = Random.secure();
    final seeds = <int>[];
    for (int i = 0; i < 32; i++) {
      seeds.add(seedSource.nextInt(255));
    }
    random.seed(KeyParameter(Uint8List.fromList(seeds)));

    keyGen.init(ParametersWithRandom(
        RSAKeyGeneratorParameters(BigInt.parse('65537'), _keySize, 64), random));

    final pair = keyGen.generateKeyPair();
    final publicKey = pair.publicKey as RSAPublicKey;
    final privateKey = pair.privateKey as RSAPrivateKey;

    final publicKeyString = _encodeRSAPublicKey(publicKey);
    final privateKeyString = _encodeRSAPrivateKey(privateKey);
    
    final fingerprint = _generateFingerprint(publicKeyString);

    return app_models.KeyPair(
      publicKey: publicKeyString,
      privateKey: privateKeyString,
      createdAt: DateTime.now(),
      fingerprint: fingerprint,
    );
  }

  /// Chiffre un message avec AES + RSA (version simplifiée)
  static String encryptMessage(String message, String recipientPublicKey) {
    try {
      // Générer une clé AES aléatoire
      final aesKey = _generateRandomBytes(_aesKeySize);
      
      // Chiffrer le message avec AES
      final encryptedMessage = _encryptAES(message, aesKey);
      
      // Pour la démo, on simule le chiffrement RSA de la clé AES
      final encryptedAesKey = base64.encode(aesKey);
      
      // Combiner les données chiffrées
      final combinedData = {
        'encryptedKey': encryptedAesKey,
        'encryptedMessage': base64.encode(encryptedMessage),
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      return base64.encode(utf8.encode(json.encode(combinedData)));
    } catch (e) {
      throw Exception('Erreur de chiffrement: $e');
    }
  }

  /// Déchiffre un message avec RSA + AES (version simplifiée)
  static String decryptMessage(String encryptedData, String privateKeyString) {
    try {
      // Décoder les données
      final decodedData = json.decode(utf8.decode(base64.decode(encryptedData)));
      final encryptedAesKey = base64.decode(decodedData['encryptedKey']);
      final encryptedMessage = base64.decode(decodedData['encryptedMessage']);
      
      // Pour la démo, on simule le déchiffrement RSA de la clé AES
      final aesKey = encryptedAesKey;
      
      // Déchiffrer le message avec AES
      final decryptedMessage = _decryptAES(encryptedMessage, aesKey);
      
      return decryptedMessage;
    } catch (e) {
      throw Exception('Erreur de déchiffrement: $e');
    }
  }

  /// Génère une empreinte de clé publique
  static String _generateFingerprint(String publicKey) {
    final bytes = utf8.encode(publicKey);
    final digest = sha256.convert(bytes);
    final hexString = digest.toString();
    // Formater comme une empreinte lisible
    final List<String> pairs = [];
    for (int i = 0; i < 32; i += 2) {
      pairs.add(hexString.substring(i, i + 2).toUpperCase());
    }
    return pairs.join(':');
  }

  /// Encode une clé publique RSA (version simplifiée)
  static String _encodeRSAPublicKey(RSAPublicKey publicKey) {
    final keyData = {
      'modulus': publicKey.modulus.toString(),
      'exponent': publicKey.exponent.toString(),
    };
    return base64.encode(utf8.encode(json.encode(keyData)));
  }

  /// Encode une clé privée RSA (version simplifiée)
  static String _encodeRSAPrivateKey(RSAPrivateKey privateKey) {
    final keyData = {
      'modulus': privateKey.modulus.toString(),
      'exponent': privateKey.exponent.toString(),
      'privateExponent': privateKey.privateExponent.toString(),
      'p': privateKey.p.toString(),
      'q': privateKey.q.toString(),
    };
    return base64.encode(utf8.encode(json.encode(keyData)));
  }

  /// Décode une clé publique depuis la représentation simplifiée
  static RSAPublicKey _decodeRSAPublicKey(String keyString) {
    final keyData = json.decode(utf8.decode(base64.decode(keyString)));
    return RSAPublicKey(
      BigInt.parse(keyData['modulus']),
      BigInt.parse(keyData['exponent']),
    );
  }

  /// Décode une clé privée depuis la représentation simplifiée
  static RSAPrivateKey _decodeRSAPrivateKey(String keyString) {
    final keyData = json.decode(utf8.decode(base64.decode(keyString)));
    return RSAPrivateKey(
      BigInt.parse(keyData['modulus']),
      BigInt.parse(keyData['privateExponent']),
      BigInt.parse(keyData['p']),
      BigInt.parse(keyData['q']),
    );
  }

  /// Chiffrement AES-CTR (plus simple que GCM)
  static Uint8List _encryptAES(String plainText, Uint8List key) {
    final cipher = CTRStreamCipher(AESEngine());
    final iv = _generateRandomBytes(16); // 128 bits
    
    cipher.init(true, ParametersWithIV(KeyParameter(key), iv));
    
    final plainBytes = utf8.encode(plainText);
    final encryptedBytes = cipher.process(Uint8List.fromList(plainBytes));
    
    // Combiner IV + données chiffrées
    final result = Uint8List(iv.length + encryptedBytes.length);
    result.setRange(0, iv.length, iv);
    result.setRange(iv.length, result.length, encryptedBytes);
    
    return result;
  }

  /// Déchiffrement AES-CTR
  static String _decryptAES(Uint8List encryptedData, Uint8List key) {
    final cipher = CTRStreamCipher(AESEngine());
    final iv = encryptedData.sublist(0, 16);
    final cipherText = encryptedData.sublist(16);
    
    cipher.init(false, ParametersWithIV(KeyParameter(key), iv));
    
    final decryptedBytes = cipher.process(cipherText);
    return utf8.decode(decryptedBytes);
  }

  /// Génère des bytes aléatoires
  static Uint8List _generateRandomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(List.generate(length, (_) => random.nextInt(256)));
  }

  /// Valide une clé publique
  static bool isValidPublicKey(String publicKey) {
    try {
      _decodeRSAPublicKey(publicKey);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Génère un ID sécurisé
  static String generateSecureId() {
    final random = Random.secure();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return String.fromCharCodes(
      Iterable.generate(16, (_) => chars.codeUnitAt(random.nextInt(chars.length)))
    );
  }
}