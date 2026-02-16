#!/bin/bash

# --- CONFIGURACIÓN CENTRALIZADA ---
URL_BINARIO="https://raw.githubusercontent.com/hvjsolution/biohardware-core/main/biohardware"
URL_FIREBASE="https://biohardware-5f47c-default-rtdb.firebaseio.com/clientes" # Reemplaza con tu URL real

# Colores para la terminal
VERDE='\033[0;32m'
ROJO='\033[0;31m'
NC='\033[0m'

echo -e "${VERDE}🧬 Iniciando Instalación Cloud de BioHardware...${NC}"

# 1. Pedir el ID del Cliente
read -p "Ingrese el ID del Cliente (ej. C001): " ID_CLIENTE

# 2. Crear estructura de carpetas de sistema
sudo mkdir -p /opt/biohardware

# 3. Crear el archivo de identidad
echo "$ID_CLIENTE" | sudo tee /opt/biohardware/id > /dev/null

# 4. DESCARGAR EL BINARIO DESDE GITHUB (Paso Crítico)
echo "📥 Descargando componente binario desde el servidor..."
sudo curl -sL "$URL_BINARIO" -o /opt/biohardware/biohardware

if [ $? -eq 0 ]; then
    sudo chmod +x /opt/biohardware/biohardware
    echo -e "${VERDE}✅ Binario instalado correctamente.${NC}"
else
    echo -e "${ROJO}❌ Error: No se pudo descargar el binario. Verifique su conexión.${NC}"
    exit 1
fi

# 5. PRUEBA DE CONEXIÓN CON FIREBASE (Opcional pero recomendado)
echo "🔌 Verificando estado del cliente en la base de datos..."
CHECK=$(curl -s "$URL_FIREBASE/$ID_CLIENTE/operativo/status.json" | tr -d '"')

if [ "$CHECK" == "ACTIVO" ]; then
    echo -e "${VERDE}✅ Cliente $ID_CLIENTE validado y activo.${NC}"
else
    echo -e "${ROJO}⚠️  Aviso: El ID $ID_CLIENTE no figura como ACTIVO. El script no enviará alertas hasta que se active.${NC}"
fi

# 6. Configurar el Crontab (evitando duplicados)
CRON_JOB="*/15 * * * * /opt/biohardware/biohardware"
(crontab -l 2>/dev/null | grep -v "/opt/biohardware/biohardware" ; echo "$CRON_JOB") | crontab -

echo -e "\n${VERDE}🚀 ¡Instalación Finalizada Exitosamente!${NC}"	
