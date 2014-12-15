---
layout: post
title:  "A live feed from the canals"
date:   2014-12-15 15:48:00
categories: gonzo
author: "Jan Jongboom"
project: Gonzo
---

Yes, a live feed from the Amsterdam canals through [Gonzo]({{ site.baseurl }}/about-gonzo/), for everyone to admire. Actually the moment we speak the sun is setting, and Gonzo is taking a photo every 30 seconds to capture that magic moment. To see the live feed from Gonzo in your browser: [click here](https://gonzo-iot.firebaseapp.com/bcerk8wv).

![Photo taken at 16:26 (GMT+1)]({{ site.baseurl }}/assets/bpvg9j2a9k9.jpg)

<!--more-->

It also gives me the opportunity to show you an early look at the Web UI of Gonzo. Olav is currently completely redoing the design, so showing it here is also a way of archiving the very first look of the service.

![Gonzo Web, very first iteration]({{ site.baseurl }}/assets/web-ui.png)

Let's go over the components here:

1. At the top of the screen we have a slider, which allows you to quickly 'fly' through time. Whenever you move it the image and the other details automatically change as well, so we don't need a preview image. Downside of this is that it's not a real timeline so when you pause Gonzo it creates a weird effect. We're gonna replace it by a proper timeline at some point in the near future.
2. Then we have time indication, useful when scrobbling through the slider.
3. Some controls, configuration / timelapse / orientation fix if you change the orientation of the camera. And the 'Take picture' button which will trigger a photo right away.
4. The photo itself. The left 33% and the right 33% are clickable so you can navigate through the stream. You can also use your scrollwheel if your mouse is in this area to quickly fly through.
5. Some basic information, share URLs, etc.
6. If available, map based on OpenCellMap data. Unfortunately quite some missing spots, but GPS draws way too much power to add this. Hopefully will get better over time, but it looks cool.

But hey, this is a very early look. Let's see what the future brings!
