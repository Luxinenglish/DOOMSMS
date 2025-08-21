import 'package:flutter/material.dart';
import 'package:doomsms/models/contact.dart';
import 'package:doomsms/widgets/contact_card.dart';

class ContactsPage extends StatefulWidget {
  final List<Contact> contacts;
  final Function(Contact) onContactSelected;

  const ContactsPage({
    super.key,
    required this.contacts,
    required this.onContactSelected,
  });

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Contact> _filteredContacts = [];

  @override
  void initState() {
    super.initState();
    _filteredContacts = widget.contacts;
    _searchController.addListener(_filterContacts);
  }

  void _filterContacts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredContacts = widget.contacts.where((contact) {
        return contact.name.toLowerCase().contains(query) ||
               contact.id.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  void didUpdateWidget(ContactsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.contacts != widget.contacts) {
      _filterContacts();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un contact...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
          Expanded(
            child: _filteredContacts.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: _filteredContacts.length,
                    itemBuilder: (context, index) {
                      final contact = _filteredContacts[index];
                      return ContactCard(
                        contact: contact,
                        onTap: () => widget.onContactSelected(contact),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddContactDialog,
        backgroundColor: Theme.of(context).colorScheme.primary,
        icon: Icon(
          Icons.person_add,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
        label: Text(
          'Ajouter',
          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    if (widget.contacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun contact',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Les contacts seront découverts automatiquement\\nsur le réseau local',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddContactDialog,
              icon: const Icon(Icons.person_add),
              label: const Text('Ajouter manuellement'),
            ),
          ],
        ),
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun résultat',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Essayez un autre terme de recherche',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }
  }

  void _showAddContactDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController keyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nom du contact',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: keyController,
              decoration: const InputDecoration(
                labelText: 'Clé publique',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.key),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            Text(
              'La clé publique permet le chiffrement de bout en bout',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty &&
                  keyController.text.trim().isNotEmpty) {
                _addContact(nameController.text.trim(), keyController.text.trim());
                Navigator.of(context).pop();
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  void _addContact(String name, String publicKey) {
    // Pour la démo, générer un ID aléatoire
    final contact = Contact(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      publicKey: publicKey,
      lastSeen: DateTime.now(),
      isVerified: false,
    );

    // Dans une vraie app, on sauvegarderait via StorageService
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Contact \$name ajouté avec succès'),
        backgroundColor: Colors.green,
      ),
    );
  }
}