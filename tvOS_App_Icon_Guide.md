# tvOS App Icon Size Requirements

## App Icon Imagestack Layers (Required Sizes)

### Front Layer (Primary Icon)
- **400x240px @1x** (for 1920x1080 screens)
- **800x480px @2x** (for 3840x2160 screens)

### Middle Layer (Optional - for depth effect)
- **400x240px @1x**
- **800x480px @2x**

### Back Layer (Optional - for depth effect)  
- **400x240px @1x**
- **800x480px @2x**

## App Store Icon (Required for submission)
- **1280x768px** (App Store listing)

## Top Shelf Images (When app is featured)
- **1920x720px** (Top Shelf Image Wide)
- **1600x480px** (Top Shelf Image)

## Steps to Convert NDQ-Video-Icon.png:

1. **Resize the source image** to the required dimensions:
   - Use image editing software (Photoshop, GIMP, Preview, etc.)
   - Create versions at each required size
   - Maintain aspect ratio and quality

2. **Add to Xcode**:
   - Drag the resized images into the appropriate imagestack layers
   - Front layer should contain your main icon
   - Middle/Back layers can be simplified versions for depth effect

3. **File Naming Convention**:
   - No specific naming required - Xcode manages this
   - Just ensure you place the correct size in the correct slot

## Current File Location:
- Source: `/Users/nathandykstra/tvNDQ3/tvNDQ3/NDQ-Video-Icon.png`
- Target: Assets.xcassets > App Icon & Top Shelf Image.brandassets

## Recommended Approach:
1. Open NDQ-Video-Icon.png in an image editor
2. Create the required sizes listed above
3. Drag them into Xcode's asset catalog
4. Use the Front layer for the main icon
5. Optionally create simplified versions for Middle/Back layers