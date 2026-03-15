# Build and Test Instructions

## Building the APK

### Option 1: Using GitHub Actions (Recommended)

The repository now has an automated build workflow that generates APK files automatically.

**Steps:**
1. After pushing commits to this branch, go to the "Actions" tab in GitHub
2. Find the "Build APK" workflow run for your commit
3. Wait for the build to complete (usually 5-10 minutes)
4. Download the APK from the "Artifacts" section at the bottom of the workflow run
5. Transfer the APK to your Android device and install it

**Manual Trigger:**
You can also manually trigger the build workflow:
1. Go to the "Actions" tab
2. Select "Build APK" from the workflows list
3. Click "Run workflow" button
4. Select the branch (copilot/add-group-channels-and-numbers)
5. Click "Run workflow" to start the build

### Option 2: Build Locally

If you have Flutter installed on your machine:

```bash
# 1. Clone the repository
git clone https://github.com/BiplopDey/Indian-IPTV-App.git
cd Indian-IPTV-App

# 2. Checkout the branch
git checkout copilot/add-group-channels-and-numbers

# 3. Install dependencies
flutter pub get

# 4. Build the APK
flutter build apk --release

# 5. Find the APK at:
# build/app/outputs/flutter-apk/app-release.apk
```

## Testing the New Features

### 1. Channel Numbers
- Open the app and browse the channel list
- Each channel should display a number badge (1, 2, 3, etc.) before the logo
- In the player screen, the channel number should appear in the AppBar

### 2. Country Grouping
- On the home screen, tap the "Grouped View" button (top right)
- Channels should now be organized by country
- Each country section shows the flag icon, country name, and channel count
- Tap on a country to expand/collapse the channel list

### 3. Country Filtering
- Scroll the horizontal chip row below the search bar
- Tap on a country chip to filter channels by that country
- Tap "All" to show all channels again

### 4. TV Remote Navigation
- Connect a keyboard to your Android TV or use an Android emulator with keyboard
- Type a channel number (e.g., "5", "23", "100")
- A large number overlay appears in the top-right corner showing your input
- After 1.5 seconds of no input, the app automatically navigates to that channel
- If the channel doesn't exist, an error message appears

### Testing Tips

**For TV Remote/Keyboard Navigation:**
- Use Android TV or an emulator with keyboard support
- Both regular number keys (0-9) and numpad keys work
- Test multi-digit numbers (e.g., 25, 123)
- Try invalid numbers to test error handling

**For Grouped View:**
- Test with channels from multiple countries
- Verify channel counts are correct
- Test expanding/collapsing multiple countries

**For Country Filtering:**
- Test filtering by different countries
- Verify the channel list updates correctly
- Test clearing the filter with "All"

## Requirements

- Android 5.0 (API level 21) or higher
- For TV remote navigation: Android TV or device with keyboard support

## Troubleshooting

**APK Installation Issues:**
- Enable "Install from Unknown Sources" in Android settings
- Make sure you're downloading the correct APK file

**Build Failures:**
- Check the GitHub Actions logs for specific errors
- Ensure all dependencies are properly specified in pubspec.yaml

**TV Remote Not Working:**
- Ensure you're testing on Android TV or emulator with keyboard
- The feature requires physical keyboard input (not on-screen keyboard)
