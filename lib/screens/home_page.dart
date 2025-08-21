import 'package:flutter/material.dart';
import 'package:doomsms/screens/chat_page.dart';
import 'package:doomsms/screens/contacts_page.dart';
import 'package:doomsms/screens/settings_page.dart';
import 'package:doomsms/services/storage_service.dart';
import 'package:doomsms/services/encryption_service.dart';
import 'package:doomsms/services/p2p_service.dart';
import 'package:doomsms/models/message.dart';
import 'package:doomsms/models/contact.dart';
import 'package:doomsms/widgets/message_bubble.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final P2PService _p2pService = P2PService();
  List<Message> _messages = [];
  List<Contact> _contacts = [];
  String _userName = '';
  String _userId = '';
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await StorageService.init();
    
    // Charger ou créer l'identité utilisateur
    String? userId = await StorageService.loadUserId();
    String? userName = await StorageService.loadUserName();
    
    if (userId == null || userName == null) {
      await _showSetupDialog();
      return;
    }
    
    _userId = userId;
    _userName = userName;
    
    // Charger ou générer les clés
    var keyPair = await StorageService.loadKeyPair();
    if (keyPair == null) {
      keyPair = EncryptionService.generateKeyPair();
      await StorageService.saveKeyPair(keyPair);
    }
    
    // Initialiser le service P2P
    _p2pService.initialize(_userId, _userName, keyPair.publicKey);
    await _p2pService.start();
    
    // Écouter les nouveaux contacts et messages
    _p2pService.contactDiscovered.listen(_onContactDiscovered);
    _p2pService.messageReceived.listen(_onMessageReceived);
    
    // Charger les données existantes
    await _loadData();
    
    setState(() => _isInitialized = true);
  }

  Future<void> _showSetupDialog() async {
    final TextEditingController nameController = TextEditingController();
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Configuration DoomSMS'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Bienvenue dans DoomSMS! Veuillez entrer votre nom:'),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Votre nom',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                _userName = nameController.text.trim();
                _userId = P2PService.generateId();
                
                await StorageService.saveUserName(_userName);
                await StorageService.saveUserId(_userId);
                
                Navigator.of(context).pop();
                await _initializeApp();
              }
            },
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadData() async {
    final messages = await StorageService.loadMessages();
    final contacts = await StorageService.loadContacts();
    
    setState(() {
      _messages = messages;
      _contacts = contacts;
    });
  }

  void _onContactDiscovered(Contact contact) async {
    if (contact.id != _userId) {
      await StorageService.addContact(contact);
      await _loadData();
    }
  }

  void _onMessageReceived(Message message) async {
    await StorageService.addMessage(message);
    await _loadData();
  }

  Map<String, List<Message>> get _conversationMap {
    final Map<String, List<Message>> conversations = {};
    for (final message in _messages) {
      final otherUserId = message.senderId == _userId ? message.recipientId : message.senderId;
      conversations[otherUserId] ??= [];
      conversations[otherUserId]!.add(message);
    }
    return conversations;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _p2pService.stop();
    _p2pService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Initialisation de DoomSMS...',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('🔒 DoomSMS'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.chat_bubble), text: 'Chats'),
            Tab(icon: Icon(Icons.contacts), text: 'Contacts'),
            Tab(icon: Icon(Icons.settings), text: 'Paramètres'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChatsTab(),
          ContactsPage(contacts: _contacts, onContactSelected: _openChat),
          SettingsPage(userName: _userName, userId: _userId),
        ],
      ),
    );
  }

  Widget _buildChatsTab() {
    final conversations = _conversationMap;
    
    if (conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune conversation',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Découvrez des contacts et commencez à discuter!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final contactId = conversations.keys.elementAt(index);
        final messages = conversations[contactId]!;
        final lastMessage = messages.last;
        final contact = _contacts.firstWhere(
          (c) => c.id == contactId,
          orElse: () => Contact(
            id: contactId,
            name: 'Contact inconnu',
            publicKey: '',
            lastSeen: DateTime.now(),
          ),
        );

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
              ),
            ),
            title: Row(
              children: [
                Expanded(child: Text(contact.name)),
                if (contact.isOnline)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            subtitle: Row(
              children: [
                Icon(
                  lastMessage.isEncrypted ? Icons.lock : Icons.lock_open,
                  size: 16,
                  color: lastMessage.isEncrypted ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    lastMessage.content.isNotEmpty ? lastMessage.content : 'Message chiffré',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${lastMessage.timestamp.hour.toString().padLeft(2, '0')}:${lastMessage.timestamp.minute.toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 4),
                _buildMessageStatusIcon(lastMessage.status),
              ],
            ),
            onTap: () => _openChat(contact),
          ),
        );
      },
    );
  }

  Widget _buildMessageStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return Icon(Icons.access_time, size: 16, color: Colors.grey);
      case MessageStatus.sent:
        return Icon(Icons.check, size: 16, color: Colors.grey);
      case MessageStatus.delivered:
        return Icon(Icons.done_all, size: 16, color: Colors.grey);
      case MessageStatus.read:
        return Icon(Icons.done_all, size: 16, color: Colors.blue);
      case MessageStatus.failed:
        return Icon(Icons.error, size: 16, color: Colors.red);
    }
  }

  void _openChat(Contact contact) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          contact: contact,
          currentUserId: _userId,
          p2pService: _p2pService,
        ),
      ),
    ).then((_) => _loadData());
  }
}