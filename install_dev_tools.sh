#!/bin/bash

# ============================================================
# install_dev_tools.sh
# Автоматичне встановлення DevOps-інструментів:
# Docker, Docker Compose, Python 3, Django
# Підтримувані системи: Ubuntu / Debian
# ============================================================

set -euo pipefail

# ---------- Кольори для виводу ----------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ---------- Допоміжні функції ----------
info()    { echo -e "${BLUE}[INFO]${NC}  $1"; }
success() { echo -e "${GREEN}[OK]${NC}    $1"; }
warning() { echo -e "${YELLOW}[SKIP]${NC}  $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Перевірка прав root
check_root() {
    if [[ "$EUID" -ne 0 ]]; then
        error "Запустіть скрипт із правами root: sudo ./install_dev_tools.sh"
    fi
}

# Оновлення індексу пакетів
update_packages() {
    info "Оновлення списку пакетів..."
    apt-get update -qq
    success "Список пакетів оновлено."
}

# ---------- Docker ----------
install_docker() {
    if command -v docker &>/dev/null; then
        warning "Docker вже встановлено: $(docker --version)"
        return
    fi

    info "Встановлення Docker..."
    apt-get install -y -qq \
        ca-certificates \
        curl \
        gnupg \
        lsb-release

    # Додавання офіційного GPG-ключа Docker
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
        | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    # Додавання репозиторію Docker
    echo \
        "deb [arch=$(dpkg --print-architecture) \
signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu \
$(lsb_release -cs) stable" \
        | tee /etc/apt/sources.list.d/docker.list > /dev/null

    apt-get update -qq
    apt-get install -y -qq docker-ce docker-ce-cli containerd.io

    systemctl enable --now docker
    success "Docker встановлено: $(docker --version)"
}

# ---------- Docker Compose ----------
install_docker_compose() {
    if command -v docker-compose &>/dev/null; then
        warning "Docker Compose вже встановлено: $(docker-compose --version)"
        return
    fi

    # Перевірка плагіна (docker compose v2)
    if docker compose version &>/dev/null 2>&1; then
        warning "Docker Compose v2 (плагін) вже доступний: $(docker compose version)"
        return
    fi

    info "Встановлення Docker Compose плагіна..."
    apt-get install -y -qq docker-compose-plugin
    success "Docker Compose встановлено: $(docker compose version)"
}

# ---------- Python 3 ----------
install_python() {
    local min_version="3.9"

    if command -v python3 &>/dev/null; then
        local current_version
        current_version=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')

        # Порівняння версій через sort -V
        if [[ "$(printf '%s\n' "$min_version" "$current_version" | sort -V | head -n1)" == "$min_version" ]]; then
            warning "Python вже встановлено: $(python3 --version)"
            return
        else
            info "Знайдено Python $current_version (потрібно >= $min_version). Оновлення..."
        fi
    fi

    info "Встановлення Python 3.9+..."
    apt-get install -y -qq python3 python3-pip python3-venv
    success "Python встановлено: $(python3 --version)"
}

# ---------- Django ----------
install_django() {
    if python3 -c "import django" &>/dev/null; then
        local django_version
        django_version=$(python3 -c "import django; print(django.__version__)")
        warning "Django вже встановлено: версія $django_version"
        return
    fi

    info "Встановлення Django через pip..."

    # Переконуємось, що pip актуальний
    python3 -m pip install --upgrade pip -q

    # На нових системах (Ubuntu 23.04+) pip захищений PEP 668 —
    # використовуємо --break-system-packages або venv
    if python3 -m pip install django -q 2>/dev/null; then
        success "Django встановлено: $(python3 -c 'import django; print(django.__version__)')"
    else
        info "Стандартна установка не вдалася — пробуємо з --break-system-packages..."
        python3 -m pip install django -q --break-system-packages
        success "Django встановлено: $(python3 -c 'import django; print(django.__version__)')"
    fi
}

# ---------- Підсумок ----------
print_summary() {
    echo ""
    echo -e "${GREEN}============================================${NC}"
    echo -e "${GREEN}       Встановлення завершено успішно!      ${NC}"
    echo -e "${GREEN}============================================${NC}"
    echo -e "  Docker:         $(docker --version 2>/dev/null || echo 'не знайдено')"
    echo -e "  Docker Compose: $(docker compose version 2>/dev/null || docker-compose --version 2>/dev/null || echo 'не знайдено')"
    echo -e "  Python:         $(python3 --version 2>/dev/null || echo 'не знайдено')"
    echo -e "  Django:         $(python3 -c 'import django; print(django.__version__)' 2>/dev/null || echo 'не знайдено')"
    echo -e "${GREEN}============================================${NC}"
}

# ---------- Головна функція ----------
main() {
    check_root
    update_packages
    install_docker
    install_docker_compose
    install_python
    install_django
    print_summary
}

main "$@"
