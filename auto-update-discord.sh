#!/bin/bash

# Vérifiez si l'utilisateur est root
if [ "$EUID" -ne 0 ]
  then echo "Veuillez exécuter ce script en tant que root ou utiliser sudo."
  exit
fi

# Gestion des paramètres
WEBHOOK_URL=$1

# Si pas de webhook en paramètre, demander interactivement
if [ -z "$WEBHOOK_URL" ]; then
    read -p "Veuillez entrer l'URL de votre webhook Discord : " WEBHOOK_URL
fi

# Vérifier que le webhook est bien fourni
if [ -z "$WEBHOOK_URL" ]; then
    echo "Erreur: L'URL du webhook Discord est requise."
    echo "Usage: $0 [WEBHOOK_URL]"
    exit 1
fi

# Supprimer les configurations existantes (optionnel, mais recommandé pour un redémarrage propre)
apt remove unattended-upgrades -y
rm -f /etc/apt/apt.conf.d/50unattended-upgrades
rm -f /etc/apt/apt.conf.d/51unattended-upgrades-discord

# Installer les paquets nécessaires
apt-get update
apt-get install -y unattended-upgrades apt-listchanges curl

# Configurer Unattended-Upgrades
cat <<EOL > /etc/apt/apt.conf.d/50unattended-upgrades
Unattended-Upgrade::Allowed-Origins {
      "\${distro_id}:\${distro_codename}";
      "\${distro_id}:\${distro_codename}-security";
};
Unattended-Upgrade::Mail "";  # Ne pas envoyer de mail
Unattended-Upgrade::MailOnlyOnError "true"; # Option sans effet car pas d'envoi de mail
EOL

# Créer le script de notification Discord
cat <<EOL > /usr/local/bin/discord-notify.sh
#!/bin/bash

WEBHOOK_URL="$WEBHOOK_URL"
HOST=\$(hostname)
TIMESTAMP=\$(date '+%Y-%m-%d %H:%M:%S')
LOG_FILE="/var/log/unattended-upgrades/unattended-upgrades.log"

# Fonction pour envoyer un message Discord
send_discord_message() {
  JSON_DATA="$1"
  curl -H "Content-Type: application/json" -X POST -d "$JSON_DATA" "$WEBHOOK_URL"
}

# Récupérer les informations sur les mises à jour à partir du log
if [ -f "\$LOG_FILE" ]; then
  # Récupérer les paquets mis à jour
  UPDATED_PACKAGES_RAW=$(grep "will be upgraded" "$LOG_FILE" | sed 's/Package //g;s/ has a higher version available, checking if it is from an allowed origin and is not pinned down.//g')

  if [ -n "$UPDATED_PACKAGES_RAW" ]; then
    # Formatter la liste des paquets
    UPDATED_PACKAGES_FORMATTED=$(echo "$UPDATED_PACKAGES_RAW" | tr '\n' ',' | sed 's/,$//')
    UPDATE_SUMMARY="Mises à jour installées : $UPDATED_PACKAGES_FORMATTED"
  else
    UPDATE_SUMMARY="Aucune mise à jour installée."
  fi

  # Vérifier s'il y a des erreurs
  ERROR_MESSAGES=\$(grep "ERROR" "\$LOG_FILE" | tail -n 5)
  if [ -n "\$ERROR_MESSAGES" ]; then
    ERROR_SUMMARY="Erreurs détectées : \n\$ERROR_MESSAGES"
    ERROR_COLOR=15158332 # Rouge
  else
    ERROR_SUMMARY="Aucune erreur détectée."
    ERROR_COLOR=5814783 # Vert
  fi

else
  UPDATE_SUMMARY="Journal des mises à jour non trouvé."
  ERROR_SUMMARY="Journal des mises à jour non trouvé."
  ERROR_COLOR=16776960  # Jaune
fi

# Création du message Discord principal (mises à jour)
MAIN_JSON_DATA='{
    "embeds": [{
        "title": "🔄 Mise à jour système effectuée",
        "color": 5814783,
        "fields": [
            {
                "name": "Serveur",
                "value": "'\$HOST'",
                "inline": true
            },
            {
                "name": "Date",
                "value": "'\$TIMESTAMP'",
                "inline": true
            },
            {
                "name": "Mises à jour installées",
                "value": "'\$UPDATE_SUMMARY'"
            }
        ],
        "footer": {
            "text": "Système de mise à jour automatique"
        }
    }]
}'

# Création du message Discord (erreurs)
ERROR_JSON_DATA='{
    "embeds": [{
        "title": "⚠️ Rapport d\'erreurs - Mise à jour système",
        "color": '"\$ERROR_COLOR"',
        "fields": [
            {
                "name": "Serveur",
                "value": "'\$HOST'",
                "inline": true
            },
            {
                "name": "Date",
                "value": "'\$TIMESTAMP'",
                "inline": true
            },
            {
                "name": "Erreurs",
                "value": "'\$ERROR_SUMMARY'"
            }
        ],
        "footer": {
            "text": "Système de mise à jour automatique"
        }
    }]
}'


# Envoi des messages Discord
send_discord_message "\$MAIN_JSON_DATA"
send_discord_message "\$ERROR_JSON_DATA"

EOL

# Rendre le script exécutable
chmod +x /usr/local/bin/discord-notify.sh

# Configurer le hook post-mise à jour
cat <<EOL > /etc/apt/apt.conf.d/51unattended-upgrades-discord
Dpkg::Post-Invoke { " /usr/local/bin/discord-notify.sh || true"; };
EOL

# Activer unattended-upgrades
echo 'Unattended-Upgrade::Automatic-Updates "1";' > /etc/apt/apt.conf.d/20auto-upgrades

echo "Configuration terminée. Unattended-Upgrades est maintenant configuré pour envoyer des notifications à Discord après chaque mise à jour."

# Envoi d'un message de test
echo "Envoi d'un message de test à Discord..."
cat <<EOL > /tmp/discord-test.json
{
    "embeds": [{
        "title": "✅ Configuration réussie",
        "description": "Le système de notification Discord a été configuré avec succès sur le serveur $(hostname)",
        "color": 5814783,
        "fields": [
            {
                "name": "Test effectué le",
                "value": "$(date '+%Y-%m-%d %H:%M:%S')",
                "inline": true
            }
        ],
        "footer": {
            "text": "Système de mise à jour automatique - Message de test"
        }
    }]
}
EOL

curl -H "Content-Type: application/json" -X POST -d @/tmp/discord-test.json "$WEBHOOK_URL"
rm /tmp/discord-test.json

echo "Si vous avez reçu un message sur Discord, la configuration est réussie !"

# Exécuter une première mise à jour (simulée) pour tester la configuration
echo "Simulation d'une mise à jour pour tester la notification..."
unattended-upgrade -d -v
