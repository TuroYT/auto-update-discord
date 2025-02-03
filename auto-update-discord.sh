#!/bin/bash

# Vérifiez si l'utilisateur est root
if [ "$EUID" -ne 0 ]
  then echo "Veuillez exécuter ce script en tant que root ou utiliser sudo."
  exit
fi

# URL du webhook Discord
read -p "Veuillez entrer l'URL de votre webhook Discord : " WEBHOOK_URL

# Installer les paquets nécessaires
apt-get update
apt-get install -y unattended-upgrades curl

# Configurer Unattended-Upgrades
cat <<EOL > /etc/apt/apt.conf.d/50unattended-upgrades
Unattended-Upgrade::Allowed-Origins {
      "\${distro_id}:\${distro_codename}";
      "\${distro_id}:\${distro_codename}-security";
      "\${distro_id}:\${distro_codename}-updates";
      "\${distro_id}:\${distro_codename}-proposed";
      "\${distro_id}:\${distro_codename}-backports";
};
EOL

# Créer le script de notification Discord
cat <<EOL > /usr/local/bin/discord-notify.sh
#!/bin/bash

WEBHOOK_URL="$WEBHOOK_URL"
HOST=\$(hostname)
TIMESTAMP=\$(date '+%Y-%m-%d %H:%M:%S')
UPDATES=\$(cat /var/log/unattended-upgrades/unattended-upgrades.log | grep -A 2 "Packages that will be upgraded" | tail -n 2)

# Création du message Discord avec un embed
JSON_DATA='{
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
                "value": "'\${UPDATES:-Aucune mise à jour détaillée disponible}'"
            }
        ],
        "footer": {
            "text": "Système de mise à jour automatique"
        }
    }]
}'

curl -H "Content-Type: application/json" -X POST -d "\$JSON_DATA" \$WEBHOOK_URL
EOL

# Rendre le script exécutable
chmod +x /usr/local/bin/discord-notify.sh

# Configurer le hook post-mise à jour
cat <<EOL > /etc/apt/apt.conf.d/51unattended-upgrades-discord
Dpkg::Post-Invoke { "/usr/local/bin/discord-notify.sh"; };
EOL

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

curl -H "Content-Type: application/json" -X POST -d @/tmp/discord-test.json $WEBHOOK_URL
rm /tmp/discord-test.json

echo "Si vous avez reçu un message sur Discord, la configuration est réussie !"
