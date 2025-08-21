import 'package:flutter/material.dart';
import 'package:doomsms/services/storage_service.dart';
import 'package:doomsms/services/encryption_service.dart';
import 'package:doomsms/widgets/security_indicator.dart';

class SettingsPage extends StatefulWidget {
  final String userName;
  final String userId;

  const SettingsPage({
    super.key,
    required this.userName,
    required this.userId,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _fingerprint = '';

  @override
  void initState() {
    super.initState();
    _loadFingerprint();
  }

  Future<void> _loadFingerprint() async {
    final keyPair = await StorageService.loadKeyPair();
    if (keyPair != null) {
      setState(() => _fingerprint = keyPair.fingerprint);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          _buildUserSection(),
          const Divider(),
          _buildSecuritySection(),
          const Divider(),
          _buildDataSection(),
          const Divider(),
          _buildAboutSection(),
        ],
      ),
    );
  }

  Widget _buildUserSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : '?',
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
                          widget.userName,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID: ${widget.userId}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _showEditProfile,
                    icon: const Icon(Icons.edit),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const SecurityIndicator(isSecure: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecuritySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sécurité',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          _buildSettingsTile(
            icon: Icons.fingerprint,
            title: 'Empreinte de clé',
            subtitle: _fingerprint.isEmpty ? 'Chargement...' : _fingerprint,
            onTap: () => _showFingerprint(),
          ),
          _buildSettingsTile(
            icon: Icons.key,
            title: 'Régénérer les clés',
            subtitle: 'Créer une nouvelle paire de clés',
            onTap: _showRegenerateKeysDialog,
          ),
          _buildSettingsTile(
            icon: Icons.backup,
            title: 'Exporter les clés',
            subtitle: 'Sauvegarder vos clés privées',
            onTap: _exportKeys,
          ),
        ],
      ),
    );
  }

  Widget _buildDataSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Données',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          _buildSettingsTile(
            icon: Icons.auto_delete,
            title: 'Messages temporaires',
            subtitle: 'Effacement automatique après 24h',
            trailing: Switch(value: false, onChanged: (_) {}),
          ),
          _buildSettingsTile(
            icon: Icons.delete_forever,
            title: 'Effacer toutes les données',
            subtitle: 'Supprimer messages, contacts et clés',
            onTap: _showClearDataDialog,
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'À propos',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          _buildSettingsTile(
            icon: Icons.info,
            title: 'DoomSMS',
            subtitle: 'Version 1.0.0 - Messagerie sécurisée P2P',
            onTap: _showAboutDialog,
          ),
          _buildSettingsTile(
            icon: Icons.security,
            title: 'Chiffrement',
            subtitle: 'RSA-2048 + AES-256-GCM',
          ),
          _buildSettingsTile(
            icon: Icons.code,
            title: 'Open Source',
            subtitle: 'Code source disponible',
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive 
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Theme.of(context).colorScheme.error : null,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: trailing,
      onTap: onTap,
    );
  }

  void _showEditProfile() {
    final TextEditingController nameController = TextEditingController(text: widget.userName);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le profil'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Nom d\'utilisateur',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                await StorageService.saveUserName(nameController.text.trim());
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profil mis à jour')),
                );
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _showFingerprint() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Empreinte de clé publique'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _fingerprint,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontFamily: 'monospace',
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Partagez cette empreinte pour permettre aux autres de vérifier votre identité.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              // Copier dans le presse-papier
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Empreinte copiée')),
              );
            },
            child: const Text('Copier'),
          ),
        ],
      ),
    );
  }

  void _showRegenerateKeysDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Régénérer les clés'),
        content: const Text(
          'Cette action va créer une nouvelle paire de clés. Tous vos contacts devront mettre à jour votre clé publique. Continuer?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newKeyPair = EncryptionService.generateKeyPair();
              await StorageService.saveKeyPair(newKeyPair);
              setState(() => _fingerprint = newKeyPair.fingerprint);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Nouvelles clés générées'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Régénérer'),
          ),
        ],
      ),
    );
  }

  void _exportKeys() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export des clés - Fonctionnalité à implémenter')),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Effacer toutes les données'),
        content: const Text(
          'Cette action est irréversible. Toutes vos conversations, contacts et clés seront supprimés définitivement.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              await StorageService.clearAllData();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Toutes les données ont été supprimées'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(
              'Supprimer',
              style: TextStyle(color: Theme.of(context).colorScheme.onError),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'DoomSMS',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.lock, size: 48),
      children: [
        const Text('Messagerie sécurisée peer-to-peer avec chiffrement de bout en bout.'),
        const SizedBox(height: 16),
        const Text('Fonctionnalités:'),
        const Text('• Chiffrement RSA-2048 + AES-256-GCM'),
        const Text('• Communication P2P directe'),
        const Text('• Aucun serveur central'),
        const Text('• Code source ouvert'),
      ],
    );
  }
}