---
layout: post
title:  "Power consumption"
date:   2014-12-05 17:03:12
categories: gonzo hardware
author: "Jan Jongboom"
project: Gonzo
---

My idea for [Gonzo]({{ site.baseurl }}/about-gonzo/), from the very moment the idea sparked in my head last September (although that's another story), was that we should aim for insane battery life. I want people to put up their Gonzo at hard to reach places without them having to worry to charge the device every week. That means that power consumption was our biggest concern when we started doing this project. How do you keep a device alive for at least a month? How much battery do we need to fulfill all our wishes, etc? The first thing we (and by we, I actually mean Thomas) did to achieve this goal was to set up proper power measurement equipment. A nice thing about reusing existing hardware is that a big portion of the work was already done for us by Mozilla engineer [Jon Hylands](https://github.com/JonHylands). For power measurement you need a (3D printed) harness, a PCB to connect battery and main board, a power meter, and some software to read the data from the meter. All of that was already written up by Jon in a blog post on [Mozilla Hacks](https://hacks.mozilla.org/2014/04/measuring-power-consumption-on-phones/).

Although building the harness was easily done by Bjørn (it even fitted the battery for the Geeksphone Keon the very first time), we didn't have any PCBs until two weeks later, so our first power measurement tool was professionaly soldered together by Thomas.

<!--more-->

![Power measurement]({{ site.baseurl }}/assets/power-measurement.jpg)

In essence, Gonzo executes three actions throughout its lifetime that consume power:

1. Be idle, just connected over 2G to the network
2. Take a photo
3. Upload a photo

Depending on the configuration of the device these actions happen every X seconds, and run for Y time, during which they consume Z power. The Geeksphone Keon board, which was the first board we tested, consumes 9 mA (rounded) when idle, 131 mA for 2 seconds while taking a photo, and (non-EDGE network) takes 13 seconds to upload a full photo at 140 mA. Our idea for Gonzo is to (when no-one is watching) is to take a photo every 2 minutes, but our assumption is that only one in five photo's will need to be uploaded by using a good diff algorithm and by throwing away dark photos (Gonzo does not have night vision goggles). Using that we can do some basic math to calculate the power consumption of the device.

In a 10 minute cycle, we spend: 10s making photos at 131 mA; 13s uploading at 140 mA; 577s at 9 mA idle'ing. Averaging at:

    ((10/600) * 131) + ((13/600) * 140) + ((577/600) * 9) = 13.9 mA

For a Gonzo to run for one month, we therefore need a (24 \* 30 \* 13.9) = 10.008 mAh battery. Which would be pretty massive but doable. There are already power banks that deliver this that retail for [about 10 USD](http://www.mi.com/sg/mipowerbank10400/). Biggest issue would be the space in the casing.

However we don't want to use the Keon as a production board, as it's a bit too expensive and also supports 3G that we don't need. In the end we will probably go for the Spreadtrum SC6821, which also powers the 25$ phones in India. Unfortunately we don't have the spec sheets, so we had to rely on manual power measurements here as well. Interesting fact is that the only device we had was a pre-production model without an IMEI number. Phones without IMEI are banned from using 3G networks, but there is no such check for 2G.

For the SC6821 the numbers are quite better when idle'ing, although we have big difference between measurements at the Telenor office in Trondheim (which are probably near-ideal condiditions) and near Thomas's house (which are probably pretty bad). At the office we get around 4.6 mA, and at Thomas around 7.5 mA. The difference increased a lot when we also kept a SimplePush socket open, bringing consumption up to over 12 mA at Thomas, but not changing at all in the office. If the socket will increase power consumption this much in non-ideal conditions we will probably use something else, like SMS, so let's calculate with the non-socket numbers.

Another difference is consumption of camera & upload. This totalled at around 240-270 mA for the same 2+13 seconds, which is quite the difference with the Keon. If we want to bring this device into production we would need to bring this drastically down. For the same scenario as described above we consume:

    Office:
    ((10/600) * 255) + ((13/600) * 255) + ((577/600) * 4.6) = 14.2 mA = 10.224 mAh

    Thomas:
    ((10/600) * 255) + ((13/600) * 255) + ((577/600) * 7.5) = 17.0 mA = 12.240 mAh

These numbers would make it impossible to achieve our battery goal with Gonzo, so a lot depends whether we can get lower consumption for uploading and making the photos. Hopefully we get access to the spec sheets at some point and figure out a way to get the low power consumption of the SC6821 and the photo/upload consumption of the Keon. That would give us a required battery of 7.000 - 9.000 mAh, which should be doable. So we made quite some progress but a lot of details to iron out!
