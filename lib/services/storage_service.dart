import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:doomsms/models/message.dart';
import 'package:doomsms/models/contact.dart';
import 'package:doomsms/models/key_pair.dart';

class StorageService {
  static const String _messagesKey = 'messages';
  static const String _contactsKey = 'contacts';
  static const String _keyPairKey = 'keyPair';
  static const String _userNameKey = 'userName';
  static const String _userIdKey = 'userId';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Sauvegarde les messages
  static Future<void> saveMessages(List<Message> messages) async {
    await init();
    final messagesJson = messages.map((m) => m.toJson()).toList();
    await _prefs!.setString(_messagesKey, json.encode(messagesJson));
  }

  /// Charge les messages
  static Future<List<Message>> loadMessages() async {
    await init();
    final messagesString = _prefs!.getString(_messagesKey);
    if (messagesString == null) return [];

    final List<dynamic> messagesJson = json.decode(messagesString);
    return messagesJson.map((json) => Message.fromJson(json)).toList();
  }

  /// Sauvegarde les contacts
  static Future<void> saveContacts(List<Contact> contacts) async {
    await init();
    final contactsJson = contacts.map((c) => c.toJson()).toList();
    await _prefs!.setString(_contactsKey, json.encode(contactsJson));
  }

  /// Charge les contacts
  static Future<List<Contact>> loadContacts() async {
    await init();
    final contactsString = _prefs!.getString(_contactsKey);
    if (contactsString == null) return [];

    final List<dynamic> contactsJson = json.decode(contactsString);
    return contactsJson.map((json) => Contact.fromJson(json)).toList();
  }

  /// Sauvegarde la paire de clés
  static Future<void> saveKeyPair(KeyPair keyPair) async {
    await init();
    await _prefs!.setString(_keyPairKey, json.encode(keyPair.toJson()));
  }

  /// Charge la paire de clés
  static Future<KeyPair?> loadKeyPair() async {
    await init();
    final keyPairString = _prefs!.getString(_keyPairKey);
    if (keyPairString == null) return null;

    final keyPairJson = json.decode(keyPairString);
    return KeyPair.fromJson(keyPairJson);
  }

  /// Sauvegarde le nom d'utilisateur
  static Future<void> saveUserName(String name) async {
    await init();
    await _prefs!.setString(_userNameKey, name);
  }

  /// Charge le nom d'utilisateur
  static Future<String?> loadUserName() async {
    await init();
    return _prefs!.getString(_userNameKey);
  }

  /// Sauvegarde l'ID utilisateur
  static Future<void> saveUserId(String id) async {
    await init();
    await _prefs!.setString(_userIdKey, id);
  }

  /// Charge l'ID utilisateur
  static Future<String?> loadUserId() async {
    await init();
    return _prefs!.getString(_userIdKey);
  }

  /// Ajoute un message
  static Future<void> addMessage(Message message) async {
    final messages = await loadMessages();
    messages.add(message);
    await saveMessages(messages);
  }

  /// Met à jour le statut d'un message
  static Future<void> updateMessageStatus(String messageId, MessageStatus status) async {
    final messages = await loadMessages();
    final index = messages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      messages[index] = messages[index].copyWith(status: status);
      await saveMessages(messages);
    }
  }

  /// Ajoute un contact
  static Future<void> addContact(Contact contact) async {
    final contacts = await loadContacts();
    final existingIndex = contacts.indexWhere((c) => c.id == contact.id);
    if (existingIndex != -1) {
      contacts[existingIndex] = contact;
    } else {
      contacts.add(contact);
    }
    await saveContacts(contacts);
  }

  /// Supprime un contact
  static Future<void> removeContact(String contactId) async {
    final contacts = await loadContacts();
    contacts.removeWhere((c) => c.id == contactId);
    await saveContacts(contacts);
  }

  /// Efface toutes les données
  static Future<void> clearAllData() async {
    await init();
    await _prefs!.clear();
  }
}