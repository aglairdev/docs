# upower -d | grep ps-controller > verifica manualmente status
# testado no controle de ps4

#!/bin/bash

STATE_FILE="/tmp/dualsense-bat-usb-iface"
RULE_FILE="/etc/udev/rules.d/99-hide-ps-battery.rules"
HELPER_FILE="/usr/local/bin/jb-udev-helper"

# procura o dispositivo dinamicamente
BATTERY_PATH=""
USB_IFACE=""
for d in /sys/class/power_supply/ps-controller-battery-*; do
  if [ -d "$d" ]; then
    BATTERY_PATH="$d"
    USB_IFACE=$(readlink -f "$d" | sed -n 's|.*/\([^/]*:[0-9]*\.[0-9]*\)/.*|\1|p')
    break
  fi
done

case "$1" in
  --off)
    if [ ! -d "$BATTERY_PATH" ]; then
      echo "controle ja estava inativo"
      echo "persistente: sim"
      exit 0
    fi

    echo "$USB_IFACE" | sudo tee "$STATE_FILE" > /dev/null
    echo -n "$USB_IFACE" | sudo tee /sys/bus/usb/drivers/usbhid/unbind > /dev/null

    sudo tee "$HELPER_FILE" > /dev/null << 'HELPER'
#!/bin/bash
# jb-udev-helper: extrai USB_IFACE do DEVPATH e faz unbind
# chamado pela regra udev com $kernel (ex: ps-controller-battery-XX:XX:XX:XX:XX:XX)
for d in /sys/class/power_supply/"$1"/; do
  [ -d "$d" ] || continue
  USB_IFACE=$(readlink -f "$d" | sed -n 's|.*/\([^/]*:[0-9]*\.[0-9]*\)/.*|\1|p')
  [ -n "$USB_IFACE" ] && echo -n "$USB_IFACE" > /sys/bus/usb/drivers/usbhid/unbind
  break
done
HELPER
    sudo chmod +x "$HELPER_FILE"

    # cria regra udev
    echo 'SUBSYSTEM=="power_supply", KERNEL=="ps-controller-battery-*", RUN+="/usr/local/bin/jb-udev-helper $kernel"' | sudo tee "$RULE_FILE" > /dev/null
    sudo udevadm control --reload-rules

    sudo systemctl restart upower
    pkill -e noctalia 2>/dev/null || true
    echo "status: off"
    echo "persistente: sim"
    ;;

  --on)
    if [ -d "$BATTERY_PATH" ]; then
      echo "controle ja estava ativo"
      echo "persistente: nao"
      exit 0
    fi

    # remove regra udev e helper
    sudo rm -f "$RULE_FILE"
    sudo rm -f "$HELPER_FILE"
    sudo udevadm control --reload-rules

    # bind
    if [ -f "$STATE_FILE" ]; then
      USB_IFACE=$(cat "$STATE_FILE")
      echo -n "$USB_IFACE" | sudo tee /sys/bus/usb/drivers/usbhid/bind > /dev/null
      rm -f "$STATE_FILE"
      sleep 1
    else
      echo "Nao e possivel religar: controle desconectado ou interface desconhecida"
      exit 1
    fi

    sudo systemctl restart upower
    pkill -e noctalia 2>/dev/null || true
    echo "status: on"
    echo "persistente: nao"
    ;;

  *)
    if [ -d "$BATTERY_PATH" ]; then
      echo "status: on"
    else
      echo "status: off"
    fi
    if [ -f "$RULE_FILE" ]; then
      echo "persistente: sim"
    else
      echo "persistente: nao"
    fi
    ;;
esac