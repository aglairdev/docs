# Limpeza (Arch, Debian) ꕤ

Automatiza a limpeza de caches, logs e pacotes desnecessários para recuperar espaço na partição raiz.

## O que faz:

- Mantém as 2 últimas versões do cache e remove pacotes desinstalados.
- Identifica e remove dependências inúteis.
- Reduz o journalctl para os últimos 7 dias.
- Limpa resíduos de Flatpak e Snap (se instalados).
- Limpa lixeira e thumbnails.
- Exibe o total de espaço recuperado.
