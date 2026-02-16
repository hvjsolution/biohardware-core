#!/bin/bash

# Colores para la terminal
VERDE='\033[0;32m'
NC='\033[0m'

echo -e "${VERDE}🧬 Iniciando Instalación de BioHardware...${NC}"

# 1. Pedir el ID del Cliente
read -p "Ingrese el ID del Cliente (ej. C001): " ID_CLIENTE

# 2. Crear estructura de carpetas
sudo mkdir -p /opt/biohardware

# 3. Crear el archivo de identidad
echo "$ID_CLIENTE" | sudo tee /opt/biohardware/id > /dev/null

# 4. Mover el ejecutable binario (ya compilado) a la carpeta
# Asumimos que el archivo binario se llama 'biohardware' (sin .sh)
if [ -f "./biohardware" ]; then
    sudo mv ./biohardware /opt/biohardware/
    sudo chmod +x /opt/biohardware/biohardware
else
    echo "❌ Error: No se encontró el archivo binario 'biohardware'."
    exit 1
fi

# 5. Configurar el Crontab (evitando duplicados)
CRON_JOB="*/15 * * * * /opt/biohardware/biohardware"
(crontab -l 2>/dev/null | grep -v "/opt/biohardware/biohardware" ; echo "$CRON_JOB") | crontab -

echo -e "${VERDE}✅ Instalación completada para el cliente $ID_CLIENTE${NC}"
