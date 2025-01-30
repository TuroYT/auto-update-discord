# Script de Mise à Jour Automatique avec Notifications Discord

Ce script permet de configurer les mises à jour automatiques sur un serveur Debian/Ubuntu et d'envoyer des notifications via Discord lorsque des mises à jour sont effectuées.

## Prérequis

- Un système d'exploitation Debian ou Ubuntu
- Accès root ou privilèges sudo
- Une URL de webhook Discord valide

## Installation

1. Clonez ce dépôt ou téléchargez le script `auto-update-discord.sh`
2. Rendez le script exécutable :
   ```bash
   chmod +x auto-update-discord.sh
   ```
3. Exécutez le script en tant que root :
   ```bash
   sudo ./auto-update-discord.sh
   ```

## Fonctionnalités

- Configuration automatique de unattended-upgrades
- Installation des dépendances nécessaires
- Mise en place des notifications Discord
- Configuration des mises à jour de sécurité automatiques

## Configuration

Lors de l'exécution du script, vous devrez fournir :
- L'URL de votre webhook Discord

## Comment ça marche

1. Le script installe et configure unattended-upgrades
2. Il met en place un script de notification Discord
3. Après chaque mise à jour automatique, une notification est envoyée sur votre canal Discord

## Notes de sécurité

- Gardez votre URL de webhook Discord privée
- Le script doit être exécuté avec les privilèges root
- Seules les mises à jour de sécurité sont activées par défaut

## Support

Pour tout problème ou question, veuillez ouvrir une issue dans ce dépôt.
