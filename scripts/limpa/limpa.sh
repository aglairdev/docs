#!/bin/bash
# =============================================================
# Arch Linux / Debian
# © 2026 sistema_de_limpeza ~ AGL ~ github.com/aglairdev
# =============================================================
set -uo pipefail

RED="\e[38;2;226;82;82m"
GREEN="\e[32m"
RESET="\e[0m"
CHECK="✓"
CROSS="✗"

title()  { echo -e "\n${RED}sistema_de_limpeza ꕤ${RESET}\n"; }
header() { echo -e "\n$1"; }
ok()     { echo -e "${GREEN}${CHECK} $1${RESET}"; }
fail()   { echo -e "${RED}${CROSS} Falha em: $1${RESET}"; }
err()    { echo -e "${RED}  Erro: $1${RESET}"; }
info()   { echo -e "→ $1"; }

title

sudo -v || exit 1
while true; do sudo -v; sleep 60; done &
SUDO_PID=$!
trap 'kill "$SUDO_PID" 2>/dev/null' EXIT

run_step() {
    local desc="$1"
    shift
    header "$desc ..."
    if output=$("$@" 2>&1); then
        ok "Concluído"
    else
        fail "$desc"
        err "${output%%$'\n'*}"
    fi
}

space_before=$(df -k --output=avail / | tail -1)

if command -v pacman >/dev/null; then
    # --- ARCH ---
    if command -v paccache >/dev/null; then
        run_step "Limpando cache de pacotes (paccache)" sudo paccache -r -k 2
        run_step "Removendo cache de apps não instalados" sudo paccache -ruk 0
    fi
    mapfile -t orphans < <(pacman -Qtdq 2>/dev/null)
    if [ "${#orphans[@]}" -gt 0 ]; then
        header "Órfãos detectados. Deseja remover? [s/N]: "
        read -r -t 30 response || response="N"
        [[ "$response" =~ ^([sS][iI][mM]|[sS])$ ]] && sudo pacman -Rns "${orphans[@]}"
    fi
elif command -v apt >/dev/null; then
    # --- DEBIAN ---
    run_step "Limpando pacotes desnecessários (autoremove)" sudo apt autoremove -y
    run_step "Limpando cache do APT (autoclean)" sudo apt autoclean
    run_step "Limpando arquivos de instalação antigos (clean)" sudo apt clean
fi

run_step "Limpando logs do systemd" sudo journalctl --vacuum-time=7d

if command -v flatpak >/dev/null; then
    run_step "Limpando resíduos do Flatpak" flatpak uninstall --unused -y
fi

if command -v snap >/dev/null; then
    run_step "Limpando versões antigas de Snaps" sudo bash -c \
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

DIVIDER=""
for i in 1 2 3 4 5; do
    if (( i % 2 == 0 )); then
        DIVIDER+="$(echo -e "\e[38;2;226;82;82m─────\e[0m")"
    else
        DIVIDER+="─────"
    fi
    [ $i -lt 5 ] && DIVIDER+=" "
done

echo ""
echo -e "$DIVIDER"
echo -e "${GREEN}${CHECK} Limpeza finalizada! Espaço recuperado: ${val} ${unit}${RESET}"
echo ""