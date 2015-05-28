---
layout: post
title:  "Firefox OS as an Internet of Things platform"
date:   2014-12-16 09:13:00
categories: gonzo hardware
author: "Jan Jongboom"
project: Gonzo
comments: false
---

When developing [Gonzo]({{ site.baseurl }}/about-gonzo/), our wireless camera, one of the big questions that pops up is: 'Why does it run Firefox OS?'. At first it indeed seems like a weird fit, a camera that runs an operating system for mobile phones. An operating system that is even mostly targeted at the developing world. But Firefox OS is a better fit for embedded devices than you might think at first glance.

If we're talking about the Internet of Things from a prototype / hobby perspective there are two major players that create development kits. [Arduino](http://www.arduino.cc/) and [Raspberry Pi](http://www.raspberrypi.org/). Both are electronics platforms that allow you to connect sensors, and use the sensor data as input for your applications. While that seems as a great fit for embedded IoT devices, both solutions came out extremely expensive for a camera project like Gonzo. The least we need are a dev kit, a camera, a GSM shield and an accelerometer (leaving the battery out), which translates into the following bill of material.

Module  | Price
--------|---------
[Arduino Uno](http://store.arduino.cc/product/A000066) | &euro;20.00
[Camera module](https://www.sparkfun.com/products/11745) | &euro;25.73 ($31.95)
[GSM Shield](http://store.arduino.cc/product/A000043) | &euro;69.00
[Accelerometer](https://www.sparkfun.com/products/9269) | &euro;12.02 ($14.95)
**Total** | **&euro;126.75**

This shows in other components as well. Adding a decent touch screen to the material list will set us back another [$144.95](https://www.sparkfun.com/products/11740). When you think of this it's actually completely crazy. Why do I need to shell out ~126 euros on Arduino modules while I can get a full smartphone with processor, memory, touchscreen, GSM, bluetooth, WiFi and accelerometer for... [TWENTY-FOUR DOLLARS](https://www.facebook.com/cherrymobile/photos/a.299251607442.152915.269510017442/10152443834567443/?type=1). That's right. $24 retail price for a full smartphone off contract. And even better, it runs Firefox OS. If you look at the architecture of a phone like this (actually any Firefox OS phone), it looks like this:

<!--more-->

    Hardware -> Linux (Android kernel) -> Gecko (Browser engine) -> HTML5 UI

The full UI of Firefox OS is rendered through Gecko, the browser engine that also powers Firefox on Android and on desktop, including the dial screen; SMS application; and the camera viewfinder. To get that to work Mozilla added JavaScript APIs for any phone sensor or function that you find on the device. For example, Firefox OS allows you to make a call through:

{% highlight javascript %}
var call = navigator.mozTelephony.dial('+1555332134');
call.addEventListener('connected', function() {
   call.hangUp();
});
{% endhighlight %}

Thus when we strip off the UI we are left with a small computer (in a phone casing) that runs the Linux kernel and a JavaScript engine with bindings to all awesome phone things. Which sounds a bit like the [Tessel](https://tessel.io/) microcontroller. On top of that, it's running on an extremely stable and well tested platform. Although there is quite some criticism on the performance of low cost Firefox OS devices, phones running the OS have been sold in over 25 countries.

## Stripping off the case

The big downside versus an Arduino or Raspberry Pi is that the phone still has a case. Lucky for us these cheap mobile phones are quite modular and only consist of three parts:

* Casing
* Mother board with all sensors / chips soldered upon it
* Screen
* Sometimes an external antenna

We found it's also quite easy to open the casing and remove the mother board without breaking the phone. So far we managed to open any Firefox OS phone using normal crosshead or torque screwdrivers. Upon removing the outer casing you'll be presented with something like this:

![Firefox OS Motherboard from Geeksphone Peak]({{ site.baseurl }}/assets/mainboard1.png)

*The motherboard of the Geeksphone Peak Firefox OS smartphone. Clearly visible are the camera, SIM card slot, SD card slot, touchscreen / display connectors, micro USB port and the flash light.*

This main board can run outside of the casing and without the touchscreen connected. You will want to connect (solder?) a battery to the battery port as the phone cannot draw enough power from the micro USB connector to boot. After booting you can disconnect the battery, but the phone will shutdown because of lack of power when connecting to a WiFi network or using other connectivity features. Depending on the phone you pick (the cheapest phones that are based on Spreadtrum SC6821 platform don't need this) you can also have an antenna connector (bottom right corner on the image above) that you need to connect to have decent connectivity. If you also need WiFi, you will need to connect a WiFi antenna, which you can source from the casing. In general it's glued on to the outer casing and has to connect to two pins on the main board.

![Sourcing the WiFi antenna from the casing]({{ site.baseurl }}/assets/mainboard-wifi1.jpg) ![Attaching WiFi antenna to the board]({{ site.baseurl }}/assets/mainboard-wifi2.jpg)

*On the left: Removing the WiFi antenna from the casing using a flat screwdriver. On the right: Attaching the WiFi antenna to the board using anti-static tape.*

What we're now left with is a small computer with a ton of sensors that we can reprogram and then build into other assets. If you're good at disassembling you might also have preserved the screen, which you can connect back to the board whenever needed. As you can see from below the board can be quite small.

![Mainboard and screen compared to a banana]({{ site.baseurl }}/assets/mainboard-banana.jpg)

*The mainboard and screen of the Geeksphone Keon compared to a banana*

## Programming the board

Now that we have a board we can reprogram it to stop being a mobile phone and instead be an IoT board. For this we have a new mobile operating system called [JanOS](https://github.com/janjongboom/janos). It's a drop-in replacement for the Firefox OS UI that is meant to run on display-less devices. What it mainly does is boot into an HTML file where you can place your own JavaScript to control the board. It comes with some batteries included and also ships a few demo's.

* Can be flashed on any rooted Firefox OS phone.
* Has simple bindings for connectivity. WiFi & 2G/3G.
* Autodetects APN settings. Just plug a SIM card in, and it works.
* Comes with demo's for devicemotion, bluetooth doorbell, security camera & GPS tracker

Instructions on how to flash the OS on top of your Firefox OS phone are listed on the [GitHub](https://github.com/janjongboom/janos) project. You can use normal JavaScript to program the board and access things like the accelerometer / cameras / phone features / etc. To debug your applications there is a visual debugger available with [WebIDE](https://developer.mozilla.org/en-US/docs/Tools/WebIDE). It's also pretty great that it runs the Android kernel so whenever you need to run native code you can connect the device to the computer and run `adb shell` and access the embedded Linux that runs on the board.

Whenever you're happy with the results it's time to build it into something else, like we did with the Gonzo camera. Our current prototype consists of a Geeksphone Keon board, a battery and some soldering wires. Make sure to expose the USB port so you can debug it later on too.

![First Gonzo prototype]({{ site.baseurl }}/assets/mainboard-solder.jpg)

*First Gonzo prototype device we created for JSConf.asia. The battery is soldered to the main board and the antenna is visible at the top. The whole thing is mounted in a 3D printed case.*

## Conclusion

It gets even better when you don't need to use a mobile phone as a basis for your IoT devices. When you buy in volume you can buy the mainboard used in the $24 phone for under $10 (no need for casing / battery / screen), and use that as your new embedded platform. Using Firefox OS in Gonzo allows us to break the price barrier for small low-powered cameras, and also allows for faster development thanks to the already well-tested platform and the ability to write large parts of our code in JavaScript.

> Something that you will want when working with IoT is GPIO pins. For this we're re-using the volume up / volume down buttons, there is a lot less possibility here than with an Arduino, but it allows you for some basic connectivity. In a later blog post Thomas (our hardware engineer) will explain the steps needed to make this work.

It's also a sign on the wall that other companies are going the same route. [MatchStick](https://www.kickstarter.com/projects/2040419302/matchstick-the-streaming-stick-built-on-firefox-os) is using a similar tactic to bring a very cheap HDMI stick to market, and they raised 470.000 USD through KickStarter. Using Firefox OS (JanOS?) for IoT solutions is not just a crazy idea, it's a real low-cost opportunity.

## More info...

I gave a presentation about the subject at JSConf.EU earlier this year.

<iframe width="560" height="315" src="//www.youtube.com/embed/Uy062kp-LM4" frameborder="0" allowfullscreen></iframe>

If you want to get in touch regarding this blog post, drop me a line at [jan@telenordigital.com](mailto:jan@telenordigital.com). If this post got you excited and you want a Gonzo device, click the button below and fill in your email address!