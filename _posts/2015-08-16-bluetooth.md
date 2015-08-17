---
layout: post
title:  "Flying a drone in your browser with WebBluetooth"
date:   2015-08-16 17:24:00
categories: iot
author: "Jan Jongboom"
tags:
comments: false
---

There's a ton of devices around us, and that number is only growing. And more and more of these devices contain connectivity. From [suitcases](http://bluesmart.com/) to [plants](http://www.parrot.com/usa/products/flower-power/) to [eggs](http://www.amazon.com/Minder-Wink-App-Enabled-Smart-Tray/dp/B00GN92KQ4). That brings new challenges: how can we discover devices around us, and how can we interact with them?

Currently interactivity is handled by separate apps running on mobile phones. But this does not solve the discoverability issue. I need to know which devices are around me before I know which app to install. When I'm standing in front of a [meeting room](http://blog.telenor.io/iot/2015/08/04/smart-meetingroom.html) I don't care about which app to install, or even what the name or ID of the meeting room is. I just want to make a booking or see availability, and as fast as possible.

# Bluetooth

[Scott Jenson](https://twitter.com/scottjenson) from Google has been thinking about discoverability for a while, and came up with [physical web](https://google.github.io/physical-web/), whose premise is:

> Walk up and use anything

The idea is that you use [Bluetooth Smart](http://www.bluetooth.com/Pages/Bluetooth-Smart.aspx), the low energy variant of bluetooth, to broadcast URLs to the world. Your phone picks up the advertisment package, decodes it, and shows some information to the user. One click and the user is redirected to a web page with relevant content. This can be used for a variety of things:

* Meeting room broadcasts a URL to it's calendar
* Movie poster broadcasts a URL for viewing times and trailers
* ???

A problem this presents however is that this is a one-way street. Broadcasting URLs is great for things like movie times, but it does not allow me to interact with the device on a deeper level. If I want to fly a [drone](http://www.parrot.com/usa/products/rolling-spider/) I not only want to discover that a drone is around me, I also want to interact with the device straight away. For that we need to a way for web pages to talk back to the device.

Enter the work of the [Web Bluetooth](https://www.w3.org/community/web-bluetooth/) W3C group, in Mozilla represented by the [Bluetooth team](https://wiki.mozilla.org/B2G/Bluetooth), who are working on bringing bluetooth APIs to the browser. If physical web allows up to walk up to any device and get a URL of a web app, then WebBluetooth allows the web app to connect to the device and talk back to it.

At this point however there's a lot of work to be done. The bluetooth API is only exposed to [certified content](https://developer.mozilla.org/en-US/Firefox_OS/Security/Security_model) on Firefox OS, and thus not accessible to ordinary web content. This will probably remain so until security issues have been cleared. The second issue is that physical web beacons broadcast a URL. How would web content know which device broadcasted the URL?

As you can see, lots of work to be done, but this blog is called Mozilla Hacks for a reason. Let's start hacking!

# Adding Physical Web support to Firefox OS

As most work around WebBluetooth has been done for Firefox OS, it has been my weapon of choice. I want the process of discovering devices to be as painless as possible, and thus figured the one right place would be on the lockscreen. Whenever you have bluetooth enabled on the phone a new notification will pop up asking you to search for devices.

<img src="{{ site.baseurl }}/assets/bt1.png" title="Tap, tap, tap">

When you tap the button we use the new Bluetooth Low Energy (BLE) APIs to discover devices around us. Listing devices is pretty easy.

{% highlight js %}
navigator.mozBluetooth.defaultAdapter.startLeScan([]).then(handle => {
  handle.ondevicefound = e => {
    console.log('Found', e.device, e.scanRecord);
  };

  setTimeout(() => {
    navigator.mozBluetooth.defaultAdapter.stopLeScan(handle)
  }, 5000);
}, err => console.error(err));
{% endhighlight %}

As you can see on the third line we have a `scanRecord`. This is the advertisement package that the device broadcasts. This is nothing more than a set of bytes, and you are free to declare your own protocol. For our purpose, broadcasting URLs over bluetooth there are two ways of encoding already: [UriBeacon](https://github.com/google/uribeacon) and [EddyStone](https://github.com/google/eddystone) which we'll both see in the wild.

Parsing the advertisement package is pretty straightforward, f.e. [here](https://gist.github.com/janjongboom/78f6e45bc3b4133193ff) is the code to parse UriBeacons. After that however we only have a URL (often shorted, because limited bytes in the advertisement package) and that makes for a bad UI.

<img src="{{ site.baseurl }}/assets/bt2.png" title="So what the hell is this device?">

To get some information about the web page that is behind the beacon we can do an AJAX request and parse the content of the page to enhance the information on the lockscreen.

{% highlight js %}
function resolveURI(uri, ele) {
var x = new XMLHttpRequest({ mozSystem: true });
x.onload = e => {
  var h = document.createElement('html');
  h.innerHTML = x.responseText;

  // After following 301/302s, this contains the last resolved URL
  console.log('url is', x.responseURL);

  var titleEl = h.querySelector('title');
  var metaEl = h.querySelector('meta[name="description"]');
  var bodyEl = h.querySelector('body');

  if (titleEl && titleEl.textContent) {
    console.log('title is', titleEl.textContent);
  }

  if (metaEl && metaEl.content) {
    console.log('description is', metaEl.content);
  }
  else if (bodyEl && bodyEl.textContent) {
    console.log('description is', bodyEl.textContent);
  }
};
x.onerror = err => console.error('Loading', uri, 'failed', err);
x.open('GET', uri);
x.send();
};
{% endhighlight %}

This yields a nicer notification which actually describes the beacon.

<img src="{{ site.baseurl }}/assets/bt3.png" title="Much nicer">

## A drone that doesn't broadcast a URL

Unfortunately not all BLE devices broadcast URLs at this point. Given that all of this is both experimental and very cool technology we've got high hopes that that will change in the near future. Because I still want to be able to fly the drone I added some code that transforms the data a drone broadcasts [into a URL](https://github.com/comoyo/gaia/blob/physical_web/apps/system/lockscreen/js/lockscreen_physical_web.js#L126).

# The web application

Now that we solved discovery we need a way of controlling the drone from the browser. As bluetooth access is not available for web content we need to make some changes to Gecko, where the security model behind Firefox OS is implemented. If you are interested in the changes, [here's the commit](https://github.com/jan-os/gecko-dev/commit/4c80faf0e48ebad1346ca9fcdbada18a6a276e6d). Additionally we needed a [dirty hack](https://github.com/comoyo/gaia/commit/d823f61994ded5fdb7259bf965ba82b7746a2db9) to make sure the tab's process would be run with the right Linux permissions. If you're playing around with the build later please note that you are running a build where no security is guaranteed.

With the API in place, we can now start writing the application. When you tap on the physical web notification on the lockscreen we pass the device address in as a parameter. This is subject to change, for the ongoing discussion take a look at [Eddystone -> Web Bluetooth handoff](https://docs.google.com/document/d/1jFCTyq84T2fLc8ZhxorTz3u_gCk59hp17EmkFgaDQ2c/edit). With the device address we can set up a connection to the device.

{% highlight js %}
var address = 'aa:bb:cc:dd:ee'; // parsed from URL
var counter = 0;
navigator.mozBluetooth.defaultAdapter.startLeScan([]).then(handle => {
  handle.ondevicefound = e => {
    if (e.device.address !== address) return;

    navigator.mozBluetooth.defaultAdapter.stopLeScan(handle);

    // write some code to fly the drone
  };
}, err => console.error(err));
{% endhighlight %}

Now that we have a reference to the device we can set up a connection. The protocol we use to talk back and forth to the device is called [GATT](https://www.safaribooksonline.com/library/view/getting-started-with/9781491900550/ch04.html), the Generic Attribute Profile. The idea behind GATT is that a device can have multiple standard services. For example, a heart rate sensor can implement the battery service and the heart rate service. Because these services are standardized a consuming application only needs to write the implementation logic once, and can talk to any hear rate monitor.

Part of the service are characteristics. A heart rate service will implement f.e. [heart rate measurement](https://developer.bluetooth.org/gatt/characteristics/Pages/CharacteristicViewer.aspx?u=org.bluetooth.characteristic.heart_rate_measurement.xml) and [heart rate max](https://developer.bluetooth.org/gatt/characteristics/Pages/CharacteristicViewer.aspx?u=org.bluetooth.characteristic.heart_rate_max.xml). Characteristics can be readable and writeable depending on the definition. This goes the same with the drone. It has a service for flying the drone and characteristics to control the drone from your phone.

Luckily [Martin Dlouhý](http://robotika.cz/robots/jessica/en) (as far as I can find he was the first one) already decoded the communication protocol for the Rolling Spider drone, so we can use his work and the new Bluetooth API to start flying...

{% highlight js %}
// Have a way of knowing when the connection drops
e.device.gatt.onconnectionstatechanged = cse => {
  console.log('connectionStateChanged', cse);
};
// Receive events (battery change f.e.) from device
e.device.gatt.oncharacteristicchanged = cce => {
  console.log('characteristicChanged', cce);
};

// Set up the connection
e.device.gatt.connect().then(() => {
  return e.device.gatt.discoverServices();
}).then(() => {
  // devices have services, and services have characteristics
  console.log('services', e.device.gatt.services);

  // find the characteristic that handles flying the drone
  var c = services.reduce((curr, f) => curr.concat(f.characteristics), [])
    .filter(c => c.uuid === '9a66fa0b-0800-9191-11e4-012d1540cb8e')[0];

  // take off instruction!
  var buffer = new Uint8Array(0x04, counter++, 0x02, 0x00, 0x01, 0x00]);
  c.writeValue(buffer).then(() => {
    console.log('take off successful!');
  });
});
{% endhighlight %}

The Mozilla team in Taipei used this to create a [demo application](https://github.com/fxos-bt-squad/RollingSpider) for Firefox OS, demonstrating the capabilities of the new API during the Mozilla work week in Whistler last June. With the API now available in the browser we can take that work, [host it as a web page](https://github.com/janjongboom/rollingspider.xyz), beef up the graphics a bit, and have a *web site* flying a drone!

<img src="{{ site.baseurl }}/assets/bt4.png" title="Such amaze">

*Such amaze. Much drone.*

<iframe src="https://www.youtube.com/embed/yILD_ZdXJW4" frameborder="0" allowfullscreen></iframe>

# Conclusion

It's an exciting time for the web! With more and more devices coming online we need a way of discovering and interacting with these devices without much hassle. The combination of both physical web and WebBluetooth allows us to create frictionless experiences for users willing to interact with real-world appliances. Although we're a long way off we're heading in the right direction with Google and Mozilla investing heavily in the tech; giving me high hopes that everything in this blog post will be common knowledge in 12 months from now!

If that's not fast enough for you, you can play around with an experimental build of Firefox OS which enables everything seen in this post. This build runs on the [Flame](https://developer.mozilla.org/en-US/Firefox_OS/Developer_phone_guide/Flame) developer device. First upgrade to [nightly_v3 base image](https://developer.mozilla.org/en-US/Firefox_OS/Phone_guide/Flame/Updating_your_Flame), then flash [this build](http://rollingspider.xyz/bt-flame.zip).

## Attributions

Thanks a lot to [Tzu-Lin Huang](https://github.com/dwi2) and [Sean Lee](https://github.com/weilonge) for building the initial drone code; the WebBluetooth team in Mozilla Taipei (esp. [Jocelyn Liu](https://github.com/yrliou)) for their quick feedback and patches when bitching about the API; [Chris Williams](https://twitter.com/voodootikigod) for putting the drone in my JSConf.us gift bag; [Scott Jenson](https://twitter.com/scottjenson) for answering my numerous questions about physical web; and [Telenor Digital](http://telenordigital.com/) for letting me play with drones for two weeks.
