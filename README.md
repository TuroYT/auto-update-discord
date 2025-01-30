# Script de Mise à Jour Automatique avec Notifications Discord

Ce script permet de configurer les mises à jour automatiques sur un serveur Debian/Ubuntu et d'envoyer des notifications via Discord lorsque des mises à jour sont effectuées.

## Installation

   ```bash
   sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/TuroYT/auto-update-discord/main/auto-update-discord.sh)"

   ```


## Comment ça marche

1. Le script installe et configure unattended-upgrades
2. Il met en place un script de notification Discord
3. Après chaque mise à jour automatique, une notification est envoyée sur votre canal Discord

