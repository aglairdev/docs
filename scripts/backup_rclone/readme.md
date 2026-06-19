# [![BACKUP_RCLONE](https://img.shields.io/badge/BACKUP__RCLONE-E25252?style=for-the-badge)](https://github.com/aglairdev/Docs/tree/main/scripts/backup_rclone)

## Que isso?

Script de backup/restore via `rclone`, pensado pra rodar manual ou agendado via crontab.

![Shell](https://img.shields.io/badge/Shell-121011?style=flat-square&logo=gnu-bash&logoColor=white)

Detalhadamente:

- Faz upload de uma pasta local para um remote rclone configurado
- Faz download do remote de volta para uma pasta local
- Valida se o `rclone` está instalado e se o remote existe antes de rodar
- Loga cada execução (sucesso ou erro com motivo) em `~/Documentos/Logs/bkp.txt`
- Sem argumento, roda upload direto ~ ideal pra crontab

## Requisitos

- `rclone` instalado e com pelo menos um remote já configurado (`rclone config`)

## Uso

```bash
bkp              # upload (padrão, ideal pra crontab)
bkp -u           # upload 
bkp -d           # download
bkp -l           # mostra os últimos logs
bkp -h           # ajuda
```
> [!TIP]
> Salve em `~/.local/bin/bkp` e dê permissão de execução (`chmod +x bkp`) pra chamar de qualquer lugar.

<p align="center">ꕤ AGL</p>
