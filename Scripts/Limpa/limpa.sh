#!/bin/bash
set -uo pipefail

YELLOW="\e[33m"
GREEN="\e[32m"
RED="\e[31m"
BLUE="\e[34m"
RESET="\e[0m"
CHECK="✓"
CROSS="✗"
AGL="ꕤ"

echo -e "\n${BLUE}${AGL}  SISTEMA DE LIMPEZA ${RESET}"
echo -e "${BLUE}---------------------------${RESET}"

sudo -v || exit 1

while true; do sudo -v; sleep 60; done &
SUDO_PID=$!
trap 'kill "$SUDO_PID" 2>/dev/null' EXIT

run_step() {
    local desc="$1"
    shift
    echo -e "\n${YELLOW}${desc} ...${RESET}"
    if output=$("$@" 2>&1); then
        echo -e "${GREEN}${CHECK} Concluido${RESET}"
    else
        echo -e "${RED}${CROSS} Falha em: ${desc}${RESET}"
        echo -e "${RED}  Erro: ${output%%$'\n'*}${RESET}"
    fi
}

space_before=$(df -k --output=avail / | tail -1)

if command -v pacman >/dev/null; then
    # --- ARCH ---
    if command -v paccache >/dev/null; then
        run_step "Limpando cache de pacotes (paccache)" sudo paccache -r -k 2
        run_step "Removendo cache de apps nao instalados" sudo paccache -ruk 0
    fi

    mapfile -t orphans < <(pacman -Qtdq 2>/dev/null)
    if [ "${#orphans[@]}" -gt 0 ]; then
        echo -e "\n${BLUE}Orfaos detectados. Deseja remover? [s/N]: ${RESET}"
        read -r -t 30 response || response="N"
        [[ "$response" =~ ^([sS][iI][mM]|[sS])$ ]] && sudo pacman -Rns "${orphans[@]}"
    fi

elif command -v apt >/dev/null; then
    # --- DEBIAN ---
    run_step "Limpando pacotes desnecessarios (autoremove)" sudo apt autoremove -y
    run_step "Limpando cache do APT (autoclean)" sudo apt autoclean
    run_step "Limpando arquivos de instalacao antigos (clean)" sudo apt clean
fi

run_step "Limpando logs do systemd" sudo journalctl --vacuum-time=7d

if command -v flatpak >/dev/null; then
    run_step "Limpando residuos do Flatpak" flatpak uninstall --unused -y
fi

if command -v snap >/dev/null; then
    run_step "Limpando versoes antigas de Snaps" sudo bash -c \
        "set -o pipefail; snap list --all | awk '/disabled/{print \$1, \$3}' | while read -r name rev; do snap remove \"\$name\" --revision=\"\$rev\"; done"
fi

run_step "Limpando lixeira" rm -rf ~/.local/share/Trash/
run_step "Limpando cache de thumbnails" rm -rf ~/.cache/thumbnails/

space_after=$(df -k --output=avail / | tail -1)
space_recovered=$((space_after - space_before))

if [ "$space_recovered" -ge 1048576 ]; then
    val=$(awk "BEGIN {printf \"%.2f\", $space_recovered/1024/1024}")
    unit="GB"
elif [ "$space_recovered" -le 0 ]; then
    val="0"
    unit="MB"
else
    val=$(awk "BEGIN {printf \"%.2f\", $space_recovered/1024}")
    unit="MB"
fi

echo -e "\n${GREEN}${CHECK} Limpeza finalizada! Espaco recuperado: ${val} ${unit}${RESET}"
