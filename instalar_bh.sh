#!/bin/bash

# --- CONFIGURACIÓN ---
URL_BASE="https://tu-proyecto-rtdb.firebaseio.com/clientes"
URL_BINARIO="https://raw.githubusercontent.com/hvjsolution/biohardware-core/main/biohardware"

VERDE='\033[0;32m'
ROJO='\033[0;31m'
NC='\033[0m'

echo -e "${VERDE}🧬 INSTALADOR BIOHARDWARE V9.2 (Hardware ID Edition)${NC}"

# 1. Identificación
read -p "Ingrese el ID del Cliente: " ID_CLIENTE

# 2. Validación
DATA_CLIENTE=$(curl -s "$URL_BASE/$ID_CLIENTE/operativo.json")
STATUS=$(echo "$DATA_CLIENTE" | grep -oP '(?<="status":")[^"]+')

if [ "$STATUS" != "ACTIVO" ]; then
    echo -e "${ROJO}❌ Error: Licencia inválida o cliente suspendido.${NC}"
    exit 1
fi

# 3. Instalación
sudo mkdir -p /opt/biohardware
echo "$ID_CLIENTE" | sudo tee /opt/biohardware/id > /dev/null
sudo curl -sL "$URL_BINARIO" -o /opt/biohardware/biohardware
sudo chmod +x /opt/biohardware/biohardware

# 4. Captura de Identidad Única (MAC y IP)
TOKEN=$(echo "$DATA_CLIENTE" | grep -oP '(?<="token":")[^"]+')
CHAT_ID=$(echo "$DATA_CLIENTE" | grep -oP '(?<="chat_id":")[^"]+')
IP_PUBLICA=$(curl -s https://ifconfig.me)
HOSTNAME=$(hostname)
# Captura la MAC de la interfaz con ruta por defecto
MAC_ADDR=$(ip link show $(ip route | grep default | awk '{print $5}' | head -n1) | grep link/ether | awk '{print $2}' | tr '[:lower:]' '[:upper:]')

MSG="🔔 *NUEVA INSTALACIÓN DETECTADA*
--------------------------
👤 *Cliente:* $ID_CLIENTE
💻 *Equipo:* $HOSTNAME
🆔 *MAC:* $MAC_ADDR
🌐 *IP:* $IP_PUBLICA
--------------------------
_ID de Hardware verificado._"

curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
    -d "chat_id=$CHAT_ID" -d "text=$MSG" -d "parse_mode=Markdown" > /dev/null

# 5. Cron
CRON_JOB="*/15 * * * * /opt/biohardware/biohardware"
(crontab -l 2>/dev/null | grep -v "/opt/biohardware/biohardware" ; echo "$CRON_JOB") | crontab -

echo -e "${VERDE}✅ Instalación completada. Hardware ID registrado: $MAC_ADDR${NC}"
