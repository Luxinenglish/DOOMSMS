import 'package:flutter/material.dart';

class SecurityIndicator extends StatelessWidget {
  final bool isSecure;
  final String? customMessage;

  const SecurityIndicator({
    super.key,
    required this.isSecure,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isSecure 
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSecure ? Colors.green : Colors.orange,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSecure ? Icons.lock : Icons.warning,
            size: 16,
            color: isSecure ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 6),
          Text(
            customMessage ?? (isSecure 
                ? 'Connexion sécurisée'
                : 'Connexion non sécurisée'),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isSecure ? Colors.green : Colors.orange,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class EncryptionBadge extends StatelessWidget {
  final bool isEncrypted;
  final String algorithm;

  const EncryptionBadge({
    super.key,
    required this.isEncrypted,
    this.algorithm = 'AES-256',
  });

  @override
  Widget build(BuildContext context) {
    if (!isEncrypted) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.withValues(alpha: 0.2),
            Colors.blue.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.security,
            size: 12,
            color: Colors.green[700],
          ),
          const SizedBox(width: 4),
          Text(
            algorithm,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.green[700],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class P2PStatusIndicator extends StatelessWidget {
  final bool isConnected;
  final int peersCount;

  const P2PStatusIndicator({
    super.key,
    required this.isConnected,
    this.peersCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isConnected 
            ? Colors.blue.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isConnected ? Icons.wifi : Icons.wifi_off,
            size: 14,
            color: isConnected ? Colors.blue : Colors.grey,
          ),
          const SizedBox(width: 4),
          Text(
            isConnected 
                ? 'P2P ($peersCount peers)'
                : 'Déconnecté',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isConnected ? Colors.blue : Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}