---
layout:   post
title:    "Video: Solving connectivity for the Internet of Things"
date:     2015-12-08 19:46:00
author:   "Jan Jongboom"
tags:     iot
categories: video
comments: false
---

<a href="http://presenter.qbrick.com/?pguid=cb3beeba-fe2f-43a9-9e4d-690ec3572476" target="_blank"><img src="{{ site.baseurl }}/assets/connectivity-iot1.jpg" title="I totally didn't spend 10 minutes to find a picture where I looked intelligent"></a>

*Click the image above to start playing the video*

<!--more-->

---

During the Telenor Technology Fair last month, I (Jan Jongboom) gave a talk about connectivity and IoT, a subject which I'm dealing with in my day-to-day job. We'll go over the current issues with connecting smart devices, promising new technologies, and our experiences making the Telenor office in Fornebu (Oslo) smart. It's also a tale of how telco's need to transform if they want to be part of the IoT movement.

If you don't like video, the slides and outline are listed below.

## Slides

<iframe src="//www.slideshare.net/slideshow/embed_code/key/12NDzlaepmpv2s" width="100%" height="450" frameborder="0" marginwidth="0" marginheight="0" scrolling="no" style="border:1px solid #CCC; border-width:1px; margin-bottom:5px; max-width: 100%;" allowfullscreen> </iframe>

## Outline

- Jan Jongboom, part of CTO Office, focusing on Internet of Things
- IoT in Digital is spread out
    - Four different teams working on variety of aspects.
- Interesting part: all aligned goals, all ended up at the same problem.
- When connecting devices, two choices: long range, or long battery life. Pick one.
- Long range: traditional cellular tech. 2G. Battery life of a week.
- Short range: variety of choices, bluetooth, zigbee, etc. Range at most 100 meters.
- If we want to do this 'IoT' thing, connecting sensors, we need to do better. Bandwidth doesn't matter for the first time.
- Can we do better? Yes!
- Variety of new tech is coming out. All same principle:
    - Sub-GHz spectrum (868 MHz in Norway, free spectrum)
    - No gateway pinning
    - Big antenna picking out the signals
- Results: penetrates buildings, walls, etc. Range of 2 kilometers in downtown Oslo (from Olav's balcony to the library), 10-15 kilometers in open field
- Only draws power when emitting data, perfect for sensors. (e.g. send temperature measurement every 15 minutes)
- Variety of vendors: LoRa, Sigfox, Siglo, Weightless-N

### LoRa

- Can enable completely new business models: better be part of it...
- Our choice: LoRa.
    - Available today for relative low cost. Gateways 1200, end-device chips 6, complete PIR sensor we bought is 30.
- First project: Telenor Eiendom
    - Making Fornebu smart with 400 sensors
        * It's a pilot with internal customer. Let's build some own sensors. 
        * 100 of these developed internally. 300 bought from external party.
        * Build up hardware competency in Digital.
    - Flex-desk availability rates, monitoring temperature, counting toilet usage, push button to indicate problems
    - Using LoRa we only need 2 gateways on the top of building, nothing else. Just buy the sensors and deploy
    - Integration with facility management system MCS to auto-dispatch coffee repairmen / women
- Lot of initial work
    - Gateways are available, but they are dumb
    - Just scan spectrum for messages, forward the data, but to where?
        - Traditional model, buy service from Huawei or something
        - This is the new decade, The Things Network can solve this efficiently w/o waiting for telcos
    - Instead of buying it, let's build it ourselves

### Technology stack

- Multiple basestations will receive the data (no gateway-pinning)
- Forward to network. All logic in here: de-duplicating, adjusting data-rate, join'ing, verifying, etc.
- Also encryption, as all messages are end-to-end encrypted, gateway cannot do MITM.
- Took the demo-implementation from Semtech (company behind LoRa), and went building on top of it.
- Now:
    - Comes into network
    - Routing the messages through AWS IoT
    - Store data into DynamoDB
    - Subscribe to live-feed f.e. to create calls in facility management system, or use historic data to analyse when desk was used.
- Our problem is not unique. Private site, private network. No telco required. But it's a lot of work on the tech site.

### Lora Network Server

- Take our learnings and enable anyone to take advantage of them.
- Network Infrastructure as a service. You bring gateways and devices, we handle everything from device onboarding to historic data APIs.
- Telenor LPWA (working title): create private network with the push of a button.
- Telenor Eiendom's network is already running on it. Can open this up to anyone. E.g. Telenor Norway, but also DNB HQ f.e.
- Live at http://lora.cloud.tcxn.net:1880/
- Additional benefit: we can route messages for other networks through any gateway that's part of LPWA (regardless of branding): building a big Digital network around the world.

### Next steps

- The Fornebu network is open through Telenor LPWA
- Read f.e. http://blog.telenor.io/iot/2015/08/04/smart-meetingroom.html, get a device and register, it's pretty simple.
    - Trondheim team happy to help out when you want to take it further.
- Get your data out of the system and start hacking something cool!
- Thank you

---

*Jan Jongboom is a Strategic Engineer for Telenor Digital, working on the Internet of Things.*

<a href="https://twitter.com/janjongboom" class="twitter-follow-button" data-show-count="false" data-size="large">Follow @janjongboom</a>
<script>!function(d,s,id){var js,fjs=d.getElementsByTagName(s)[0],p=/^http:/.test(d.location)?'http':'https';if(!d.getElementById(id)){js=d.createElement(s);js.id=id;js.src=p+'://platform.twitter.com/widgets.js';fjs.parentNode.insertBefore(js,fjs);}}(document, 'script', 'twitter-wjs');</script>
