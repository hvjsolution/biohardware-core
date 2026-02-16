#!/bin/bash

# --- CONFIGURACIÓN (REEMPLAZA CON TU URL REAL) ---
URL_BASE="https://tu-proyecto-rtdb.firebaseio.com/clientes"
URL_BINARIO="https://raw.githubusercontent.com/hvjsolution/biohardware-core/main/biohardware"

# Colores para la terminal
VERDE='\033[0;32m'
ROJO='\033[0;31m'
NC='\033[0m'

echo -e "${VERDE}🧬 INSTALADOR BIOHARDWARE V10 (Hardware ID & Cloud Validation)${NC}"

# 1. Identificación del Cliente (Soporta entrada directa o prompt)
ID_CLIENTE=$1
if [ -z "$ID_CLIENTE" ]; then
    read -p "Ingrese el ID del Cliente (ej. C001): " ID_CLIENTE
fi

# 2. Validación Quirúrgica en Firebase
echo "🔍 Conectando con el servidor de licencias..."
# Eliminamos comillas y espacios de la respuesta de Firebase
STATUS=$(curl -sL "$URL_BASE/$ID_CLIENTE/operativo/status.json" | tr -d '"' | tr -d ' ')

if [ "$STATUS" != "ACTIVO" ]; then
    echo -e "${ROJO}❌ Error: Licencia inválida o cliente suspendido.${NC}"
    echo -e "Respuesta del servidor: ${ROJO}${STATUS:-NULL}${NC}"
    exit 1
fi

echo -e "${VERDE}✅ Licencia Validada.${NC}"

# 3. Preparación de carpetas y persistencia de ID
sudo mkdir -p /opt/biohardware
echo "$ID_CLIENTE" | sudo tee /opt/biohardware/id > /dev/null

# 4. Descarga del motor binario
echo "📥 Descargando componentes de monitoreo..."
sudo curl -sL "$URL_BINARIO" -o /opt/biohardware/biohardware

if [ $? -eq 0 ]; then
    sudo chmod +x /opt/biohardware/biohardware
else
    echo -e "${ROJO}❌ Error: Falló la descarga del binario desde GitHub.${NC}"
    exit 1
fi

# 5. Notificación de Seguridad a Telegram
echo "📡 Registrando Hardware ID..."
# Obtenemos datos del cliente para el bot
OPERATIVO_DATA=$(curl -sL "$URL_BASE/$ID_CLIENTE/operativo.json")
TOKEN=$(echo "$OPERATIVO_DATA" | grep -oP '(?<="token":")[^"]+')
CHAT_ID=$(echo "$OPERATIVO_DATA" | grep -oP '(?<="chat_id":")[^"]+')

# Datos físicos del equipo
IP_PUBLICA=$(curl -s https://ifconfig.me)
HOSTNAME=$(hostname)
IFACE=$(ip route | grep default | awk '{print $5}' | head -n1)
MAC_ADDR=$(ip link show $IFACE | grep link/ether | awk '{print $2}' | tr '[:lower:]' '[:upper:]')

MSG="🔔 *NUEVA INSTALACIÓN DETECTADA*
--------------------------
👤 *Cliente:* $ID_CLIENTE
💻 *Equipo:* $HOSTNAME
🆔 *MAC:* $MAC_ADDR
🌐 *IP:* $IP_PUBLICA
📅 *Fecha:* $(date '+%d/%m/%Y %H:%M')
--------------------------
_Verificación de seguridad BioHardware_"

curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
    -d "chat_id=$CHAT_ID" -d "text=$MSG" -d "parse_mode=Markdown" > /dev/null

# 6. Configuración de tarea automática (Cron) cada 15 min
(crontab -l 2>/dev/null | grep -v "/opt/biohardware/biohardware" ; echo "*/15 * * * * /opt/biohardware/biohardware") | crontab -

echo -e "\n${VERDE}🚀 INSTALACIÓN COMPLETADA CON ÉXITO${NC}"
echo -e "Equipo ID: ${VERDE}$MAC_ADDR${NC} registrado bajo el cliente ${VERDE}$ID_CLIENTE${NC}"
