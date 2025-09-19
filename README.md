# tvNDQ3 IPTV Channel Manager for tvOS

A modern tvOS app for browsing, managing, and playing IPTV channels. Features favorites, channel groups, settings, and VLC integration.

## Features
- IPTV channel manager for tvOS 26.0+
- Three main pages: Favorites, Channels, Settings
- Favorites: Save and quickly access favorite channels
- Channels: Browse groups and channels from M3U playlists
- Settings: Configure M3U URL, refresh interval, and playback options
- Launches VLC with channel URL for playback
- Auto-refresh and manual refresh of channel list
- Secure secrets management (M3U URL not committed to GitHub)
- Modern, compact UI optimized for Apple TV
- App icon generation script and guide included

## Getting Started
1. Clone the repository
2. Copy `Config/Secrets.swift.template` to `Config/Secrets.swift` and set your M3U URL
3. Open the project in Xcode
4. Add your app icons using the guide in `tvOS_App_Icon_Guide.md` and `AppIcons/README.md`
5. Build and run on your Apple TV or tvOS Simulator

## Folder Structure
- `tvNDQ3/` - Main app source
- `tvNDQ3/Managers/` - Data managers (Favorites, Settings)
- `tvNDQ3/Services/` - M3U parsing service
- `tvNDQ3/Views/` - SwiftUI views
- `tvNDQ3/Config/` - Secrets and configuration
- `tvNDQ3/AppIcons/` - Generated app icon files
- `tvOS_App_Icon_Guide.md` - App icon requirements and instructions

## Security
- Sensitive configuration (M3U URL) is stored in `Config/Secrets.swift` and ignored by git
- Use the provided template for safe collaboration

## License
This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

## Credits
- Built with SwiftUI for tvOS
- Uses ImageMagick for automated app icon generation
- VLC integration via URL scheme

---

For questions or contributions, please open an issue or pull request on GitHub.