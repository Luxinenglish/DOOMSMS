# DoomSMS - Architecture Plan

## Vue d'ensemble
DoomSMS est une application de messagerie sécurisée peer-to-peer avec chiffrement de bout en bout.

## Fonctionnalités principales
1. **Communication P2P sécurisée**: Chiffrement end-to-end RSA/AES
2. **Gestion d'identité**: Génération de clés et découverte de pairs
3. **Échange de messages**: Chat chiffré avec statut de livraison
4. **Fonctionnalités de sécurité**: Suppression de messages, indicateurs de chiffrement
5. **Interface moderne**: Thèmes sombre/clair avec animations

## Architecture technique

### Stratégie de chiffrement
- RSA-2048 pour l'échange de clés
- AES-256-GCM pour le chiffrement des messages
- Stockage local pour les clés et messages
- Aucune dépendance serveur - P2P pur

### Structure des fichiers
```
lib/
├── main.dart (mis à jour)
├── theme.dart (amélioré)
├── models/
│   ├── message.dart
│   ├── contact.dart
│   └── key_pair.dart
├── services/
│   ├── encryption_service.dart
│   ├── p2p_service.dart
│   └── storage_service.dart
├── screens/
│   ├── home_page.dart
│   ├── chat_page.dart
│   ├── contacts_page.dart
│   └── settings_page.dart
└── widgets/
    ├── message_bubble.dart
    ├── contact_card.dart
    └── security_indicator.dart
```

### Modèles de données
- **Message**: contenu chiffré, timestamp, statut
- **Contact**: clé publique, nom, dernière activité
- **KeyPair**: clés RSA publique/privée locales

### Services
- **EncryptionService**: chiffrement/déchiffrement RSA+AES
- **P2PService**: découverte et communication réseau
- **StorageService**: persistance locale sécurisée

### Interface utilisateur
- Navigation par onglets (Chats, Contacts, Paramètres)
- Messages en bulles avec indicateurs de sécurité
- Animations fluides et design moderne
- Thème adaptatif sombre/clair