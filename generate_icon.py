#!/usr/bin/env python3
"""
Simple script to generate app icon PNG files from SVG
Requires: pip install cairosvg pillow
"""

try:
    from PIL import Image, ImageDraw, ImageFont
    import os
    
    def generate_icon(size=1024, output_path="assets/app_icon.png"):
        """Generate a simple app icon programmatically"""
        # Create image with blue gradient background
        img = Image.new('RGB', (size, size), color='#4A90E2')
        draw = ImageDraw.Draw(img)
        
        # Draw gradient background (simple approximation)
        for i in range(size):
            ratio = i / size
            r = int(74 + (46 - 74) * ratio)  # 4A to 2E
            g = int(144 + (92 - 144) * ratio)  # 90 to 5C
            b = int(226 + (138 - 226) * ratio)  # E2 to 8A
            draw.rectangle([(0, i), (size, i+1)], fill=(r, g, b))
        
        # Draw shield shape (simplified)
        shield_points = [
            (size * 0.35, size * 0.15),  # Top left
            (size * 0.35, size * 0.45),  # Left middle
            (size * 0.5, size * 0.75),   # Bottom center
            (size * 0.65, size * 0.45),  # Right middle
            (size * 0.65, size * 0.15),  # Top right
        ]
        draw.polygon(shield_points, fill='#E91E63', outline='white', width=int(size/50))
        
        # Draw location pin circle
        pin_center = (size // 2, int(size * 0.45))
        pin_radius = int(size * 0.08)
        draw.ellipse(
            [pin_center[0] - pin_radius, pin_center[1] - pin_radius,
             pin_center[0] + pin_radius, pin_center[1] + pin_radius],
            fill='white', outline='#4A90E2', width=int(size/100)
        )
        inner_radius = int(size * 0.05)
        draw.ellipse(
            [pin_center[0] - inner_radius, pin_center[1] - inner_radius,
             pin_center[0] + inner_radius, pin_center[1] + inner_radius],
            fill='#4A90E2'
        )
        
        # Draw checkmark
        check_points = [
            (int(size * 0.44), int(size * 0.49)),
            (int(size * 0.47), int(size * 0.52)),
            (int(size * 0.56), int(size * 0.43)),
        ]
        draw.line([check_points[0], check_points[1]], fill='white', width=int(size/35))
        draw.line([check_points[1], check_points[2]], fill='white', width=int(size/35))
        
        # Save image
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        img.save(output_path, 'PNG')
        print(f"Generated icon: {output_path} ({size}x{size})")
        return True
    
    def generate_foreground_icon(size=1024, output_path="assets/app_icon_foreground.png"):
        """Generate foreground icon (transparent background)"""
        # Create transparent image
        img = Image.new('RGBA', (size, size), color=(0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        
        # Draw shield shape
        shield_points = [
            (size * 0.35, size * 0.15),
            (size * 0.35, size * 0.45),
            (size * 0.5, size * 0.75),
            (size * 0.65, size * 0.45),
            (size * 0.65, size * 0.15),
        ]
        draw.polygon(shield_points, fill='#E91E63', outline='white', width=int(size/50))
        
        # Draw location pin
        pin_center = (size // 2, int(size * 0.45))
        pin_radius = int(size * 0.08)
        draw.ellipse(
            [pin_center[0] - pin_radius, pin_center[1] - pin_radius,
             pin_center[0] + pin_radius, pin_center[1] + pin_radius],
            fill='white', outline='#4A90E2', width=int(size/100)
        )
        inner_radius = int(size * 0.05)
        draw.ellipse(
            [pin_center[0] - inner_radius, pin_center[1] - inner_radius,
             pin_center[0] + inner_radius, pin_center[1] + inner_radius],
            fill='#4A90E2'
        )
        
        # Draw checkmark
        check_points = [
            (int(size * 0.44), int(size * 0.49)),
            (int(size * 0.47), int(size * 0.52)),
            (int(size * 0.56), int(size * 0.43)),
        ]
        draw.line([check_points[0], check_points[1]], fill='white', width=int(size/35))
        draw.line([check_points[1], check_points[2]], fill='white', width=int(size/35))
        
        # Save image
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        img.save(output_path, 'PNG')
        print(f"Generated foreground icon: {output_path} ({size}x{size})")
        return True
    
    if __name__ == "__main__":
        print("Generating app icons...")
        generate_icon(1024, "assets/app_icon.png")
        generate_foreground_icon(1024, "assets/app_icon_foreground.png")
        print("Icons generated successfully!")
        print("\nNext steps:")
        print("1. Run: flutter pub get")
        print("2. Run: flutter pub run flutter_launcher_icons")
        
except ImportError:
    print("PIL (Pillow) not installed. Installing...")
    import subprocess
    import sys
    subprocess.check_call([sys.executable, "-m", "pip", "install", "Pillow"])
    print("Pillow installed. Please run this script again.")

