---
title: 'Astrophotography image stacking'
description: 'Notes on how to stack photos with Deep Sky stacker'
pubDate: 'Aug 13 2026'
---

You want as raw an image as you can get so go through your settings and turn off and automatic white balancing, color temp, etc.

Turn off Manual Focus and Auto Focus off

Take 3 types of calibration frames. You can use gphoto2 as a intervelometer to automate taking these and my wrapper script

* Bias frames - on manual go to shortest exposure (1/8000 or whatever your is) set iso to whatever your light frames (the photos you take of the sky) are. Take the shots with the body cap on in the dark to pick up noise from the sensor. Take 50 with you intervalometer or manually. Some are better than none.
* Dark frames - similar to bias, with cap in dark. Match the exposure time as your light frames (e.g. 3 sec. depending on formula). Take 30-50. Must match temperature e.g. 15 degrees Celsius, that your light frames will be in.
* Flat frames - same focal point and aperture. Take with lens on into a white tablet screen with optionally some white paper over it. If you see lines paper or longer exposure can help.  Bring up histogram and bring it 1/3 to half way over. Take 30-50.
* Light frame (subs)

When focusing use high ISO (400 to 3200 depending on your camera noise level, star trails, etc.) and exposure time to get live view to show stars. I’ve been using experience to find a shutter speed of about 5 seconds eliminates star trails in Adelaide. There's the 500 rule and npf rule.

Use the Zoom button to get on the brightest star and focus with Bahtinov mask if you need to. Otherwise just get the stars as small as you can and, take a photo and zoom in to see if you're focues. I use my wrapper script to live view on my headless Surface Pro 7+ running Fedora and linux-surface I found on a curb and paired with a 15" portable screen.

Credit to Nebula Photos

### Videos:

- [You don't need expensive gear to photograph other galaxies](https://youtu.be/aB5IiKiGDE8?si=eOeh5WwE8wZOm3XP)
- [Orion Nebula WITHOUT a Star Tracker or Telescope, Start to Finish, DSLR Astrophotography](https://youtu.be/iuMZG-SyDCU?si=nmw_MoxhhMjlU9s7)

My third feable attempt at image stacking. 20 images shot at 55mm. Edited in Darktable.
![Stacked astro photo](https://nextcloudpi.wilson-cloud.us/index.php/s/pb24wtLwikMnrBx/download)

My second feable attempt at image stacking. 30 images shot at 55mm. Edited in Darktable.
![Stacked astro photo](https://nextcloudpi.wilson-cloud.us/index.php/s/tQp2Fez2tmjtkxi/download)