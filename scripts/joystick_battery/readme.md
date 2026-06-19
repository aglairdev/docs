# [![JOYSTICK__BATTERY](https://img.shields.io/badge/JOYSTICK__BATTERY-E25252?style=for-the-badge)](https://github.com/aglairdev/Docs/tree/main/scripts/joystick_battery)

## Que isso?

Desativa o alerta de bateria fraca do controle PS4 (DualShock 4) conectado via USB.

![Shell](https://img.shields.io/badge/Shell-121011?style=flat-square&logo=gnu-bash&logoColor=white)

Quê?

> [!NOTE]
> Resolve um problema pessoal de controle PS4 com bateria viciada: o sistema fica avisando bateria fraca o tempo todo, mesmo o controle estando alimentado pelo cabo USB.

- Detecta automaticamente a interface USB responsável pelo reporte de bateria
- Desvincula essa interface, removendo o dispositivo de bateria do sistema
- Salva o ID da interface pra poder reverter depois
- Reinicia `upower` e o Noctalia pra aplicar a mudança na hora
- Cria uma regra `udev` pra manter o efeito persistente após reboot
- Evita erro se já estiver no estado desejado (ligado/desligado)

## Compatibilidade
- **Testado**: DualShock 4 (PS4) via USB

## Uso
```bash
./jb.sh --off    # desliga notificações de bateria (persistente após reboot)
./jb.sh --on     # liga notificações de bateria
./jb.sh          # mostra estado atual (status + se está persistente)
```

> [!TIP]
> Outra forma de verificar status: `upower -d | grep ps-controller`  se não aparecer nada, está desativado.

<details>

<summary>Manualmente</summary>

<br>

Lista os dispositivos de energia:
```bash
ls /sys/class/power_supply/
```
Procura por `ps-controller-battery-XXXXXXXXXXXX`.

Descobre a interface USB responsável pela bateria:
```bash
readlink -f /sys/class/power_supply/ps-controller-battery-XXXXXXXXXXXX
```
A saída contém um caminho como `/sys/devices/.../1-6:1.3/...`, onde `1-6:1.3` é a interface.

Desativa as notificações:
```bash
echo -n "1-6:1.3" | sudo tee /sys/bus/usb/drivers/usbhid/unbind
```
Reativa as notificações:
```bash
echo -n "1-6:1.3" | sudo tee /sys/bus/usb/drivers/usbhid/bind
```
</details>

<p align="center">ꕤ AGL</p>
