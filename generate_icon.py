#!/usr/bin/env python3
"""Generate ESSÊNCIA app icon - gradient circle with E letter"""
from PIL import Image, ImageDraw, ImageFont
import os

def create_icon(size):
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Background circle with gradient effect (dark obsidian)
    # Draw filled circle
    margin = int(size * 0.02)
    draw.ellipse([margin, margin, size - margin, size - margin], fill='#0C0A0A')
    
    # Draw gradient ring (rosé to gold)
    # Outer ring
    ring_width = int(size * 0.06)
    for i in range(ring_width):
        alpha = int(255 * (1 - i / ring_width))
        # Blend from rosé (#C4727A) to gold (#B8956A)
        r = int(196 + (184 - 196) * (i / ring_width))
        g = int(114 + (149 - 114) * (i / ring_width))
        b = int(122 + (106 - 122) * (i / ring_width))
        draw.ellipse(
            [margin + i, margin + i, size - margin - i, size - margin - i],
            outline=(r, g, b, alpha),
            width=1
        )
    
    # Draw inner filled circle (obsidian background)
    inner_margin = margin + ring_width + int(size * 0.01)
    draw.ellipse([inner_margin, inner_margin, size - inner_margin, size - inner_margin], 
                 fill='#0C0A0A')
    
    # Draw the E letter
    font_size = int(size * 0.45)
    try:
        # Try system fonts
        for font_path in [
            '/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf',
            '/usr/share/fonts/truetype/liberation/LiberationSerif-Bold.ttf',
            '/usr/share/fonts/truetype/noto/NotoSerif-Bold.ttf',
        ]:
            if os.path.exists(font_path):
                font = ImageFont.truetype(font_path, font_size)
                break
        else:
            font = ImageFont.load_default()
    except:
        font = ImageFont.load_default()
    
    # Center the E
    text = "E"
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    x = (size - text_width) / 2 - bbox[0]
    y = (size - text_height) / 2 - bbox[1]
    
    # Draw E with rosé/gold gradient look
    draw.text((x, y), text, fill='#C4727A', font=font)
    
    return img

# Generate all required Android sizes
sizes = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
}

base_path = 'android/app/src/main/res'

for folder, size in sizes.items():
    dir_path = f'{base_path}/{folder}'
    os.makedirs(dir_path, exist_ok=True)
    
    icon = create_icon(size)
    icon.save(f'{dir_path}/ic_launcher.png')
    
    # Also save foreground for adaptive icons
    icon.save(f'{dir_path}/ic_launcher_foreground.png')
    
    print(f'  ✓ {folder}: {size}x{size}')

# Generate a 1024x1024 for Play Store
store_icon = create_icon(1024)
store_icon.save(f'{base_path}/playstore-icon.png')
print('  ✓ Play Store icon: 1024x1024')

print('\nDone!')
