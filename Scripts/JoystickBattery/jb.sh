# upower -d | grep ps-controller > verifica manualmente status
# testado no controle de ps4

#!/bin/bash

STATE_FILE="/tmp/dualsense-bat-usb-iface"

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
      echo "controle já estava inativo"
      exit 0
    fi
    echo "$USB_IFACE" | sudo tee "$STATE_FILE" > /dev/null
    echo -n "$USB_IFACE" | sudo tee /sys/bus/usb/drivers/usbhid/unbind > /dev/null
    sudo systemctl restart upower
    pkill -e noctalia 2>/dev/null || true
    echo "status: off"
    echo "upower reiniciado"
    ;;
  --on)
    if [ -d "$BATTERY_PATH" ]; then
      echo "controle já estava ativo"
      exit 0
    fi
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
    echo "upower reiniciado"
    ;;
  *)
    if [ -d "$BATTERY_PATH" ]; then
      echo "status: on"
    else
      echo "status: off"
    fi
    ;;
esac
