---
layout: post
title:  "Enhancing your webcam using canvas.captureStream()"
date:   2017-01-05 12:00:00
author: "Sigve Sebastian Farstad"
tags: Zombocam WebRTC Technology Javascript
comments: true
---

<div style='position:relative; padding-bottom:57%'><iframe src='https://gfycat.com/ifr/DeterminedLightFerret?referrer=https%3A%2F%2Fmedium.com%2Fmedia%2F52bf1361cb0f67e59a11d67c281361ef%3FpostId%3Dc71e3dca9176' frameborder='0' scrolling='no' width='100%' height='100%' style='position:absolute;top:0;left:0;' allowfullscreen></iframe></div>
<br/>

*This blog post is also available on [Medium](https://medium.com/@zombocam/enhancing-your-webcam-using-canvas-capturestream-c71e3dca9176#.fcu6yn4ft)*

Recently, [HTMLCanvasElement.captureStream()](https://developer.mozilla.org/en-US/docs/Web/API/HTMLCanvasElement/captureStream) was implemented in browsers.
This allows you to expose the contents of a HTML5 canvas as a [MediaStream](https://developer.mozilla.org/en-US/docs/Web/API/Media_Streams_API) to be consumed by applications.
This is the same base MediaStream type that [getUserMedia](https://developer.mozilla.org/en-US/docs/Web/API/MediaDevices/getUserMedia) returns, which is what websites use to get access to your webcam.

The first question that comes to mind is, of course:
*“Is it possible to intercept calls to getUserMedia, get a hold of the webcam MediaStream, enhance it by rendering it into a canvas and doing some post-processing, then transparently returning the canvas’ MediaStream?”*

As it turns out, the answer is yes.

We built a cross-platform [WebExtension](https://developer.mozilla.org/en-US/Add-ons/WebExtensions) called [Zombocam](https://www.zombocam.com) that does exactly this.
Zombocam injects itself on every webpage and monkey-patches getUserMedia.
If a webpage then calls getUserMedia, we transparently enhance the camera and spawn a floating UI in the DOM that lets you control your different filters and settings.
This means that any website that uses your webcam will now get your enhanced webcam instead!

This blog post is a technical walk-through of the different challenges we ran into while developing Zombocam.


# Monkey-patching 101

Monkey-patching getUserMedia essentially means replacing the browser’s implementation with our own.
We supply our own getUserMedia function that wraps the browser’s implementation and adds an intermediary canvas processing step (and fires up a UI).
Of course, since getUserMedia is a web JS API, there are one million different versions that need to be supported.
There’s Navigator.getUserMedia and MediaDevices.getUserMedia, and then vendor prefixes on top of that (e.g. Navigator.webkitGetUserMedia and Navigator.mozGetUserMedia), and then there are different signatures (e.g. callbacks vs promises), and then on top of that again they historically support different syntaxes for specifying constraints.
Oh, and they have different errors too.
To be fair, MediaDevices.getUserMedia, the one true getUserMedia, solves all of these problems, but the web needs to wait for everyone to stop using the old versions first.


<div style='position:relative; padding-bottom:42%'><iframe src='https://gfycat.com/ifr/ColorlessGeneralAmericanwarmblood?referrer=https%3A%2F%2Fmedium.com%2Fmedia%2F0a29e31aa391394e50088082839f0f9f%3FpostId%3Dc71e3dca9176' frameborder='0' scrolling='no' width='100%' height='100%' style='position:absolute;top:0;left:0;' allowfullscreen></iframe></div>
<br/>

All of this boils down to having to type a lot of code to iron over the inconsistencies between different implementations, but in the happy case we end up with something like:


<script src="https://gist.github.com/sigvef/6e5a04c0974e2418f1b10c6b11a79d77.js"></script>

# The rendering pipeline

Most of the effects and filters in Zombocam are implemented as [WebGL](https://developer.mozilla.org/en-US/docs/Web/API/WebGL_API) fullscreen quad shader passes.
This is a WebGL rendering technique that essentially lets us generate images on the fly on a per-pixel basis by using a fragment shader.
This is elaborated upon in thorough detail in [this excellent article](https://blog.mayflower.de/4584-Playing-around-with-pixel-shaders-in-WebGL.html) by Alexander Oldemeier.
Using this technique means that the image processing can be done on the GPU, which is essential to achieve smooth real-time performance.
For each video frame, the frame is uploaded to the GPU and made available to an effect’s fragment shader, which is responsible for implementing the specific transformation for that effect.

<script src="https://gist.github.com/sigvef/cc5f6997000cf1c9a0aad6b1fd3e0425.js"></script>

Effects in Zombocam are split into three main categories: color filters, distortion effects and overlays.
Filters in the first categories are implemented as non-linear per-channel functions with hard-coded mappings of input to output values in each frame.
The idea is that a color grading expert creates a nice-looking preset using his or her favorite color grading tool.
Then that color grading is applied to three 0–255 gradients, one for each color channel.
The color graded outputs then serve as lookup tables for the pixel values in order to create a color graded output.
This is a simplified version of the technique elaborated upon in [this excellent article](http://www.slickentertainment.com/tech/dev-blog-128-color-grading-another-cool-rendering-trick/) by Slick Entertainment.

Distortion effects are implemented as non-linear pixel coordinate transformation functions on the input image.
That is, the pixel at coordinate (x, y) in the transformed image is copied from the pixel at coordinate f(x, y) in the original image.
As long as you define f correctly, you can implement swirls, pinches, magnifications, hazes and all sorts of other distortions.

Finally, overlay effects simply overlay new pixels on parts or all of the frame.
These new pixels can be sourced from anywhere, including other video sources.
This effectively lets us overlay Giphy videos directly in the camera stream!
Productivity will never be the same.

Since effects can be chained in Zombocam, the output from one effect’s rendering pass is fed directly as input to the next effect’s rendering pass.
This opens for a wide array of different possible effect combinations.


<img src="/images/zombocam1.png" alt="Zombocam can turn you into a cyclops if you’re not careful when chaining effects!"/>
<br/>

# Works everywhere! (\*)

In theory, this approach works everywhere out of the box, so you can use when you’re snapping a profile picture on [Facebook](https://facebook.com), hanging out in video meetings on [Appear.in](https://appear.in) or [Google Hangouts](https://hangouts.google.com).
In practice, however, the story is a little more nuanced.
Reliably monkey-patching getUserMedia in time in a cross-browser fashion via injection from a WebExtension without going overboard with permissions turns out to be hard in some cases.
This means that if an application is really adamant at calling getUserMedia reeeally early in the page’s lifetime, getUserMedia might not be monkey-patched yet.
In that case, Zombocam will simply never trigger, and it will be as if it weren’t ever even installed.

When attempting to transparently monkey-patch APIs one has to take extreme care to make sure that the monkey-patching actually is transparent.
That means properly forwarding all sorts of properties on the Streams and Tracks returned from getUserMedia that applications might expect and depend on.

One specific example of this that we ran into was with [Appear.in’s new premium offering](https://appear.in/information/premium/), where you can screen-share and show your webcam stream in your meeting room at the same time.
The application relied on the name of one of the Tracks to be “Screen”, which we didn’t properly forward to our Tracks that we got from our canvas.
Because of this, Appear.in didn’t know which of the tracks was the screen-sharing track, and things stopped working.
Properly forwarding the name property solved the issue, and we learned an important lesson in the virtues of actually being transparent when trying to transparently intercept APIs.

# What's next: audio filters

With the new release of [Zombocam](https://www.zombocam.com) we’ve taken it one step further and enhanced getUserMedia audio tracks as well using the [Web Audio API](https://developer.mozilla.org/en-US/docs/Web/API/Web_Audio_API).
More on that in a later blog post!
