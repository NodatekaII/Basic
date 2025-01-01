#!/bin/bash



# Проверка наличия curl и установка, если не установлен
if ! command -v curl &> /dev/null; then
    sudo apt update
    sudo apt install curl -y
fi
sleep 1

# Цвета для текста
TERRACOTTA='\033[38;5;208m'
LIGHT_BLUE='\033[38;5;117m'
RED='\033[0;31m'
BOLD='\033[1m'
PURPLE='\033[0;35m'
VIOLET='\033[38;5;93m'
BEIGE='\033[38;5;228m'
GOLD='\033[38;5;220m'
GREEN='\033[38;5;28m'
WHITE='\033[38;5;15m'
NC='\033[0m'


# Функции для форматирования текста
function show() {
    echo -e "${TERRACOTTA}$1${NC}"
}

function show_bold() {
    echo -en "${TERRACOTTA}${BOLD}$1${NC}"
}

function show_blue() {
    echo -e "${LIGHT_BLUE}$1${NC}"
}

function show_war() {
    echo -e "${RED}${BOLD}$1${NC}"
}

function show_purple() {
    echo -e "${PURPLE}$1${NC}"
}

function show_violet() {
    echo -e "${VIOLET}$1${NC}"
}

function show_beige() {
    echo -e "${BEIGE}$1${NC}"
}

function show_gold() {
    echo -e "${GOLD}$1${NC}"
}

function show_green() {
    echo -e "${GREEN}$1${NC}"
}

function show_white() {
    echo -e "${WHITE}$1${NC}"
}

function color_text() {
    local text="$1"
    local bg_color="$2"
    local fg_color="$3"
    echo -e "\033[48;5;${bg_color}m\033[38;5;${fg_color}m ${text} \033[0m"
}





# Логотип команды
show_logotip() {
    bash <(curl -s https://raw.githubusercontent.com/NodatekaII/Basic/refs/heads/main/name.sh)
}

#финальное сообщение
final_message() {
    bash <(curl -s https://raw.githubusercontent.com/NodatekaII/Basic/refs/heads/main/final_message.sh) 
}

# Функция для подтверждения действия
confirm() {
    local prompt="$1"
    show_bold "❓ $prompt [y/n, Enter = yes]: "  # Выводим вопрос с цветом
    read choice  # Читаем ввод пользователя
    case "$choice" in
        ""|y|Y|yes|Yes)  # Пустой ввод или "да"
            return 0  # Подтверждение действия
            ;;
        n|N|no|No)  # Любой вариант "нет"
            return 1  # Отказ от действия
            ;;
        *)
            show_war '⚠️ Пожалуйста, введите y или n.'
            confirm "$prompt"  # Повторный запрос, если ответ не распознан
            ;;
    esac
}


# Название узла
show_name() {
   echo ""
   show_green '░░░░░░█▀▀█░█▀▀█░█▀▀█░█▀▀░█▀▀█░█▄░░█░█▀▀█░░░░░░█▀▀█░█▀▀█░█▀▀░▀█▀░░░░░░'
   show_green '░░░░░░█░▄▄░█▄▄▀░█▀▀█░█▀▀░█▀▀█░█░█░█░█▀▀█░░░░░░▀▀▄▄░█░░█░█▀▀░░█░░░░░░░'
   show_green '░░░░░░█▄▄█░█░░█░█░░█░█░░░█░░█░█░░▀█░█░░█░░░░░░█▄▄█░█▄▄█░█░░░░█░░░░░░░'
   show_green '---------------------------------------------------------------------'
   #show_white '                                                 script version: v0.2'
   echo ""
}

# Меню с командами
show_menu() {
    show_logotip
    show_name
    show_bold 'Выберите действие: '
    echo ''
    actions=(
        "1. Установка мониторинга на ведущий сервер"
        "2. Установка мониторинга на ведомый сервер"
        "3. Добавление новых серверов для мониторинга"
        "4. Удаление серверов из мониторинга"
        "5. Просмотр состояния служб"

        "9. Удаление служб мониторинга"
        "0. Выход"

    )
    for action in "${actions[@]}"; do
        show "$action"
    done
}

# Проверка на запуск от имени root
if [ "$EUID" -ne 0 ]; then
  show_war "⚠️ Пожалуйста, запустите скрипт с правами root."
  exit 1
fi

################################################################################################

# Установка переменных версий
PROMETHEUS_VERSION="2.54.1"
NODE_EXPORTER_VERSION="1.8.2"
GRAFANA_VERSION="11.2.0"
# Получение реального IP сервера
SERVER_IP=$(curl -s https://ipinfo.io/ip)

# Установка Prometheus
prometheus_install() {
    show "Установка Prometheus версии $PROMETHEUS_VERSION..."

    # Скачивание и установка
    cd /tmp || { show_war "❌ Не удалось перейти в /tmp"; exit 1; }
    wget -q https://github.com/prometheus/prometheus/releases/download/v$PROMETHEUS_VERSION/prometheus-$PROMETHEUS_VERSION.linux-amd64.tar.gz || { show_war "❌ Ошибка при скачивании Prometheus."; exit 1; }
    tar xvfz prometheus-$PROMETHEUS_VERSION.linux-amd64.tar.gz > /dev/null || { show_war "❌ Ошибка при распаковке архива."; exit 1; }
    mv prometheus-$PROMETHEUS_VERSION.linux-amd64/prometheus /usr/bin/ || { show_war "❌ Ошибка при перемещении Prometheus."; exit 1; }
    rm -rf /tmp/prometheus* || { show_war "❌ Ошибка при очистке временных файлов."; exit 1; }

    # Создание директорий
    mkdir -p /etc/prometheus /etc/prometheus/data || { show_war "❌ Ошибка при создании директорий."; exit 1; }

    # Создание конфигурационного файла
    cat <<EOF > /etc/prometheus/prometheus.yml
global:
  scrape_interval: 15s
scrape_configs:
  - job_name: "prometheus"
    static_configs:
      - targets: ["localhost:9090"]
EOF

    # Настройка пользователя
    if ! id -u prometheus &>/dev/null; then
        useradd -rs /bin/false prometheus
    fi
    chown -R prometheus:prometheus /usr/bin/prometheus /etc/prometheus || { show_war "❌ Ошибка при настройке прав."; exit 1; }

    # Создание службы
    cat <<EOF > /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus Server
After=network.target

[Service]
User=prometheus
Group=prometheus
Type=simple
Restart=on-failure
ExecStart=/usr/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/etc/prometheus/data

[Install]
WantedBy=multi-user.target
EOF

    # Запуск и включение службы
    systemctl daemon-reload || { show_war "❌ Ошибка systemctl daemon-reload."; exit 1; }
    systemctl start prometheus || { show_war "❌ Ошибка запуска Prometheus."; exit 1; }
    systemctl enable prometheus || { show_war "❌ Ошибка включения автозапуска Prometheus."; exit 1; }

    show_bold "✅ Prometheus установлен и запущен успешно."
    echo ""
}

node_exporter_install() {
    show "Установка Node Exporter версии $NODE_EXPORTER_VERSION..."

    # Скачивание и установка
    cd /tmp || { show_war "❌ Не удалось перейти в /tmp"; exit 1; }
    wget -q https://github.com/prometheus/node_exporter/releases/download/v$NODE_EXPORTER_VERSION/node_exporter-$NODE_EXPORTER_VERSION.linux-amd64.tar.gz || { show_war "❌ Ошибка при скачивании Node Exporter."; exit 1; }
    tar xvfz node_exporter-$NODE_EXPORTER_VERSION.linux-amd64.tar.gz > /dev/null || { show_war "❌ Ошибка при распаковке архива."; exit 1; }
    mv node_exporter-$NODE_EXPORTER_VERSION.linux-amd64/node_exporter /usr/bin/ || { show_war "❌ Ошибка при перемещении Node Exporter."; exit 1; }
    rm -rf /tmp/node_exporter* || { show_war "❌ Ошибка при очистке временных файлов."; exit 1; }

    # Создание пользователя
    if ! id -u node_exporter &>/dev/null; then
        useradd -rs /bin/false node_exporter || { show_war "❌ Ошибка при создании пользователя node_exporter."; exit 1; }
    fi
    chown node_exporter:node_exporter /usr/bin/node_exporter || { show_war "❌ Ошибка при настройке прав."; exit 1; }

    # Создание службы
    cat <<EOF > /etc/systemd/system/node_exporter.service
[Unit]
Description=Prometheus Node Exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
Restart=on-failure
ExecStart=/usr/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

    # Запуск службы
    systemctl daemon-reload || { show_war "❌ Ошибка systemctl daemon-reload."; exit 1; }
    systemctl start node_exporter || { show_war "❌ Ошибка запуска Node Exporter."; exit 1; }
    systemctl enable node_exporter || { show_war "❌ Ошибка включения автозапуска Node Exporter."; exit 1; }

    show_bold "✅ Node Exporter установлен и запущен успешно."
    echo ""
}

grafana_install() {
    # Установка Grafana
    show "Установка Grafана..."
    apt-get install -y apt-transport-https software-properties-common wget > /dev/null || { show_war "❌ Ошибка: Не удалось установить зависимости для Grafana."; return 1; }
    mkdir -p /etc/apt/keyrings/ || { show_war "❌ Ошибка: Не удалось создать папку /etc/apt/keyrings."; return 1; }
    wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor > /etc/apt/keyrings/grafana.gpg || { show_war "❌ Ошибка: Не удалось скачать ключ для Grafana."; return 1; }
    echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" > /etc/apt/sources.list.d/grafana.list
    apt-get update > /dev/null || { show_war "❌ Ошибка: Не удалось обновить репозитории."; return 1; }
    apt-get install -y grafana || { show_war "❌ Ошибка: Не удалось установить Grafana."; return 1; }

    # Настройка источника данных Prometheus в Grafana
    show "Настройка источника данных Prometheus в Grafana..."
    mkdir -p /etc/grafana/provisioning/datasources
    PROMETHEUS_IP=$SERVER_IP
    cat <<EOF > /etc/grafana/provisioning/datasources/prometheus.yaml
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    url: http://$PROMETHEUS_IP:9090
    access: proxy
    isDefault: true
EOF

    # Запрос порта для Grafana
    echo -en "${TERRACOTTA}${BOLD}Введи порт для Grafana (по умолчанию 3010): ${NC}"
    read GRAFANA_PORT
    GRAFANA_PORT=${GRAFANA_PORT:-3010}
    export GRAFANA_PORT

    # Замена порта в файле конфигурации Grafana
    sed -i "s/;http_port = 3000/http_port = $GRAFANA_PORT/" /etc/grafana/grafana.ini || { show_war "❌ Ошибка: Не удалось изменить порт Grafana."; return 1; }

    # Запуск и включение Grafana
    systemctl daemon-reload
    systemctl enable grafana-server > /dev/null || { show_war "❌ Ошибка: Не удалось включить Grafana в автозагрузку."; return 1; }
    systemctl start grafana-server > /dev/null || { show_war "❌ Ошибка: Не удалось запустить Grafana."; return 1; }
    show_bold "✅ Grafana успешно установлена и запущена на порту $GRAFANA_PORT."
    echo ""

}

add_dashboard() {
    show "Добавление дашборда в Grafana..."

    # Директория для дашбордов
    mkdir -p /etc/grafana/provisioning/dashboards
    mkdir -p /var/lib/grafana/dashboards

    # Предложение выбрать язык дашборда
    show_bold "Выберите язык интерфейса дашборда Grafana"
    echo ""
    show "1. Английский"
    show "2. Русский"
    read -p "$(show_bold 'Ваш выбор (по умолчанию 1): ')" DASHBOARD_CHOICE
    DASHBOARD_CHOICE=${DASHBOARD_CHOICE:-1}

    # Определение ссылки и имени файла на основе выбора
    if [[ "$DASHBOARD_CHOICE" == "2" ]]; then
        DASHBOARD_URL="https://raw.githubusercontent.com/NodatekaII/Basic/refs/heads/main/Grafana/grafana_nodateka_ru.json"
        DASHBOARD_NAME="grafana_nodateka_ru.json"
    else
        DASHBOARD_URL="https://raw.githubusercontent.com/NodatekaII/Basic/refs/heads/main/Grafana/grafana_nodateka_eng.json"
        DASHBOARD_NAME="grafana_nodateka_eng.json"
    fi

    DASHBOARD_PATH="/var/lib/grafana/dashboards/$DASHBOARD_NAME"

    # Скачивание выбранного файла дашборда
    wget -q -O "$DASHBOARD_PATH" "$DASHBOARD_URL" || { show_war "❌ Ошибка: Не удалось скачать дашборд с $DASHBOARD_URL."; return 1; }

    # Конфигурация провиженинга для дашбордов
    cat <<EOF > /etc/grafana/provisioning/dashboards/default.yaml
apiVersion: 1
providers:
  - name: "default"
    orgId: 1
    folder: ""
    type: file
    disableDeletion: false
    editable: true
    updateIntervalSeconds: 10
    options:
      path: /var/lib/grafana/dashboards
EOF

    # Конфигурация источника данных Prometheus
    PROMETHEUS_IP=$SERVER_IP
    cat <<EOF > /etc/grafana/provisioning/datasources/prometheus.yaml
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    url: http://$PROMETHEUS_IP:9090
    access: proxy
    isDefault: true
EOF

    # Перезапуск Grafana для применения изменений
    systemctl restart grafana-server
    if [[ $? -eq 0 ]]; then
        show_bold "✅ Дашборд ($DASHBOARD_NAME) успешно добавлен в Grafana. Перезапуск завершён."
        echo ""
    else
        show_war "❌ Ошибка: Не удалось перезапустить Grafana."
        return 1
    fi
}



configure_prometheus() {
    local prometheus_config_path="/etc/prometheus/prometheus.yml"

    # Проверяем, существует ли файл конфигурации Prometheus
    if [[ ! -f "$prometheus_config_path" ]]; then
        show "Создание нового файла конфигурации Prometheus..."
        cat <<EOF > "$prometheus_config_path"
global:
  scrape_interval: 15s
scrape_configs:
  - job_name: "nodateka"
    static_configs:
      - targets: ["localhost:9090"]
EOF
        show_bold "✅ Базовая конфигурация создана в $prometheus_config_path."
        echo ""
    fi

    # Добавление основного сервера
    echo -en "${TERRACOTTA}${BOLD}Введи имя основного сервера (на который сейчас происходит установка): ${NC}"
    read MAIN_SERVER_NAME

    # Проверка на существование записи основного сервера
    if ! grep -q "$MAIN_SERVER_NAME" "$prometheus_config_path"; then
        cat <<EOF >> "$prometheus_config_path"
      - targets: ["$SERVER_IP:9100"]
        labels:
          label: "$MAIN_SERVER_NAME"
EOF
        show_bold "✅ Ведущий сервер $MAIN_SERVER_NAME добавлен в Prometheus с IP: $SERVER_IP."
        echo ""
    else
        show_war "⚠️ Ведущий сервер $MAIN_SERVER_NAME уже существует в конфигурации Prometheus."
        echo ""
    fi
}



add_server() {
    # Путь к файлу конфигурации Prometheus
    local prometheus_config_path="/etc/prometheus/prometheus.yml"

    # Проверяем, существует ли файл
    if [[ ! -f "$prometheus_config_path" ]]; then
        show_war "❌ Файл $prometheus_config_path не найден. Убедитесь, что Prometheus установлен и файл существует."
        return 1
    fi

    # Цикл для добавления серверов
    while true; do
        if confirm "Хочешь добавить сервер для мониторинга?"; then
            echo -en "${TERRACOTTA}${BOLD}Введи IP адрес сервера: ${NC}"
            read NEW_SERVER_IP

            # Проверка корректности IP-адреса
            if [[ ! "$NEW_SERVER_IP" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
                show_war "❌ Некорректный IP адрес: $NEW_SERVER_IP. Попробуй снова."
                continue
            fi

            echo -en "${TERRACOTTA}${BOLD}Введи метку для сервера (например My_Server): ${NC}"
            read SERVER_LABEL

            # Проверяем наличие секции scrape_configs
            if ! grep -q "scrape_configs:" "$prometheus_config_path"; then
                show_war "❌ Файл $prometheus_config_path некорректный: отсутствует секция scrape_configs."
                return 1
            fi

            # Добавление нового сервера с меткой в файл конфигурации
            cat <<EOF >> "$prometheus_config_path"
      - targets: ["$NEW_SERVER_IP:9100"]
        labels:
          label: "$SERVER_LABEL"
EOF
            show_bold "✅ Сервер $NEW_SERVER_IP с меткой $SERVER_LABEL успешно добавлен."
            echo ""
        else
            echo ""
            show_bold "✅ Добавление серверов завершено."
            echo ""
            break
        fi
    done

    show_bold "✅ Файл конфигурации $prometheus_config_path успешно обновлен."
    echo ""

     # Перезапуск службы Prometheus
    systemctl restart prometheus
    if [[ $? -eq 0 ]]; then
        show_bold "✅ Служба Prometheus успешно перезапущена."
    else
        show_war "❌ Ошибка при перезапуске службы Prometheus."
    fi
}

remove_server() {
    # Путь к файлу конфигурации Prometheus
    local prometheus_config_path="/etc/prometheus/prometheus.yml"

    # Проверяем, существует ли файл
    if [[ ! -f "$prometheus_config_path" ]]; then
        show_war "❌ Файл $prometheus_config_path не найден. Убедитесь, что Prometheus установлен и файл существует."
        return 1
    fi

    # Выводим список серверов для удаления
    echo -e "\n${TERRACOTTA}${BOLD}Список добавленных серверов:${NC}"
    SERVERS=$(awk '/- targets:/ {getline; print}' "$prometheus_config_path" | sed -n 's/.*targets: \["\(.*\):9100"\]/\1/p')
    SERVER_NAMES=$(awk '/- targets:/ {getline; getline; if ($1 ~ /labels:/) print $0}' "$prometheus_config_path" | sed -n 's/.*label: \"\(.*\)\".*/\1/p')

    if [[ -z "$SERVERS" ]]; then
        echo "❌ Серверы не найдены в конфигурационном файле."
        return 1
    fi

    echo -e "${TERRACOTTA}${BOLD}  IP адреса и имена серверов:${NC}"
    paste <(echo "$SERVERS") <(echo "$SERVER_NAMES" | sed 's/^/ - Имя: /') | while read -r line; do
        echo "  - $line"
    done

    # Удаление сервера
    while true; do
        if confirm "Хочешь удалить сервер из мониторинга?"; then
            echo -en "${TERRACOTTA}${BOLD}Введи IP адрес сервера, который нужно удалить: ${NC}"
            read OLD_SERVER_IP

            # Проверка на пустой ввод
            if [[ -z "$OLD_SERVER_IP" ]]; then
                show_war "❌ Пустой ввод. Попробуй снова."
                continue
            fi

            # Проверка наличия сервера в конфигурации
            if ! echo "$SERVERS" | grep -q "$OLD_SERVER_IP"; then
                show_war "❌ Сервер с IP $OLD_SERVER_IP не найден в конфигурационном файле. Попробуй снова."
                continue
            fi

            # Удаление сервера
            local temp_file="${prometheus_config_path}.tmp"
            awk -v ip="$OLD_SERVER_IP" '\
                BEGIN {skip=0}
                /- targets:/ {
                    if ($0 ~ ip ":9100") {
                        skip=1
                        next
                    }
                }
                /labels:/ {
                    if (skip) {
                        skip=0
                        next
                    }
                }
                {if (!skip) print $0}
            ' "$prometheus_config_path" > "$temp_file"

            mv "$temp_file" "$prometheus_config_path"
            show_bold "✅ Сервер $OLD_SERVER_IP успешно удалён из конфигурационного файла."
        else
            show_bold "✅ Удаление серверов завершено."
            break
        fi
    done

    # Перезапуск Prometheus
    systemctl restart prometheus
    if [[ $? -eq 0 ]]; then
        show_bold "✅ Служба Prometheus успешно перезапущена."
    else
        show_war "❌ Ошибка при перезапуске службы Prometheus."
    fi
}



check_status() {
    # Список сервисов для проверки
    declare -A services=(
        ["Prometheus"]="prometheus"
        ["Node Exporter"]="node_exporter"
        ["Grafana"]="grafana-server"
    )

    show "Проверка статуса сервисов..."
    for service_name in "${!services[@]}"; do
        if systemctl is-active --quiet "${services[$service_name]}"; then
            show_bold "✅ $service_name успешно работает."
            echo ""
        else
            show_war "❌ $service_name не запущен. Проверьте конфигурацию."

            # Попытка запустить сервис, если он не работает
            show "⚠️ Попытка запустить $service_name..."
            systemctl start "${services[$service_name]}"
            if systemctl is-active --quiet "${services[$service_name]}"; then
                show_bold "✅ $service_name успешно запущен после исправления."
                echo ""
            else
                show_war "❌ Не удалось запустить $service_name. Проверьте журнал с помощью команды: journalctl -u ${services[$service_name]}"
            fi
        fi
    done
}

delete_monitoring() {
    # Удаление службы Prometheus
    if systemctl is-active --quiet prometheus; then
        show "Остановка службы Prometheus..."
        systemctl stop prometheus || { show_war "❌ Ошибка: Не удалось остановить Prometheus."; }
    fi
    show "Удаление службы Prometheus..."
    systemctl disable prometheus > /dev/null 2>&1
    rm -f /etc/systemd/system/prometheus.service
    rm -rf /usr/bin/prometheus /etc/prometheus
    show_bold "✅ Prometheus удалён."
    echo ""

    # Удаление службы Node Exporter
    if systemctl is-active --quiet node_exporter; then
        show "Остановка службы Node Exporter..."
        systemctl stop node_exporter || { show_war "❌ Ошибка: Не удалось остановить Node Exporter."; }
    fi
    show "Удаление службы Node Exporter..."
    systemctl disable node_exporter > /dev/null 2>&1
    rm -f /etc/systemd/system/node_exporter.service
    rm -f /usr/bin/node_exporter
    show_bold "✅ Node Exporter удалён."
    echo ""

    # Удаление Grafana
    if systemctl is-active --quiet grafana-server; then
        show "Остановка службы Grafana..."
        systemctl stop grafana-server || { show_war "❌ Ошибка: Не удалось остановить Grafana."; }
    fi
    show "Удаление службы Grafana..."
    systemctl disable grafana-server > /dev/null 2>&1
    rm -f /etc/systemd/system/grafana-server.service
    rm -rf /etc/grafana /var/lib/grafana /var/log/grafana /usr/sbin/grafana-server
    show_bold "✅ Grafana удалена."
    echo ""

    # Удаление остатков
    show "Очистка временных файлов..."
    rm -rf /tmp/prometheus* /tmp/node_exporter*
    apt-get remove --purge -y grafana || { show_war "❌ Ошибка: Не удалось удалить пакет Grafana."; }
    apt-get autoremove -y

    # Перезагрузка systemctl
    show "Обновление конфигурации systemctl..."
    systemctl daemon-reload
    systemctl reset-failed

    show_bold "✅ Все компоненты успешно удалены."
    echo ""
}

get_grafana_port() {
    local config_file="/etc/grafana/grafana.ini"
    if [[ -f "$config_file" ]]; then
        # Ищем строку с портом Grafana
        GRAFANA_PORT=$(grep -Po '^http_port = \K\d+' "$config_file")
        if [[ -z "$GRAFANA_PORT" ]]; then
            show_war "⚠️ Порт Grafana не найден в $config_file."
        fi
    else
        show_war "❌ Файл конфигурации Grafana $config_file не найден."
    fi
}

show_link() {
    LOGIN="admin"
    PASSWORD="admin"
    MAX_WIDTH=70 # Задаем фиксированную ширину рамки
    # Сообщения для вывода
    LINE1="${TERRACOTTA}${BOLD} Мониторинг доступен по ссылке: ${NC}${LIGHT_BLUE} http://$SERVER_IP:$GRAFANA_PORT/${NC}"
    LINE2="${TERRACOTTA}${BOLD} Login: ${NC}${LIGHT_BLUE}$LOGIN  ${NC} ${TERRACOTTA}${BOLD}Password: ${NC}${LIGHT_BLUE}$PASSWORD${NC}"
   
    # Удаление ANSI-кодов для расчета длины строки
    LINE1_STRIPPED=$(echo -e "$LINE1" | sed 's/\x1b\[[0-9;]*m//g')
    LINE2_STRIPPED=$(echo -e "$LINE2" | sed 's/\x1b\[[0-9;]*m//g')

    # Рассчитываем длину строк без ANSI-кодов
    LINE1_LENGTH=${#LINE1_STRIPPED}
    LINE2_LENGTH=${#LINE2_STRIPPED}
    
    # Добавляем пробелы для выравнивания
    LINE1_PADDING=$((MAX_WIDTH - 4 - LINE1_LENGTH))
    LINE2_PADDING=$((MAX_WIDTH - 4 - LINE2_LENGTH))

    LINE1_PADDED=$(printf "${TERRACOTTA}║ ${NC}%s%*s${TERRACOTTA} ║${NC}" "$(echo -e "$LINE1")" "$LINE1_PADDING" "")
    LINE2_PADDED=$(printf "${TERRACOTTA}║ ${NC}%s%*s${TERRACOTTA} ║${NC}" "$(echo -e "$LINE2")" "$LINE2_PADDING" "")

    # Верхняя и нижняя границы
    BORDER_TOP="${TERRACOTTA}╔$(printf '═%.0s' $(seq 1 $((MAX_WIDTH - 2))))╗${NC}"
    BORDER_BOTTOM="${TERRACOTTA}╚$(printf '═%.0s' $(seq 1 $((MAX_WIDTH - 2))))╝${NC}"

    # Вывод рамки
    echo -e "$BORDER_TOP"
    echo -e "$LINE1_PADDED"
    echo -e "$LINE2_PADDED"
    echo -e "$BORDER_BOTTOM"

    
    #show_bold "╔═══════════════════════════════════════════════════════════════════╗"
    #echo ""
    #echo -en "${TERRACOTTA}${BOLD}║ 💡 Мониторинг доступен по ссылке: ${NC}${LIGHT_BLUE} http://$SERVER_IP:$GRAFANA_PORT/${NC}${TERRACOTTA}${BOLD}     ║${NC}\n"
    #echo -en "${TERRACOTTA}${BOLD}║ Login: ${NC}${LIGHT_BLUE}admin  ${NC} ${TERRACOTTA}${BOLD}Password: ${NC}${LIGHT_BLUE}admin${NC}${TERRACOTTA}${BOLD}                                    ║${NC}\n"
    #show_bold '╚═══════════════════════════════════════════════════════════════════╝'
    #echo ""
}
################################################################################################

menu() {
    # Проверка аргумента меню
    if [[ -z "$1" ]]; then
        show_war "⚠️ Пожалуйста, выберите пункт меню."
        return
    fi

    case $1 in
        1)  
            # Установка на ведущий сервер
            prometheus_install
            node_exporter_install
            grafana_install
            add_dashboard
            configure_prometheus
            add_server
            check_status
            show_link
            ;;
        2)  
            # Установка на ведомый сервер
             node_exporter_install
            ;;
        3)  
            # Добавление ведомых серверов
            add_server
            check_status
            get_grafana_port
            show_link
            ;;
        4)
            remove_server
            check_status
            get_grafana_port
            show_link
            ;;
        5)  
            # Просмотр статуса служб
            check_status
            get_grafana_port
            show_link
            ;;
        
        9)  
            # Удаление ноды с подтверждением
            delete_monitoring
            ;;
        0)  
            # Выход с финальным сообщением
            final_message
            exit 0
            ;;
        *)  
            # Обработка неверного ввода
            show_war "⚠️ Неверный выбор, попробуйте снова."
            ;;
    esac
}
            

while true; do
    show_menu
    show_bold 'Ваш выбор: '
    read choice
    menu "$choice"
done
