---
title: 'Automating Astrophotography With an Old Canon DSLR and gphoto2'
description: 'Fun with a 15 year old camera and Linux'
pubDate: 'Aug 10 2026'
---

I recently became interested in astrophotography and bought a cheap old Canon DSLR to play around with. After watching several videos on how to capture and stack photos of the night sky I learned I needed a few more things to make the process easier. The first, a tripod and the second an intervalometer or an interval meter. It's basically a remote for the camera that allows you to program a set number of shots so you won't have to touch the camera between shots and disturb the image. I don't know why Canon didn't include this in the camera itself, but you can only shoot up to 10 continuous photos (per shutter press) without one.

After ordering an intervalometer from China I did a little more digging and found that you can control Canon DSLRs using Canon's EOS utility. The version that supports my 1100d is outdated, but I still got it to work on my also outdated MacOs 13 install on my 2015 Macbook pro 15 inch.

You probably noticed the gear I tend to work with is all old.

While the EOS utility seemed to work fine, its graphical feature set lacks some of the things I would rather automate. You don't want to take 100 photos and then realize one of your settings was wrong.

While looking up how to check my shutter count, I found 
gphoto2. A command line utility for Unix like operating systems used to control digital cameras. You can automate the settings for your astronomy setup, program the number of shots and intervals and even save the photos directly to your disk or network storage.

After growing impatient with Homebrew building gphoto2 from scratch, I fired up a Linux machine and installed it with dnf.

Of course, there was a hurdle to overcome before I could run any commands. gphoto2 was being blocked because GVFS was using the camera to make its storage available to the file system.

I found the solution in this 2014 blog post about using a Canon camera and gphoto2 on Linux, which explains that the GVFS camera processes need to be stopped before gphoto2 can access the camera directly.

Here's how I fixed it:

killall gvfs-gphoto2-volume-monitor gvfsd-gphoto2

I was then able to get the shutter count, which was scary high but still less than Canon's stated 100k design spec.

```
gphoto2 --get-config /main/status/shuttercounter
```
```
Label: Shutter Counter                                                           
Readonly: 1  
Type: TEXT  
Current: 68394  
END
```

I then experimented with settings commands and interval shots:

```
gphoto2 --set-config /main/imgsettings/imgformat=RAW --set-config /main/imgsettings/iso=800 --set-config /main/capturesettings/shutterspeed=2 --set-config /main/capturesettings/aperture=3.5 --frames 200 --interval 3 --capture-image-and-download
```

Note the interval needs to be longer than the shutter speed to allow the camera to prepare to take the next shot. Next I vibe coded a basic script:

```
#!/bin/bash

echo "Releasing USB lock from system volume monitors..."
systemctl --user stop gvfs-gphoto2-volume-monitor.service 2>/dev/null
killall gvfs-gphoto2-volume-monitor gvfsd-gphoto2 2>/dev/null

SESSION_DIR="astro_$(date +%Y-%m-%d_%H-%M)"
echo "Creating session directory: $SESSION_DIR"
mkdir -p "$SESSION_DIR"
cd "$SESSION_DIR" || exit

echo "Starting sequence: 200 RAW frames at ISO 800, 2s, f/3.5..."
gphoto2 \
  --set-config /main/imgsettings/imgformat=RAW \
  --set-config /main/imgsettings/iso=800 \
  --set-config /main/capturesettings/shutterspeed=2 \
  --set-config /main/capturesettings/aperture=3.5 \
  --filename "astro_shot_%03n.%C" \
  --frames 200 \
  --interval 3 \
  --capture-image-and-download

echo "Sequence complete! Restoring system volume monitor..."
systemctl --user start gvfs-gphoto2-volume-monitor.service 2>/dev/null
```

I may have gotten a bit carried away as the above script is probably adequate for most people. One feauture you may appreciate is a live view, which can help focussing your lens by making the stars as small as possible. I also added prompts with the camera’s available settings, validity checks and a battery level check. It’s hard to draw a line when you can add features so easily. After all, the sky’s the limit:

See the latest script here: https://github.com/hobbitronics/astro

<details>
<summary>Show the full capture script</summary>

```bash
#!/bin/bash

MONITOR_STOPPED=0

restore_volume_monitor() {
    if [ "$MONITOR_STOPPED" -eq 1 ]; then
        systemctl --user start gvfs-gphoto2-volume-monitor.service 2>/dev/null
        MONITOR_STOPPED=0
    fi
}

trap restore_volume_monitor EXIT

get_config_choices() {
    local config_path="$1"
    local fallback_choices="$2"
    local choices

    choices=$(gphoto2 --get-config "$config_path" 2>/dev/null | awk '
        /^Choice:/ {
            sub(/^Choice:[[:space:]]+[0-9]+[[:space:]]+/, "")
            if (choices != "") choices = choices ", "
            choices = choices $0
        }
        END {
            if (choices != "") print choices
        }
    ')

    if [ -n "$choices" ]; then
        echo "$choices"
    else
        echo "$fallback_choices"
    fi
}

# Ask for capture settings
read -p "Number of frames [1]: " TOTAL_FRAMES
TOTAL_FRAMES=${TOTAL_FRAMES:-1}

read -p "Interval between shots in seconds [12]: " INTERVAL
INTERVAL=${INTERVAL:-12}

echo ""
echo "Capture settings:"
echo "  Frames:       $TOTAL_FRAMES"
echo "  Interval:     ${INTERVAL}s"

# 1. Kill background processes to free up the USB interface

echo ""
echo "Releasing USB lock from system volume monitors..."
systemctl --user stop gvfs-gphoto2-volume-monitor.service 2>/dev/null
killall gvfs-gphoto2-volume-monitor gvfsd-gphoto2 2>/dev/null
MONITOR_STOPPED=1

# 2. Check if the camera is physically connected and detected

echo "Checking camera connection..."
if ! gphoto2 --auto-detect | grep -q "usb"; then
    echo "❌ ERROR: Camera not detected! Check your USB cable and power switch."
    exit 1
fi

echo "✓ Camera detected successfully."

# 3. Check battery status

echo "Checking battery level..."
BATTERY_INFO=$(gphoto2 --get-config /main/status/batterylevel 2>/dev/null)
BATTERY_VAL=$(echo "$BATTERY_INFO" | grep "Current:" | awk '{print $2}')

if [ -z "$BATTERY_VAL" ]; then
    echo "⚠️ WARNING: Could not read battery level. Proceeding with caution."
else
    echo "✓ Battery level is at: $BATTERY_VAL"

    if [[ "$BATTERY_VAL" =~ ^[0-9]+$ ]] && [ "$BATTERY_VAL" -lt 20 ]; then
        echo "❌ ERROR: Battery is too low ($BATTERY_VAL%). Recharge before starting."
        exit 1
    fi
fi

SHUTTER_OPTIONS=$(get_config_choices "/main/capturesettings/shutterspeed" "bulb, 1, 1/60, 1/125, 1/250")
APERTURE_OPTIONS=$(get_config_choices "/main/capturesettings/aperture" "3.5, 5.6, 8, 11, 16")
ISO_OPTIONS=$(get_config_choices "/main/imgsettings/iso" "100, 200, 400, 800, 1600")

echo ""
echo "Available ISO options: $ISO_OPTIONS"
read -p "ISO [1600] (enter one of the listed values): " ISO
ISO=${ISO:-1600}

echo ""
echo "Available shutter speed options: $SHUTTER_OPTIONS"
read -p "Shutter speed [10] (enter one of the listed values): " SHUTTER_SPEED
SHUTTER_SPEED=${SHUTTER_SPEED:-10}

echo "Available aperture options: $APERTURE_OPTIONS"
read -p "Aperture [3.5] (enter one of the listed values): " APERTURE
APERTURE=${APERTURE:-3.5}

echo ""
echo "Capture settings:"
echo "  Frames:       $TOTAL_FRAMES"
echo "  Interval:     ${INTERVAL}s"
echo "  ISO:          $ISO"
echo "  Shutter:      $SHUTTER_SPEED"
echo "  Aperture:     $APERTURE"
echo ""

read -p "Start capture? [Y/n]: " CONFIRM
CONFIRM=${CONFIRM:-Y}

if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

# 4. Create a uniquely named folder for tonight's session

SESSION_DIR="astro_$(date +%Y-%m-%d_%H-%M)"
echo "Creating session directory: $SESSION_DIR"
mkdir -p "$SESSION_DIR"
cd "$SESSION_DIR" || exit 1

# 5. Set camera configurations

echo "Configuring camera settings..."
gphoto2 \
    --set-config /main/imgsettings/imgformat=RAW \
    --set-config /main/imgsettings/iso="$ISO" \
    --set-config /main/capturesettings/shutterspeed="$SHUTTER_SPEED" \
    --set-config /main/capturesettings/aperture="$APERTURE" \
    > /dev/null 2>&1

# 6. Capture loop with progress bar

echo ""
echo "Starting capture sequence..."

for ((i=1; i<=TOTAL_FRAMES; i++)); do

    # Calculate progress
    PERCENT=$(( i * 100 / TOTAL_FRAMES ))
    BAR_LENGTH=$(( PERCENT / 4 ))

    # Construct progress bar
    BAR=$(printf "%${BAR_LENGTH}s" | tr ' ' '#')

    # Print progress
    printf "\rProgress: [%-25s] %d%% (%d/%d frames)" \
        "$BAR" "$PERCENT" "$i" "$TOTAL_FRAMES"

    # Capture frame
    gphoto2 \
        --filename "astro_shot_$(printf "%03d" "$i").%C" \
        --capture-image-and-download \
        > /dev/null 2>&1

    # Wait for next shot
    if [ "$i" -lt "$TOTAL_FRAMES" ]; then
        sleep "$INTERVAL"
    fi

done

echo ""
echo ""
echo "🎉 Sequence complete!"
echo "Images saved in: $(pwd)"

# 7. Restore system services

echo "Restoring system volume monitor..."
restore_volume_monitor
trap - EXIT
```

</details>
