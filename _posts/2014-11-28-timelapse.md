---
layout: post
title:  "Timelapse"
date:   2014-11-28 15:44:28
categories: gonzo cloud-software
author: "Jan Jongboom"
tags: gonzo
comments: false
---

<video src="{{ site.baseurl }}/assets/gonzo-timelapse.webm" controls></video>

*Timelapse of the sky. Gonzo can function both horizontal & vertical position. It uses accelerometer data to rotate the picture automatically.*

Gonzo generates a lot of data. Our demo models currently make a picture every 30 seconds, mainly so we can see battery drain quickly, totalling at 2,880 photo's a day. When you have to navigate this many photo's you want to glaze over them as quickly as possible. To facilitate that we listen to the mousewheel event and change the photos using that which you can then use to quickly 'fly' over a stream. Something you learn when you interact with the stream that way is that when a Gonzo is stationary, you can create some pretty amazing timelapses. With that in mind I hacked my Friday morning away on a simple timelapse feature. First thing to do is of course to put one of our prototypes in front of the canals in Amsterdam.

<!--more-->

![Gonzo overlooking the canals]({{ site.baseurl }}/assets/IMG_0183.jpg)

The moment you put your Gonzo somewhere it will just start recording, so in no time we have a nice stream of photo's that we can then convert into a timelapse video. Because I didn't want to rely on any server component I took the [whammy](https://github.com/antimatter15/whammy) library that takes in a frame rate and photos and then converts it into a WebM stream. The photo URLs already are on the client so the only thing we need to do is sequentially load all the URLs (are cached in browser cache so subsequent actions are fast too), put them onto a canvas, and feed them into Whammy.

First problem we encountered here is a big fat error in the JavaScript console:

> Unable to get image data from canvas because the canvas has been tainted by cross-origin data.

Apparently a canvas will be tainted whenever you put an image on it that does not have the right CORS headers. Never knew that. Good thing Amazon S3 has a simple way of adding CORS headers, but that didn't solve the problem. By default Amazon only sends the CORS headers whenever an 'origin' is specified in the original requests, which you can set from JS via:

{% highlight javascript %}
var img = new Image();
img.crossOrigin = 'anonymous'; // TAH DAH!
img.onload = () => {};
img.onerror = () => {};
img.src = url;
{% endhighlight %}

After this the video is properly generated and we can enjoy beautiful timelapses. Only issue is to add a UI for all this beauty so I quickly hacked together some buttons to control the timeline and a small form that pops up when you click one of them buttons.

![Timelapse UI]({{ site.baseurl }}/assets/timelapse-ui.png)

And the result:

<video src="{{ site.baseurl }}/assets/timelapsecanal2.webm" controls></video>

I looked for a bunch of other interesting streams, and realized that one night I had a Gonzo pointed at my screen. Creates a pretty cool video too! Only downside is that you can see me looking at [dumpert.nl](http://dumpert.nl) too often :-)

<video src="{{ site.baseurl }}/assets/timelapsecomputer.webm" controls></video>

Quite the downside is that Whammy needs WebP images as input which does not work in Firefox, but we'll find a workaround. Anyway, it looks cool and that's a start!
