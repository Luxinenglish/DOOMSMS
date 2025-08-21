import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// Générateur d'identifiants uniques pour DoomSMS
/// 
/// Génère des IDs sécurisés avec de meilleures garanties d'unicité
/// pour une utilisation dans un système P2P distribué.
class IdGenerator {
  static final Random _random = Random.secure();
  
  // Caractères utilisés pour l'ID (base62: lettres minuscules, majuscules et chiffres)
  static const String _chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  static const int _charsLength = 62;
  
  /// Génère un ID unique avec horodatage pour garantir l'unicité
  /// 
  /// Format: [timestamp_base62][random_part]
  /// - Longueur totale: 20 caractères minimum
  /// - Les 8 premiers caractères encodent le timestamp en base62
  /// - Les 12 caractères suivants sont aléatoires
  /// 
  /// Cela garantit l'unicité même si deux instances génèrent
  /// un ID à la même milliseconde.
  static String generateUniqueId() {
    // Obtenir le timestamp actuel en millisecondes
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    // Convertir le timestamp en base62 (8 caractères)
    final timestampPart = _toBase62(timestamp, 8);
    
    // Générer la partie aléatoire (12 caractères)
    final randomPart = _generateRandomString(12);
    
    return timestampPart + randomPart;
  }
  
  /// Génère un ID compatible avec l'ancien format (16 caractères, a-z0-9)
  /// 
  /// Utilisé pour maintenir la compatibilité avec l'ancien système.
  /// Note: Moins sécurisé que generateUniqueId() mais compatible.
  static String generateLegacyId() {
    const legacyChars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return String.fromCharCodes(
      Iterable.generate(16, (_) => legacyChars.codeUnitAt(_random.nextInt(36)))
    );
  }
  
  /// Génère un ID court pour l'affichage (8 caractères)
  /// 
  /// Utilisé pour les cas où un ID plus court est suffisant
  /// ou pour l'affichage dans l'interface utilisateur.
  static String generateShortId() {
    return _generateRandomString(8);
  }
  
  /// Génère un ID sécurisé basé sur un hash
  /// 
  /// Utilise SHA-256 d'une combinaison de timestamp, aléatoire et données
  /// pour créer un ID déterministe mais unique.
  static String generateHashBasedId([String? additionalData]) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomBytes = List.generate(16, (_) => _random.nextInt(256));
    
    final input = '$timestamp:${randomBytes.join(',')}:${additionalData ?? ''}';
    final digest = sha256.convert(utf8.encode(input));
    
    // Convertir les premiers 15 bytes du hash en base62 (20 caractères)
    final hashBytes = digest.bytes.take(15).toList();
    return _bytesToBase62(hashBytes, 20);
  }
  
  /// Valide le format d'un ID
  /// 
  /// Vérifie si l'ID respecte l'un des formats supportés:
  /// - Format unique: 20+ caractères base62
  /// - Format legacy: 16 caractères a-z0-9
  /// - Format court: 8 caractères base62
  static bool isValidId(String id) {
    if (id.isEmpty) return false;
    
    // Format unique (20+ caractères base62)
    if (id.length >= 20 && _isBase62(id)) {
      return true;
    }
    
    // Format legacy (16 caractères a-z0-9)
    if (id.length == 16 && _isLegacyFormat(id)) {
      return true;
    }
    
    // Format court (8 caractères base62)
    if (id.length == 8 && _isBase62(id)) {
      return true;
    }
    
    return false;
  }
  
  /// Extrait le timestamp d'un ID unique
  /// 
  /// Retourne le timestamp encodé dans les 8 premiers caractères
  /// d'un ID généré par generateUniqueId(), ou null si ce n'est pas possible.
  static DateTime? extractTimestamp(String id) {
    if (id.length < 8) return null;
    
    try {
      final timestampPart = id.substring(0, 8);
      final timestamp = _fromBase62(timestampPart);
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } catch (e) {
      return null;
    }
  }
  
  // Méthodes utilitaires privées
  
  /// Génère une chaîne aléatoire de longueur donnée en base62
  static String _generateRandomString(int length) {
    return String.fromCharCodes(
      Iterable.generate(length, (_) => _chars.codeUnitAt(_random.nextInt(_charsLength)))
    );
  }
  
  /// Convertit un nombre en base62 avec padding
  static String _toBase62(int number, int minLength) {
    if (number == 0) return '0'.padLeft(minLength, 'a');
    
    String result = '';
    int num = number;
    
    while (num > 0) {
      result = _chars[num % _charsLength] + result;
      num ~/= _charsLength;
    }
    
    return result.padLeft(minLength, 'a');
  }
  
  /// Convertit une chaîne base62 en nombre
  static int _fromBase62(String str) {
    int result = 0;
    for (int i = 0; i < str.length; i++) {
      final charIndex = _chars.indexOf(str[i]);
      if (charIndex == -1) throw FormatException('Invalid base62 character: ${str[i]}');
      result = result * _charsLength + charIndex;
    }
    return result;
  }
  
  /// Convertit un tableau de bytes en base62
  static String _bytesToBase62(List<int> bytes, int minLength) {
    // Convertir les bytes en un grand nombre
    BigInt number = BigInt.zero;
    for (final byte in bytes) {
      number = number * BigInt.from(256) + BigInt.from(byte);
    }
    
    if (number == BigInt.zero) return 'a'.padLeft(minLength, 'a');
    
    String result = '';
    while (number > BigInt.zero) {
      final remainder = number % BigInt.from(_charsLength);
      result = _chars[remainder.toInt()] + result;
      number = number ~/ BigInt.from(_charsLength);
    }
    
    return result.padLeft(minLength, 'a');
  }
  
  /// Vérifie si une chaîne est en format base62 valide
  static bool _isBase62(String str) {
    return str.split('').every((char) => _chars.contains(char));
  }
  
  /// Vérifie si une chaîne est en format legacy (a-z0-9)
  static bool _isLegacyFormat(String str) {
    const legacyChars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return str.split('').every((char) => legacyChars.contains(char));
  }
}