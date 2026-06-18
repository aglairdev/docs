## Por que isso? 

Estava com problema de bateria viciada no controle PS4 conectado via USB no desktop, e o sistema ficava alertando bateria fraca constantemente mesmo o controle estando alimentado pelo cabo.

A solução foi desvincular a interface USB responsável pelo reporte da bateria, removendo o dispositivo de bateria do sistema sem afetar o funcionamento do controle.

Testado apenas no DualShock 4 (PS4).

## Aplicando manualmente 

Lista os dispositivos de energia:

```bash
ls /sys/class/power_supply/
```

Procura por `ps-controller-battery-XXXXXXXXXXXX`.
> ps4

Descobre a interface USB responsável pela bateria:

```bash
readlink -f /sys/class/power_supply/ps-controller-battery-XXXXXXXXXXXX
```

A saída contem um caminho como `/sys/devices/.../1-6:1.3/...` onde `1-6:1.3` e a interface.

Desativa as notificações:

```bash
echo -n "1-6:1.3" | sudo tee /sys/bus/usb/drivers/usbhid/unbind
```

Reativa as notificações:

```bash
echo -n "1-6:1.3" | sudo tee /sys/bus/usb/drivers/usbhid/bind
```

Verifica o estado:

```bash
upower -d | grep ps-controller
```

> Se não aparecer nada, está desativado

## Usando o script

O script `jb.sh` automatiza os passos manuais:

- Detecta a interface USB do controle automaticamente (ps4)
- Salva o ID da interface para reativar depois
- Reinicia o `upower` e o daemon de notificação (Noctalia) para aplicar as mudancas imediatamente
- Impede erros quando já está no estado desejado
- Persiste apos reboot: cria uma regra `udev` que desativa automaticamente ao conectar o controle

```bash
./jb.sh --off    # desliga notificações de bateria
./jb.sh --on     # liga notificações de bateria
./jb.sh          # mostra estado atual
```

Isso e útil porque o ID da interface USB muda dependendo da porta onde o controle está conectado. O script descobre isso automaticamente, sem necessidade de verificar manualmente toda vez.