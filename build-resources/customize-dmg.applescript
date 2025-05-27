tell application "Finder"
    tell disk "CacheCleaner"
        open
        
        -- Set window size and position
        set bounds of container window to {400, 100, 900, 400}
        
        -- Set view options
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        
        -- Set background
        set opts to the icon view options of container window
        set background picture of opts to file ".background.png"
        
        -- Set icon arrangement
        set arrangement of icon view options of container window to not arranged
        
        -- Set icon positions
        set position of item "CacheCleaner.app" of container window to {120, 150}
        set position of item "Applications" of container window to {380, 150}
        
        -- Clean up
        update without registering applications
        delay 5
        close
    end tell
end tell 