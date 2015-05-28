---
layout: post
title:  "Managing configuration on the device"
date:   2014-11-27 16:44:55
categories: gonzo device-software
author: "Jan Jongboom"
tags: gonzo
comments: false
---

There is a variety of configuration options on the device that need to be managed, from the interval in which photos are made, to the API URL of the server. When you think over all the configuration options we have we can put them in three categories:

1. Hard coded in the source code, e.g. the location of the API
2. Local configuration, e.g. the PIN code of the SIM card in the device
3. Remote configuration, e.g. the JPEG compression rate on photos

In general you want your basic configuration file to look completely OK so when someone flashes the device everything works out of the box. Sometimes it is required that pre-build time you configure some options, like the PIN code or whether you want to roam on the SIM card. Other options need to be changable from distance, because you would not want to re-flash a device to change the interval it makes photos in.

To accomodate for this we use a couple of techniques. First, we use [architect](http://github.com/c9/architect), a dependency injection framework, to abstract away modules and their configuration on the device. We have a base configuration file that lists all the modules we have and we can specify options on a per-module basis. For example:
<!--more-->

{% highlight javascript %}
var config = [
  {
    packagePath: 'js/plugins/camera',
    compression: 0.7
  },
  {
    packagePath: 'js/plugins/uploader',
    apiUrl: 'https://some/place/' + deviceId
  },
  {
    packagePath: 'js/plugins/radio',
    pin: null // we don't know PIN code here. It's generic config.
  }
];
// load the app through architect
{% endhighlight %}

The advantage that this has is that:

1. All configuration is in a single file
2. Options are module specific. The uploader plugin does not have to know about the `compression` option in camera.
3. Plugins don't know anything about devices. The uploader gets an API endpoint where it can upload to. How that is constructed does not matter for the plugin.

## Overriding local settings

Now we have a SIM card that has a PIN code, and we need to override this. For this we have a local file that we host in the project folder, but is not included in version control, that has a similar format, called `local_settings.json`:

{% highlight javascript %}
{
  "js/plugins/radio": {
    "pin": "1337"
  }
}
{% endhighlight %}

During the build process this file is copied to the device. On startup we can now load this file and combine it with the standard config to create a combined configuration that we can then send to architect using:

{% highlight javascript %}
// We still have |config| variable here
// We loaded the JSON file in |localSettings|

Object.keys(localSettings).forEach(function(k) {
  var conf = config.filter(c => c === k || c.packagePath === k)[0];
  if (conf && typeof conf === 'string') {
    conf.packagePath = conf;
  }
  if (conf) {
    Object.keys(localSettings[k]).forEach(function(subKey) {
      conf[subKey] = localSettings[k][subKey];
    });
  }
});
{% endhighlight %}

Now our combined config has the PIN code included as well. The `radio` plugin does not know anything about this. It just receives an options object that has a `pin` key with `1337`. Where it comes from does not matter.

## Overriding remote settings

Remote it's a bit harder. First, the device is always connected over a TCP or UDP socket to a [SimplePush](https://wiki.mozilla.org/WebAPI/SimplePush) server. This is a socket that will make sure to stay alive without killing the CPU's sleep cycle, which we do to avoid battery drain. After a push message comes in we ask the server for the remote config, because SimplePush does not support a payload on messages. In general this looks like:

* User changes config
* Server sends push message to device and wakes up
* Device queries server for new remote config

Now we have the new configuration and we store it in localStorage. The format is the same as the `local_settings.json` file and only contains values that the user changed himself. F.e. if you change the compression rate to 0.8 we store the following:

{% highlight javascript %}
{
  "js/plugins/camera": {
    "compression": 0.8
  }
}
{% endhighlight %}

We store this value in localStorage, and on startup, we do the same trick as with the local_settings file, and we combine everything into one big config file. Works fine!

Only problem is that changes only take effect whenever the device restarts. For this every plugin can implement an optional `updateOptions()` function, which looks somewhat like this:

{% highlight javascript %}
function updateOptions(newOptions) {
  if (options.compression !== newOptions.compression) {
    // update without rebooting
    options.compression = newOptions.compression;
    // make additional changes
    CompressionMagic.overrideCompression(options.compression);
    return true;
  }
}
{% endhighlight %}

We cannot magically update the option values because code will be dependent on this, so always go through an intermediate function. If we encounter any change that cannot be populated without a restart we can initiate a reboot after the config change but so far we have not have to go down this road. It would also add more risk. Rebooting is scary!
