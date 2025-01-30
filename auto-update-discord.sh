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
    "\${distro_id}:\${distro_codename}-security";
    // "\${distro_id}:\${distro_codename}-updates";
    // "\${distro_id}:\${distro_codename}-proposed";
    // "\${distro_id}:\${distro_codename}-backports";
};
EOL

# Créer le script de notification Discord
cat <<EOL > /usr/local/bin/discord-notify.sh
#!/bin/bash

WEBHOOK_URL="$WEBHOOK_URL"
HOST=\$(hostname)
MESSAGE="Une mise à jour a été effectuée sur le serveur \$HOST."

curl -H "Content-Type: application/json" -X POST -d "{\"content\": \"\$MESSAGE\"}" \$WEBHOOK_URL
EOL

# Rendre le script exécutable
chmod +x /usr/local/bin/discord-notify.sh

# Configurer le hook post-mise à jour
cat <<EOL > /etc/apt/apt.conf.d/51unattended-upgrades-discord
Dpkg::Post-Invoke { "/usr/local/bin/discord-notify.sh"; };
EOL

echo "Configuration terminée. Unattended-Upgrades est maintenant configuré pour envoyer des notifications à Discord après chaque mise à jour."
