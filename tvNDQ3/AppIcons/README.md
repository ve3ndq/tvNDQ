# Generated tvOS App Icons from NDQ-Video-Icon.png

## Successfully Generated Files:

### App Icon Imagestack Layers:
- **app-icon-front-1x.png** (400×240px) → Front layer @1x
- **app-icon-front-2x.png** (800×480px) → Front layer @2x
- **app-icon-middle-1x.png** (400×240px) → Middle layer @1x (60% opacity)
- **app-icon-middle-2x.png** (800×480px) → Middle layer @2x (60% opacity)
- **app-icon-back-1x.png** (400×240px) → Back layer @1x (30% opacity)
- **app-icon-back-2x.png** (800×480px) → Back layer @2x (30% opacity)

### App Store & Top Shelf:
- **app-icon-store.png** (1280×768px) → App Store submission
- **top-shelf-wide.png** (1920×720px) → Top Shelf Wide Image
- **top-shelf.png** (1600×480px) → Top Shelf Image

## How to Add to Xcode:

### 1. App Icon Imagestack:
1. Open Xcode project
2. Navigate to: Assets.xcassets > App Icon & Top Shelf Image.brandassets > App Icon.imagestack
3. Add files to layers:
   - **Front.imagestacklayer/Content.imageset/**: 
     - Drag `app-icon-front-1x.png` to @1x slot
     - Drag `app-icon-front-2x.png` to @2x slot
   - **Middle.imagestacklayer/Content.imageset/**: 
     - Drag `app-icon-middle-1x.png` to @1x slot
     - Drag `app-icon-middle-2x.png` to @2x slot
   - **Back.imagestacklayer/Content.imageset/**: 
     - Drag `app-icon-back-1x.png` to @1x slot
     - Drag `app-icon-back-2x.png` to @2x slot

### 2. App Store Icon:
1. Navigate to: App Icon - App Store.imagestack
2. Add `app-icon-store.png` to the appropriate layer

### 3. Top Shelf Images:
1. Navigate to: Top Shelf Image Wide.imageset
   - Add `top-shelf-wide.png`
2. Navigate to: Top Shelf Image.imageset
   - Add `top-shelf.png`

## Generation Command Used:
```bash
# Main app icon sizes
magick NDQ-Video-Icon.png -resize 400x240! AppIcons/app-icon-front-1x.png
magick NDQ-Video-Icon.png -resize 800x480! AppIcons/app-icon-front-2x.png
magick NDQ-Video-Icon.png -resize 1280x768! AppIcons/app-icon-store.png
magick NDQ-Video-Icon.png -resize 1920x720! AppIcons/top-shelf-wide.png
magick NDQ-Video-Icon.png -resize 1600x480! AppIcons/top-shelf.png

# Depth effect layers (with transparency)
magick NDQ-Video-Icon.png -resize 400x240! -channel A -evaluate multiply 0.6 AppIcons/app-icon-middle-1x.png
magick NDQ-Video-Icon.png -resize 800x480! -channel A -evaluate multiply 0.6 AppIcons/app-icon-middle-2x.png
magick NDQ-Video-Icon.png -resize 400x240! -channel A -evaluate multiply 0.3 AppIcons/app-icon-back-1x.png
magick NDQ-Video-Icon.png -resize 800x480! -channel A -evaluate multiply 0.3 AppIcons/app-icon-back-2x.png
```

All files are ready to be dragged into Xcode's asset catalog!