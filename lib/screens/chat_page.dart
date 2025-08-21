import 'package:flutter/material.dart';
import 'package:doomsms/models/contact.dart';
import 'package:doomsms/models/message.dart';
import 'package:doomsms/services/p2p_service.dart';
import 'package:doomsms/services/storage_service.dart';
import 'package:doomsms/services/encryption_service.dart';
import 'package:doomsms/widgets/message_bubble.dart';

class ChatPage extends StatefulWidget {
  final Contact contact;
  final String currentUserId;
  final P2PService p2pService;

  const ChatPage({
    super.key,
    required this.contact,
    required this.currentUserId,
    required this.p2pService,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Message> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final allMessages = await StorageService.loadMessages();
    final chatMessages = allMessages.where((message) {
      return (message.senderId == widget.currentUserId && message.recipientId == widget.contact.id) ||
             (message.senderId == widget.contact.id && message.recipientId == widget.currentUserId);
    }).toList();

    chatMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    setState(() {
      _messages = chatMessages;
      _isLoading = false;
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    try {
      // Chiffrer le message
      final encryptedContent = EncryptionService.encryptMessage(text, widget.contact.publicKey);
      
      final message = Message(
        id: P2PService.generateId(),
        senderId: widget.currentUserId,
        recipientId: widget.contact.id,
        content: text,
        encryptedContent: encryptedContent,
        timestamp: DateTime.now(),
        status: MessageStatus.sending,
        isEncrypted: true,
      );

      // Ajouter à la liste locale immédiatement
      setState(() {
        _messages.add(message);
      });
      _scrollToBottom();

      // Sauvegarder localement
      await StorageService.addMessage(message);

      // Créer le message chiffré pour l'envoi
      final messageToSend = message.copyWith(
        content: '', // Ne pas envoyer le texte en clair
      );

      // Envoyer via P2P (IP simulée pour la démo)
      final sent = await widget.p2pService.sendMessage('127.0.0.1', messageToSend);
      
      final newStatus = sent ? MessageStatus.sent : MessageStatus.failed;
      await StorageService.updateMessageStatus(message.id, newStatus);
      
      // Mettre à jour l'affichage
      final updatedMessage = message.copyWith(status: newStatus);
      final index = _messages.indexWhere((m) => m.id == message.id);
      if (index != -1) {
        setState(() {
          _messages[index] = updatedMessage;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur d\'envoi: $e')),
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                widget.contact.name.isNotEmpty ? widget.contact.name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.contact.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.lock,
                        size: 12,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Chiffré de bout en bout',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showContactInfo(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.lock,
                              size: 48,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Conversation sécurisée',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tous les messages sont chiffrés de bout en bout',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          return MessageBubble(
                            message: _messages[index],
                            isMe: _messages[index].senderId == widget.currentUserId,
                          );
                        },
                      ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Message sécurisé...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      prefixIcon: Icon(
                        Icons.lock,
                        size: 20,
                        color: Colors.green,
                      ),
                    ),
                    maxLines: null,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                FloatingActionButton.small(
                  onPressed: _sendMessage,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Icon(
                    Icons.send,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showContactInfo() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    widget.contact.name.isNotEmpty ? widget.contact.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.contact.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${widget.contact.id}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildInfoRow(
              icon: Icons.fingerprint,
              title: 'Empreinte de clé',
              subtitle: widget.contact.publicKey.isNotEmpty 
                  ? widget.contact.publicKey.substring(0, 32) + '...'
                  : 'Non disponible',
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.access_time,
              title: 'Dernière activité',
              subtitle: _formatLastSeen(widget.contact.lastSeen),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: widget.contact.isVerified ? Icons.verified : Icons.warning,
              title: 'Statut de vérification',
              subtitle: widget.contact.isVerified ? 'Contact vérifié' : 'Non vérifié',
              subtitleColor: widget.contact.isVerified ? Colors.green : Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? subtitleColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.labelMedium,
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: subtitleColor ?? Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inHours < 1) {
      return 'Il y a ${difference.inMinutes} minutes';
    } else if (difference.inDays < 1) {
      return 'Il y a ${difference.inHours} heures';
    } else {
      return 'Il y a ${difference.inDays} jours';
    }
  }
}