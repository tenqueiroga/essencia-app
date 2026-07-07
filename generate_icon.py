#!/usr/bin/env python3
"""Generate Olfato app icons from the brand source icon."""
from PIL import Image
import os

# Source icon (1024px from brand kit)
source_path = os.path.join("..", "novas logos", "05_Icones", "olfato_icone_transparente_1024.png")
if not os.path.exists(source_path):
    source_path = os.path.join("..", "novas logos", "05_Icones", "olfato_icone_transparente_1024.png")

img = Image.open(source_path)
print(f"Source: {source_path} ({img.size[0]}x{img.size[1]})")

# ─── Android mipmap icons ─────────────────────────────────────────────────────
android_sizes = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
}

base_path = os.path.join('android', 'app', 'src', 'main', 'res')

for folder, size in android_sizes.items():
    dir_path = os.path.join(base_path, folder)
    os.makedirs(dir_path, exist_ok=True)

    resized = img.resize((size, size), Image.LANCZOS)
    resized.save(os.path.join(dir_path, 'ic_launcher.png'), 'PNG')
    resized.save(os.path.join(dir_path, 'ic_launcher_foreground.png'), 'PNG')
    print(f'  ✓ {folder}: {size}x{size}')

# Play Store icon (512px)
store_icon = img.resize((512, 512), Image.LANCZOS)
store_icon.save(os.path.join(base_path, 'playstore-icon.png'), 'PNG')
print('  ✓ Play Store icon: 512x512')

# ─── iOS icons ────────────────────────────────────────────────────────────────
ios_sizes = {
    "Icon-App-20x20@1x.png": 20,
    "Icon-App-20x20@2x.png": 40,
    "Icon-App-20x20@3x.png": 60,
    "Icon-App-29x29@1x.png": 29,
    "Icon-App-29x29@2x.png": 58,
    "Icon-App-29x29@3x.png": 87,
    "Icon-App-40x40@1x.png": 40,
    "Icon-App-40x40@2x.png": 80,
    "Icon-App-40x40@3x.png": 120,
    "Icon-App-60x60@2x.png": 120,
    "Icon-App-60x60@3x.png": 180,
    "Icon-App-76x76@1x.png": 76,
    "Icon-App-76x76@2x.png": 152,
    "Icon-App-83.5x83.5@2x.png": 167,
    "Icon-App-1024x1024@1x.png": 1024,
}

ios_path = os.path.join('ios', 'Runner', 'Assets.xcassets', 'AppIcon.appiconset')

for filename, size in ios_sizes.items():
    resized = img.resize((size, size), Image.LANCZOS)
    resized.save(os.path.join(ios_path, filename), 'PNG')
    print(f'  ✓ iOS: {filename} ({size}x{size})')

# ─── Web icons ────────────────────────────────────────────────────────────────
web_path = 'web'
web_icons_path = os.path.join(web_path, 'icons')

favicon = img.resize((32, 32), Image.LANCZOS)
favicon.save(os.path.join(web_path, 'favicon.png'), 'PNG')
print('  ✓ Web favicon: 32x32')

for name, size in [('Icon-192.png', 192), ('Icon-512.png', 512),
                   ('Icon-maskable-192.png', 192), ('Icon-maskable-512.png', 512)]:
    resized = img.resize((size, size), Image.LANCZOS)
    resized.save(os.path.join(web_icons_path, name), 'PNG')
    print(f'  ✓ Web: {name} ({size}x{size})')

print('\nAll icons generated!')
