#!/bin/bash

INPUT_DIR="."
OUTPUT_DIR="compressed"
BITRATE="64k"
BITRATE_NUM=64000

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
GRAY='\033[0;90m'
BOLD='\033[1m'
RESET='\033[0m'
AGL="ꕤ"

spinner() {
  local pid=$1
  local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
  local i=0
  while kill -0 "$pid" 2>/dev/null; do
    printf "\r  ${CYAN}%s${RESET} Processando..." "${frames[$i]}"
    i=$(( (i + 1) % ${#frames[@]} ))
    sleep 0.08
  done
}

progress_bar() {
  local current=$1
  local total=$2
  local width=40
  local filled=$(( current * width / total ))
  local empty=$(( width - filled ))
  local bar=""
  for ((i=0; i<filled; i++)); do bar+="█"; done
  for ((i=0; i<empty; i++)); do bar+="░"; done
  printf "\r  [${GREEN}%s${RESET}] %d/%d" "$bar" "$current" "$total"
}

get_bitrate() {
  ffprobe -v error \
    -select_streams a:0 \
    -show_entries stream=bit_rate \
    -of default=noprint_wrappers=1:nokey=1 \
    "$1" 2>/dev/null
}

echo ""
printf "${CYAN}${BOLD}  Compressor de mp3 %s${RESET}\n" "$AGL"
echo ""

mapfile -t MP3_FILES < <(find "$INPUT_DIR" -maxdepth 1 -name "*.mp3" | sort)
total=${#MP3_FILES[@]}

if [ "$total" -eq 0 ]; then
  echo -e "  ${RED}Nenhum arquivo .mp3 encontrado na pasta atual.${RESET}"
  exit 1
fi

echo -e "  ${BOLD}O que deseja fazer?${RESET}"
echo ""
echo -e "  ${CYAN}1${RESET} - Otimizar bitrate ${YELLOW}(reduz tamanho, mantém duração)${RESET}"
echo -e "  ${CYAN}2${RESET} - Reduzir duração  ${YELLOW}(corta cada arquivo em N minutos)${RESET}"
echo -e "  ${CYAN}3${RESET} - Ambos            ${YELLOW}(reduz duração + otimiza bitrate)${RESET}"
echo ""
printf "  Escolha [1/2/3]: "
read -r CHOICE

DURATION_SECS=0

if [[ "$CHOICE" == "2" || "$CHOICE" == "3" ]]; then
  echo ""
  printf "  Duração em minutos por arquivo: "
  read -r MINUTES
  if ! [[ "$MINUTES" =~ ^[0-9]+$ ]] || [ "$MINUTES" -le 0 ]; then
    echo -e "  ${RED}Valor inválido. Use um número inteiro positivo.${RESET}"
    exit 1
  fi
  DURATION_SECS=$(( MINUTES * 60 ))
fi

if [[ "$CHOICE" != "1" && "$CHOICE" != "2" && "$CHOICE" != "3" ]]; then
  echo -e "  ${RED}Opção inválida.${RESET}"
  exit 1
fi

echo ""
echo -e "${CYAN}  ─────────────────────────────────────────${RESET}"
if [[ "$CHOICE" == "1" || "$CHOICE" == "3" ]]; then
  printf "  Bitrate:   ${YELLOW}%s${RESET}\n" "$BITRATE"
fi
printf "  Arquivos:  ${YELLOW}%s${RESET}\n" "$total"
printf "  Saída:     ${YELLOW}%s/${RESET}\n" "$OUTPUT_DIR"
if [ "$DURATION_SECS" -gt 0 ]; then
  printf "  Duração:   ${YELLOW}%s minuto(s) por arquivo${RESET}\n" "$MINUTES"
fi
echo -e "${CYAN}  ─────────────────────────────────────────${RESET}"
echo ""

mkdir -p "$OUTPUT_DIR"

current=0
skipped=0
total_original=0
total_compressed=0

for f in "${MP3_FILES[@]}"; do
  [ -f "$f" ] || continue
  filename=$(basename "$f")
  output="$OUTPUT_DIR/$filename"
  current=$(( current + 1 ))

  APPLY_BITRATE=true

  if [[ "$CHOICE" == "1" || "$CHOICE" == "3" ]]; then
    current_br=$(get_bitrate "$f")
    if [[ -n "$current_br" && "$current_br" -le "$BITRATE_NUM" ]]; then
      APPLY_BITRATE=false
      if [[ "$CHOICE" == "1" ]]; then
        printf "  ${GRAY}⊘ %-28s já está em %dk - pulado${RESET}\n" "$filename" $(( current_br / 1000 ))
        echo ""
        progress_bar "$current" "$total"
        echo ""
        skipped=$(( skipped + 1 ))
        continue
      fi
    fi
  fi

  printf "  ${CYAN}%-30s${RESET}\n" "$filename"

  FFMPEG_ARGS=(-i "$f")

  if [ "$DURATION_SECS" -gt 0 ]; then
    FFMPEG_ARGS+=(-t "$DURATION_SECS")
  fi

  if [[ "$APPLY_BITRATE" == true ]]; then
    FFMPEG_ARGS+=(-b:a "$BITRATE")
  fi

  FFMPEG_ARGS+=(-map_metadata 0 -id3v2_version 3 -y "$output" -loglevel error)

  ffmpeg "${FFMPEG_ARGS[@]}" &
  ffmpeg_pid=$!
  spinner "$ffmpeg_pid"
  wait "$ffmpeg_pid"

  orig=$(du -k "$f" | cut -f1)
  comp=$(du -k "$output" | cut -f1)
  total_original=$(( total_original + orig ))
  total_compressed=$(( total_compressed + comp ))
  orig_h=$(du -sh "$f" | cut -f1)
  comp_h=$(du -sh "$output" | cut -f1)

  if [ "$orig" -gt 0 ]; then
    saved=$(( 100 - comp * 100 / orig ))
  else
    saved=0
  fi

  note=""
  [[ "$APPLY_BITRATE" == false ]] && note=" ${GRAY}(bitrate já otimizado)${RESET}"

  printf "\r  ${GREEN}✓${RESET} %-28s ${YELLOW}%s → %s${RESET} (-%d%%)%b\n" \
    "$filename" "$orig_h" "$comp_h" "$saved" "$note"
  echo ""
  progress_bar "$current" "$total"
  echo ""
done

echo ""

if [ "$total_original" -gt 0 ]; then
  total_saved=$(( 100 - total_compressed * 100 / total_original ))
else
  total_saved=0
fi

orig_total_h=$(( total_original / 1024 ))
comp_total_h=$(( total_compressed / 1024 ))

echo -e "${CYAN}  ─────────────────────────────────────────${RESET}"
echo -e "  Total original:    ${YELLOW}${orig_total_h} MB${RESET}"
echo -e "  Total comprimido:  ${GREEN}${comp_total_h} MB${RESET}"
if [ "$total_saved" -gt 0 ]; then
  echo -e "  Economia total:    ${GREEN}-${total_saved}%${RESET}"
fi
if [ "$skipped" -gt 0 ]; then
  echo -e "  Pulados:           ${GRAY}${skipped} (já otimizados)${RESET}"
fi
echo -e "${CYAN}  ─────────────────────────────────────────${RESET}"
echo -e "  Arquivos salvos em: ${YELLOW}$OUTPUT_DIR/${RESET}"
echo ""