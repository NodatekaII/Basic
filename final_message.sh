#!/bin/bash

# Цвета для текста
TERRACOTTA='\033[38;5;208m'
LIGHT_BLUE='\033[38;5;117m'
BOLD='\033[1m'
NC='\033[0m'


function show_bold() {
    echo -en "${TERRACOTTA}${BOLD}$1${NC}"
}

# Вывод финального сообщения
echo ''
show_bold "╔═══════════════════════════════════════════════════════════════════╗"
echo ""
show_bold "║ Присоединяйся к Нодатеке, будем ставить ноды вместе!              ║"
echo ''
echo -en "${TERRACOTTA}${BOLD}║ Telegram: ${NC}${LIGHT_BLUE}https://t.me/cryptotesemnikov/778${NC}${TERRACOTTA}${BOLD}                       ║${NC}\n"
echo -en "${TERRACOTTA}${BOLD}║ Twitter: ${NC}${LIGHT_BLUE}https://x.com/nodateka${NC}${TERRACOTTA}${BOLD}                                   ║${NC}\n"
echo -en "${TERRACOTTA}${BOLD}║ YouTube: ${NC}${LIGHT_BLUE}https://www.youtube.com/@CryptoTesemnikov${NC}${TERRACOTTA}${BOLD}                ║${NC}\n"
show_bold '╚═══════════════════════════════════════════════════════════════════╝'
echo ""

# Ожидание 3 секунды перед началом процесса
sleep 1
