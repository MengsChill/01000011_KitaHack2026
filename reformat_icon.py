from PIL import Image, ImageChops

def trim(im):
    bg = Image.new(im.mode, im.size, im.getpixel((0,0)))
    diff = ImageChops.difference(im, bg)
    diff = ImageChops.add(diff, diff, 2.0, -100)
    bbox = diff.getbbox()
    if bbox:
        return im.crop(bbox)
    return im

def process_icon(path):
    # Load
    img = Image.open(path).convert("RGBA")
    bg_color = img.getpixel((0,0))
    
    # Trim whitespace
    cropped = trim(img)
    
    # Create 1024x1024 canvas
    canvas_size = 1024
    new_img = Image.new("RGBA", (canvas_size, canvas_size), bg_color)
    
    # Scale cropped logo to 80% (820px)
    safe_zone_size = int(canvas_size * 0.8)
    w, h = cropped.size
    ratio = min(safe_zone_size/w, safe_zone_size/h)
    new_w, new_h = int(w*ratio), int(h*ratio)
    resized = cropped.resize((new_w, new_h), Image.Resampling.LANCZOS)
    
    # Paste centered
    offset = ((canvas_size - new_w) // 2, (canvas_size - new_h) // 2)
    new_img.paste(resized, offset, resized)
    
    # Convert back to RGB (remove alpha to avoid App Store warnings if requested, 
    # but for now keeping it as is or removing depending on bg_color)
    final = new_img.convert("RGB")
    final.save(path)
    print(f"Icon processed and saved to {path}")

if __name__ == "__main__":
    process_icon("assets/app_logo.png")
