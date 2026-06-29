#!/usr/bin/env bash
# Assistant d'installation Aetheris — Version française
# Usage: bash scripts/setup-fr.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     π Aetheris — Assistant d'installation   ║${NC}"
echo -e "${BLUE}║     Détection spatiale par WiFi           ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"
echo ""

# Vérification des prérequis
echo -e "${YELLOW}Vérification des prérequis...${NC}"

check_dep() {
    if command -v "$1" &>/dev/null; then
        echo -e "  ${GREEN}✓${NC} $1 trouvé"
    else
        echo -e "  ${RED}✗${NC} $1 manquant"
        return 1
    fi
}

check_dep "python3"
check_dep "pip3" || check_dep "pip"
check_dep "docker" || echo -e "  ${YELLOW}⚠ Docker optionnel (mode démo)${NC}"
check_dep "git"
check_dep "curl"

echo ""

# Menu principal
echo -e "${BLUE}Choisissez un mode d'installation :${NC}"
echo "  1) Mode Python (recommandé pour débuter)"
echo "  2) Mode Docker (simulation, sans matériel)"
echo "  3) Mode complet (Rust + Python + Firmware)"
echo "  4) Mode démo (Docker, pas de matériel requis)"
echo "  5) Vérifier le matériel uniquement"
echo ""

read -p "Votre choix (1-5) : " choice

case $choice in
    1)
        echo -e "\n${GREEN}Installation mode Python...${NC}"
        pip install ruview
        pip install "ruview[client]"
        echo -e "\n${GREEN}✓ Installation terminée !${NC}"
        echo -e "Lancez : ${BLUE}python -m ruview${NC}"
        ;;
    2)
        echo -e "\n${GREEN}Installation mode Docker...${NC}"
        docker pull ruvnet/wifi-densepose:latest
        echo -e "\n${GREEN}✓ Image téléchargée !${NC}"
        echo -e "Lancez : ${BLUE}docker run -p 3000:3000 ruvnet/wifi-densepose:latest${NC}"
        echo -e "Ouvrez : ${BLUE}http://localhost:3000${NC}"
        ;;
    3)
        echo -e "\n${GREEN}Installation mode complet...${NC}"
        if command -v cargo &>/dev/null; then
            echo -e "  ${GREEN}✓ Rust trouvé${NC}"
        else
            echo -e "  ${YELLOW}Installation de Rust...${NC}"
            curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
            source "$HOME/.cargo/env"
        fi
        pip install -r requirements.txt
        cd v2 && cargo build --release && cd ..
        echo -e "\n${GREEN}✓ Installation complète terminée !${NC}"
        ;;
    4)
        echo -e "\n${GREEN}Lancement du mode démo...${NC}"
        docker pull ruvnet/wifi-densepose:latest
        docker run -p 3000:3000 ruvnet/wifi-densepose:latest
        ;;
    5)
        echo -e "\n${GREEN}Vérification du matériel...${NC}"
        echo ""
        if lsusb 2>/dev/null | grep -qi "ESP32"; then
            echo -e "  ${GREEN}✓ ESP32 détecté${NC}"
        else
            echo -e "  ${YELLOW}⚠ Aucun ESP32 trouvé${NC}"
            echo -e "  Branchez un ESP32-S3 sur un port USB"
        fi
        if command -v esptool.py &>/dev/null || pip3 show esptool &>/dev/null; then
            echo -e "  ${GREEN}✓ esptool trouvé${NC}"
        else
            echo -e "  ${YELLOW}⚠ esptool manquant${NC}"
            echo -e "  Installez : ${BLUE}pip install esptool${NC}"
        fi
        if python3 -c "import serial" 2>/dev/null; then
            echo -e "  ${GREEN}✓ pyserial trouvé${NC}"
        else
            echo -e "  ${YELLOW}⚠ pyserial manquant${NC}"
            echo -e "  Installez : ${BLUE}pip install pyserial${NC}"
        fi
        ;;
    *)
        echo -e "${RED}Choix invalide${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Documentation : https://ruvnet.github.io/Aetheris/ ║${NC}"
echo -e "${BLUE}║  Support : github.com/ruvnet/Aetheris/issues ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"
