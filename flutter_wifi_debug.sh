#!/bin/bash
# ====================================================
#  Flutter Wireless Debug Script (Auto IP Detection)
#  Connects Android phone to Flutter via Wi-Fi
#  Author: Micheal Noble (Academic Nightingale)
# ====================================================

# Step 1 — Restart ADB in TCP/IP mode on port 5555
echo "🔁 Restarting ADB in TCP mode (port 5555)..."
adb tcpip 5555
sleep 2

# Step 2 — Detect phone's current IP address
echo "🔍 Detecting phone IP..."
PHONE_IP=$(adb shell ip route | awk '{print $9}')

if [[ -z "$PHONE_IP" ]]; then
  echo "❌ Could not detect phone IP. Make sure the phone is connected via USB and Wi-Fi is ON."
  exit 1
fi

echo "📡 Phone IP detected: $PHONE_IP"

# Step 3 — Connect over Wi-Fi
echo "🔗 Connecting to $PHONE_IP:5555 ..."
adb connect "$PHONE_IP:5555"

# Step 4 — List connected devices
echo "📱 Connected devices:"
flutter devices

# Step 5 — Optional: Run your Flutter app
read -p "🚀 Do you want to run Flutter now? (y/n): " choice
if [[ "$choice" == "y" ]]; then
  flutter run
else
  echo "✅ Wireless ADB setup complete. You can now use 'flutter run'."
fi

