---
layout: post
title:  "Building a smart meeting room w/ LoRa and Physical Web"
date:   2015-08-04 11:29:00
categories: iot
author: "Jan Jongboom"
tags: lora iot
comments: false
---

Ah! An empty meeting room. The moment you sit down however you're being kicked out by someone who apparently 'reserved' the damn thing, and you'll have to start your quest for some quiet working space all over again. Annoying. So when you're finally used to first checking the calendar for the room, you'll start to notice that there are people reserving rooms that they are not using at all!

As we see [smart suitcases](http://bluesmart.com/), [connected plants](http://www.parrot.com/usa/products/flower-power/), and [egg management devices](http://www.amazon.com/Minder-Wink-App-Enabled-Smart-Tray/dp/B00GN92KQ4) appear I was wondering why our meeting rooms are still so dumb. When companies are building 'smart' meeting rooms, they usually don't get further than just [hanging an iPad](https://robinpowered.com/) next to the entrance. It's time to create a proper smart meeting room.

<!--more-->

## Discoverability

As I said earlier there is two problems I'd like to solve. First, knowing whether an empty meeting room is going to be available; and second, knowing if a booked meeting room is actually used. The first issue can be solved quickly by looking in the meeting room calendar (which is hosted by Google Calendar in our Amsterdam & Oslo offices), but this is not preferable on mobile, as it requires syncing of all meeting room calendars, which then interferes with your normal agenda. The second problem is that it requires you to find the meeting room you're in front of, select specifically that calendar, and then manually type a new event. Clunky and not very fast.

To get around that I created a simple web application that binds into Google Calendar, and shows you whether the meeting room is booked. Plus with one click it allows you to book the room for 15, 30 or 60 minutes (depending on availability). The application is open source and available on [GitHub](http://github.com/janjongboom/meetingroom-web).

<img src="{{ site.baseurl }}/assets/meetingroom1.png" title="Fresh UI around Google Calendar">

*An alternative front end for Google Calendar, targeted at meeting rooms*

One click on the button and an appointment is created under your own name. Every meeting room gets it's own URL, that is bound to a [Google Calendar](https://github.com/janjongboom/meetingroom-web/blob/master/config/dev.json#L8). To solve around manually getting to a URL, and solve the discoverability issue, there is now [Physical Web](http://google.github.io/physical-web/), which allows you to broadcast a URL over Bluetooth Low Energy. So I got the [Nordic Semiconductors nRF51-DK](https://developer.mbed.org/platforms/Nordic-nRF51-DK/); a dev kit with a Cortex M0 and a Bluetooth chip on it, and programmed it to [broadcast the URL of the meeting room](https://developer.mbed.org/teams/Bluetooth-Low-Energy/code/BLE_PhysicalWeb/). Because the low power charactaristics of BLE, we can keep broadcasting for years on a coin cell. The meeting room is then discoverable through the Physical Web app on [Android](https://play.google.com/store/apps/details?id=physical_web.org.physicalweb&hl=en) and [iOS](https://itunes.apple.com/us/app/physical-web/id927653608?mt=8).

<img src="{{ site.baseurl }}/assets/meetingroom2.png" title="nRF51-DK broadcasting Physical Web URL, Android phone reading the beacon">

*nRF51-DK is broadcasting the URL, Android phone picking up the signal. The dev board actually runs of a coin cell and is easy to program through [ARM mbed](http://mbed.org/).*

## Detecting motion

Although this makes booking a lot easier, it can still happen that a room is booked, but no-one actually showed up. Wouldn't it be nice to have an indication whether there is actually something happening in the room? If no movement was generated in a booked room for 5 minutes, we can just take it.

Fortunately we can leverage the dev board for this too. For a few dollars you can buy a [PIR sensor](https://www.adafruit.com/products/189) that uses infrared to detect motion. The one I picked up in the local electronics store for 7 euro's has a viewport of ~110 degrees, which is more than enough for our meeting room. Also it doesn't have to be a perfect sensor, as just detecting movement once every few minutes is enough. The code is simple enough:

{% highlight c %}
InterruptIn motion(p7); // PIR sensor on digital pin 7
bool rise_state = false;
uint16_t last_rise = 0;

void riseHandler(void) {
  last_rise = rtc.time(); // from https://developer.mbed.org/users/fxschumacher/code/nRF51_rtc_example/
  rise_state = true;
}

void fallHandler(void) {
  last_rise = rtc.time();
  rise_state = false;
}

int main(void) {
  motion.rise(&riseHandler);
  motion.fall(&fallHandler);
}
{% endhighlight %}

Now the problem is how we can send the motion data to the web application. Protocols like cellular and WiFi are both overkill in bandwidth, as well as very battery inefficient.

## Broadcasting motion data

One of the techniques that we're working on, and that I'm very excited about is [LoRa](http://lora-alliance.org/). Kind of like a cellular network, specifically made for IoT purposes. Very low datarate, so made to transmit sensor data, but also very little battery usage and very long range (we got to 2km when testing in downtown Amsterdam). Perfect for what we're trying to achieve here.

As the dev board does not come with support for LoRa, you'll need to add a shield first. Unfortunately it's quite expensive at this time (80 euros), but if you'll make a lot of them you can use the raw chips and those are a lot cheaper (&lt; 10 euros). The [SX1276MB1xAS](https://developer.mbed.org/components/SX1276MB1xAS/) shield fits nicely on the Nordic board, and leaves you room to fit the PIR sensor in as well.

<img src="{{ site.baseurl }}/assets/meetingroom4.jpg" title="There is no way this is going to break. Ever.">

*nRF51-DK with SX1276MB1MAS LoRa shield and PIR sensor, running in one of our meeting rooms*

IBM has a nice [reference implementation](https://developer.mbed.org/teams/Semtech/code/LoRaWAN-lmic-app/) with LoRaMac-In-C, which handles most of the magic for you. Only thing left is to make sure we broadcast the data from the PIR sensor.

{% highlight c %}
// Make sure to adjust LORAWAN_APP_DATA_SIZE

static void prepareTxFrame( void )
{
  uint16_t seconds_ago = rtc.time() - last_rise;

  LMIC.frame[0] = 0x02; // Use first byte to specify sensor type (own protocol)
  LMIC.frame[1] = rise_state ? 1 : 0;
  LMIC.frame[2] = ( seconds_ago >> 8 ) & 0xFF;
  LMIC.frame[3] = seconds_ago & 0xFF;

  // Nice for debugging
  printf("prepareTxFrame %02x %02x %02x %02x\r\n",
      LMIC.frame[0], LMIC.frame[1], LMIC.frame[2], LMIC.frame[3]);

#if ( LORAWAN_CONFIRMED_MSG_ON == 1 )
  LMIC.frame[4] = LMIC.seqnoDn >> 8;
  LMIC.frame[5] = LMIC.seqnoDn;
  LMIC.frame[6] = LMIC.rssi >> 8;
  LMIC.frame[7] = LMIC.rssi;
  LMIC.frame[8] = LMIC.snr;
#endif
}
{% endhighlight %}

> For some reason I cannot get the device to broadcast both LoRa and BLE at the same time. If you have any idea what's wrong, please check [my question on the mbed forum](https://developer.mbed.org/questions/55586/LoRa-LMiC-Bluetooth-Low-Energy-in-one-mb/).

### Receiving the signal

Now that we're broadcasting, we'll need a way of receiving the signal. If there's no LoRa provider around you yet, or when you don't trust other parties with your data, you'll need a base station. There are [big, commercial ones](http://www.kerlink.com/en/products/lora-iot-station) (&gt; 1200 euros) that we have in Oslo, but in Amsterdam I decided to [build my own](http://openlora.com/forum/viewtopic.php?t=25) with a Raspberry Pi 2 and an IMST iC880A module.

<img src="{{ site.baseurl }}/assets/meetingroom3.jpg" title="A quarter the cost, four times as fun!">

*Self built LoRa gateway based on Raspberry Pi 2 and iC880A. Total cost ~300 euro's.*

A gateway is not cheap, but the nice thing is that (if you have one of the big ones) you'll just need one or two to cover your whole office building. The biggest advantage of course is that the device that gathers your data (like our motion sensor) can just run of battery.

On the gateway I run Semtech's [packet-forwarder](https://github.com/Lora-net/packet_forwarder), which just grabs all incoming data and forwards it to one of our servers. I then pump the data into [2lemetry/ThingFabric](http://2lemetry.com/iot-platform/), and [read the data back](https://github.com/janjongboom/meetingroom-web/blob/master/server.js#L230) in the web app. Tah dah, full circle!

<img src="{{ site.baseurl }}/assets/meetingroom5.png" title="Data ends up over MQTT in ThingFabric">

*The data flowed from the sensor, over LoRa, to our base station, to ThingFabric, ready to be consumed.*

## Conclusion

It took me about three days to do this whole setup from scratch, including building the gateway and the web app, and it shows how easy it is to build connected devices that actually solve a problem in the office.

The coolest thing for me however, is that it'd be possible to run the entire setup on a small battery. Both BLE and LoRa are made to be very, very power efficient, and we only need readings from the PIR sensor every few seconds. Combine that with sending data over LoRa, and we have a device that does not need cables, and just needs to swap the coin cell every few months. Awesomness.

<a href="https://twitter.com/janjongboom" class="twitter-follow-button" data-show-count="false" data-size="large">Follow @janjongboom</a>
<script>!function(d,s,id){var js,fjs=d.getElementsByTagName(s)[0],p=/^http:/.test(d.location)?'http':'https';if(!d.getElementById(id)){js=d.createElement(s);js.id=id;js.src=p+'://platform.twitter.com/widgets.js';fjs.parentNode.insertBefore(js,fjs);}}(document, 'script', 'twitter-wjs');</script>
