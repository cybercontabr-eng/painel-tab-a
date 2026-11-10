"""Ajusta o AndroidManifest gerado pelo `flutter create`."""
import pathlib
import re

p = pathlib.Path("android/app/src/main/AndroidManifest.xml")
s = p.read_text(encoding="utf-8")

perm = '<uses-permission android:name="android.permission.INTERNET"/>'
if perm not in s:
    s = s.replace("<application", perm + "\n    <application", 1)

s = re.sub(r'android:label="[^"]*"', 'android:label="Painel Tab"', s, count=1)

p.write_text(s, encoding="utf-8")
print("AndroidManifest ajustado.")
