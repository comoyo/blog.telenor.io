---
layout: post
title:  "Changing Firefox MediaStreams to accommodate cloning"
date:   2016-04-29 09:15:00
categories: webrtc
author: "Andreas Pehrson"
tags: webrtc Firefox
comments: false
---

This article explains how [MediaStreams](http://w3c.github.io/mediacapture-main/getusermedia.html#mediastream) work in Firefox and the changes I did to them to accommodate cloning.

First of all. What is a [MediaStreamTrack](http://w3c.github.io/mediacapture-main/getusermedia.html#mediastreamtrack), and how can you clone it?

A MediaStreamTrack represents a realtime stream of audio or video data.

It provides a common API to the multiple producers ([getUserMedia](http://w3c.github.io/mediacapture-main/getusermedia.html#dom-mediadevices-getusermedia), [WebAudio](https://webaudio.github.io/web-audio-api/), [Canvas](https://html.spec.whatwg.org/multipage/scripting.html#the-canvas-element), etc.) and consumers ([WebRTC](http://w3c.github.io/webrtc-pc/), WebAudio, [MediaRecorder](http://w3c.github.io/mediacapture-record/MediaRecorder.html), etc.) of MediaStreamTracks.

A MediaStream is simply put a grouping of MediaStreamTracks. A MediaStream also ensures that all tracks contained in it stay synchronized to each other, for instance when it gets played out in a [media element](https://html.spec.whatwg.org/multipage/embedded-content.html#media-elements).

Cloning a track means that you get a new MediaStreamTrack instance representing the same data as the original, but where the identifier is unique (consumers don't know it's a clone) and disabling and stopping works independently across the original and all its clones.

Now, how does all this come together in Firefox?

<!--more-->

---

### My Background

For the last year and a half, I have been representing Telenor in the [WebRTC Competency Center that Mozilla announced back in 2014](https://blog.mozilla.org/blog/2014/12/09/mozilla-and-telenor-announce-webrtc-competency-center-to-advance-webrtc-and-help-standardization/). The WebRTC Competency Center is a project where we as participants work together with Mozilla on driving the Firefox WebRTC stack and the relevant standards forward.

I'll also mention in passing, that the WebRTC Competency Center is getting a refresh in the shape of a new website and a name update later this year! Stay tuned for more info on this in the next couple of months. Both from Telenor and Mozilla.

Most of my work so far in this context has been on features and bug fixes in and around the MediaStream and MediaStreamTrack implementation. For instance I fixed [transmitting WebAudio tracks over RTCPeerConnections](https://bugzilla.mozilla.org/show_bug.cgi?id=1081819), [the "resize" event for media elements](https://bugzilla.mozilla.org/show_bug.cgi?id=992685), [capturing a canvas to a MediaStream](https://bugzilla.mozilla.org/show_bug.cgi?id=1032848), [MediaStream constructors](https://bugzilla.mozilla.org/show_bug.cgi?id=1070216), [`MediaStream.addTrack()` and `removeTrack()`](https://bugzilla.mozilla.org/show_bug.cgi?id=1103188) and [many many bug fixes](https://bugzilla.mozilla.org/buglist.cgi?emailtype1=substring&emailassigned_to1=1&email1=pehrsons&resolution=FIXED&query_format=advanced&product=Core&list_id=12986111).

Recently I landed a huge rewrite - [105 patches in one go](https://bugzilla.mozilla.org/show_bug.cgi?id=1208371) - rerouting most of the main thread communications between streams and their sources and sinks, leading to finally enabling [`MediaStream.clone()`](http://w3c.github.io/mediacapture-main/getusermedia.html#widl-MediaStream-clone-MediaStream) and [`MediaStreamTrack.clone()`](http://w3c.github.io/mediacapture-main/getusermedia.html#widl-MediaStreamTrack-clone-MediaStreamTrack) in Firefox 48.

### Outline

Since this article gets rather lengthy, here's an outline so that you can skip directly to the pieces that you find most interesting.

- [TL;DR What does this mean for me?](#tldr)
- [Explaining the MediaStreamGraph](#msg-explained)
- [The old stream-centered way](#stream-centered)
- [MediaStreamGraph has been taught what tracks are](#msg-tracks)
- [We have MediaStreamTrackSources now](#track-sources)
- [Security needs to be track-centered](#security)
- [Fixing tricky intermittent bugs - and some perf issues](#intermittents)

### <a name="tldr"></a> TL;DR What does this mean for me?

Before you dive in, take a look at the jsfiddle below showing track cloning in action. The feature was just released as Firefox 48 became Developer Edition. Make sure you're on Developer Edition for the latest features!

Once you've gotten your gUM (short for getUserMedia()) camera feed going, you can click the "Clone it 100 times!" button and if track cloning is supported by your browser, a second video should appear, playing back the 100th clone of the original VideoStreamTrack. The clone can now be disabled and stopped independently from the original.

Try it yourself!

<div style="height:300px;">
<iframe src="https://jsfiddle.net/pehrsons/tx4dfhcp/embedded/js,html,result/" frameborder="0" height="100%" width="100%"></iframe>
</div>

### <a name="msg-explained"></a> Explaining the MediaStreamGraph

Gecko's (the Firefox browser engine) MediaStream and MediaStreamTrack implementation largely has two parts: a main thread API - much of which is exposed to javascript, and an internal [MediaStreamGraph](https://dxr.mozilla.org/mozilla-central/rev/fc15477ce628599519cb0055f52cc195d640dc94/dom/media/MediaStreamGraph.h#1444) which processes media data on a background thread. The main thread APIs communicate with the MediaStreamGraph through message passing to achieve largely lock free inter-thread communication.

The MediaStreamGraph is the central engine for MediaStreams in Gecko. It is easiest explained as a mapping of how all streams and tracks are connected to each other, and on every iteration (typically ~10ms but it depends on how often the operating system calls its audio callback) it goes through all tracks to ensure they contain data for the current time.

There are three main types of internal streams used by the MediaStreamGraph:

- [SourceMediaStream](https://dxr.mozilla.org/mozilla-central/rev/55d557f4d73ee58664bdf2fa85aaab555224722e/dom/media/MediaStreamGraph.h#722)
    - Raw data either gets pushed to the source stream by a producer or pulled in by the MediaStreamGraph.
- [TrackUnionStream](https://dxr.mozilla.org/mozilla-central/rev/55d557f4d73ee58664bdf2fa85aaab555224722e/dom/media/TrackUnionStream.h#17)
    - Consists of tracks coming from other SourceMediaStreams or TrackUnionStreams.
- [AudioNodeStream](https://dxr.mozilla.org/mozilla-central/rev/55d557f4d73ee58664bdf2fa85aaab555224722e/dom/media/webaudio/AudioNodeStream.h#34)
    - A stream for a WebAudio node. Most WebAudio nodes are built on top of this stream. This is not used directly by a MediaStream but can be exposed as a TrackUnionStream through a special MediaStreamAudioDestinationNode.

A regular MediaStream (the JS object) is backed by three internal streams in the MediaStreamGraph:

- A SourceMediaStream or a TrackUnionStream as *input* stream
- A TrackUnionStream for denoting tracks that are native to the MediaStream in question, the *owned* stream
- A TrackUnionStream where only the currently active tracks in the MediaStream are present, the *playback* stream

What do I then mean by tracks that are *native to the MediaStream in question*?

Consider a call like `getUserMedia({ audio: true, video: true })`. It will result in a MediaStream with one AudioStreamTrack and one VideoStreamTrack. Both these tracks are native to this MediaStream. If I later `removeTrack()` the audio track and `addTrack()` another, external, track the original two tracks will still be native to the MediaStream, and the added track will not. This means that the original video track and the added track will be available in this MediaStream's internal playback stream.

For a visual representation of this setup, consider the following ASCII drawings, [straight from the codebase](https://dxr.mozilla.org/mozilla-central/rev/fc15477ce628599519cb0055f52cc195d640dc94/dom/media/DOMMediaStream.h#138). Never mind that they're called *DOMStream* in the drawings. That's a legacy naming convention in Gecko. They're regular MediaStreams.


This is a simple case where we have done `A.addTrack(B.getTracks([0]))`:

```
 DOMStream A
           Input        Owned          Playback
            t1 ---------> t1 ------------> t1     <- MediaStreamTrack X
                                                     (pointing to t1 in A)
                                 --------> t2     <- MediaStreamTrack Y
                                /                    (pointing to t1 in B)
 DOMStream B                   /
           Input        Owned /        Playback
            t1 ---------> t1 ------------> t1     <- MediaStreamTrack Y
                                                     (pointing to t1 in B)
```


Here another simple case where we remove the only track in a stream, like `A.removeTrack(A.getTracks(0))`:

```
 DOMStream A
           Input        Owned          Playback
            t1 ---------> t1                      <- No tracks
```


When cloning a track, you're supposed to get a completely different instance from the original. This instance has a new unique identifier and can be stopped and disabled independently from the original or any other clones of the same track (a clone of a clone is no different than a clone of an original). The way this is set up is by having a link from the original MediaStream's internal *input* stream, to the internal *owned* stream of the clone, with stopping and track disabling happening on that same link.

Here it is visualized in its simplest form. `B = A.clone()`:

```
 DOMStream A
           Input        Owned          Playback
            t1 ---------> t1 ------------> t1     <- MediaStreamTrack X
               \                                     (pointing to t1 in A)
                -----
 DOMStream B         \
           Input      \ Owned          Playback
                       -> t1 ------------> t1     <- MediaStreamTrack Y
                                                     (pointing to t1 in B)
```


Ok, all those were quite easy. To finish it off, I have one case where these methods have been combined like so:

```
 var A = someStreamWithTwoTracks;
 var B = someStreamWithOneTrack;
 var X = A.getTracks()[0];
 var Y = A.getTracks()[1];
 var Z = B.getTracks()[0];
 A.addTrack(Z);
 A.removeTrack(X);
 B.removeTrack(Z);
 var A' = A.clone();
```


This results in the following graph:

```
 DOMStream A
           Input        Owned          Playback
            t1 ---------> t1                      <- MediaStreamTrack X (removed)
                                                     (pointing to t1 in A)
            t2 ---------> t2 ------------> t2     <- MediaStreamTrack Y
             \                                       (pointing to t2 in A)
              \                    ------> t3     <- MediaStreamTrack Z
               \                  /                  (pointing to t1 in B)
 DOMStream B    \                /
           Input \      Owned   /      Playback
            t1 ---^-----> t1 ---                  <- MediaStreamTrack Z (removed)
              \    \                                 (pointing to t1 in B)
               \    \
 DOMStream A'   \    \
           Input \    \ Owned          Playback
                  \    -> t1 ------------> t1     <- MediaStreamTrack Y'
                   \                                 (pointing to t1 in A')
                    ----> t2 ------------> t2     <- MediaStreamTrack Z'
                                                     (pointing to t2 in A')
```

As simple as pie!

### <a name="stream-centered"></a> The old stream-centered way

Until now, everything has been centered around streams, including the assumption that a stream contains at most one video track and one audio track. This works fine for basic getUserMedia streams, but doesn't cater for complicated cases where you want to combine multiple tracks from different sources, like screen capture, camera capture, WebAudio destination nodes, canvas and media element capturing.

Other assumptions were:

- All tracks in a stream come from the same source. Security wise ([cross-origin](https://www.w3.org/TR/cors/) access) we only have to care about that source. And it won't change throughout the lifetime of the stream.
- Any consumer of a stream (or track) has to use a [MediaStreamListener](https://dxr.mozilla.org/mozilla-central/rev/fc15477ce628599519cb0055f52cc195d640dc94/dom/media/MediaStreamGraph.h#103) (internal class) for data access, inadvertently getting notified about the activity of all tracks in the stream it is attached to. While this made sense for APIs that want all the tracks, it is now much more track centered, see for instance [MediaStreamAudioSourceNodes](https://webaudio.github.io/web-audio-api/#MediaStreamAudioSourceNode) and [RTCPeerConnections](http://w3c.github.io/webrtc-pc/#rtcpeerconnection-interface). An example of an API that accepts streams is MediaRecorder, though its spec doesn't mention how to treat added and removed tracks much.

### <a name="msg-tracks"></a> MediaStreamGraph has been taught what tracks are

As mentioned in [Explaining the MediaStreamGraph](#msg-explained) we have links between internal streams. These used to always forward all tracks that were live in the input stream. The MediaStreamGraph now has the ability to forward single tracks between streams. This basically makes tracks first class citizens in the stream graph.

We also used to have a MediaStreamListener class for listening to changes and new data for a stream. We now have a [MediaStreamTrackListener](https://dxr.mozilla.org/mozilla-central/rev/fc15477ce628599519cb0055f52cc195d640dc94/dom/media/MediaStreamGraph.h#300) class that can listen to data represented by a single MediaStreamTrack. This could in essence be achieved before by using a MediaStreamListener on the internal *owned* stream while filtering on a track's TrackID (identifying a track in an internal stream) but now we can avoid those extra cycles by only raising events for the track in question.

APIs that take tracks instead of streams can listen to only the tracks it needs and don't have to worry about those tracks being removed from their parent stream, clones, etc.

### <a name="track-sources"></a> We have MediaStreamTrackSources now

I implemented a general interface of a [MediaStreamTrackSource](https://dxr.mozilla.org/mozilla-central/rev/fc15477ce628599519cb0055f52cc195d640dc94/dom/media/MediaStreamTrack.h#46) through which all MediaStreamTrack instances can communicate with their respective sources. A track shares its MediaStreamTrackSource instance with all of its clones.

Previously there was a special MediaStream sub-class for getUsermedia streams that allowed methods like [`applyConstraints()`](http://w3c.github.io/mediacapture-main/getusermedia.html#widl-MediaStreamTrack-applyConstraints-Promise-void--MediaTrackConstraints-constraints) to be called from a getUserMedia track up to the proper source. This would naturally not work if that track is contained in another MediaStream type (like the generic one, MediaStream). Now with MediaStreamTrackSources we have generic access to the source from all tracks, and they don't have to go through a MediaStream on the way. All sources simply have to implement applyConstraints in some way. Most sources ignore it since it doesn't apply, but for getUserMedia sources it gets applied appropriately.

Similarly, we do the same forwarding to the source of calls like [`stop()`](http://w3c.github.io/mediacapture-main/getusermedia.html#widl-MediaStreamTrack-stop-void) (after all clones have been stopped), and various other internal methods.

### <a name="security"></a> Security needs to be track-centered

To fully understand this section, we need to understand what principals are.

A principal is a representation of an origin, so we can check if a consumer is allowed access to a particular producer's data, by checking if the producer's principal *subsumes* the consumer's principal. It's also worth knowing that there are system principals - elevated principals used by for instance browser chrome code  For more info on principals, see the [script security page on Mozilla's developer network](https://developer.mozilla.org/en-US/docs/Mozilla/Gecko/Script_security#Security_checks).

Being stream-centered like we used to, a stream would be tied to the [origin](https://tools.ietf.org/html/rfc6454#section-3.2) within which it was created. If you added a track from another origin to it we'd combine the principal from the added track into the stream's current principal, upgrading it to the system principal if needed. If the same track was removed again, we wouldn't touch the principal. Should we have done so, we would probably have leaked real data because the track removal operation happens on main thread, and it would take a bounce of message passing to the MediaStreamGraph (and an iteration) and a bounce back to main thread, to actually get new media data to apply. During these two bounces the current data would be protected by a downgraded principal - hence we never downgraded it.

What I have implemented now is a system where we send the principal (main thread only) from the track source to the MediaStreamGraph, which then notifies the MediaStreamTrack when a new principal has been applied. In summary this allows us to do the following:

- When the source of a MediaStreamTrack changes its principal, for instance a 2d canvas that we drew a cross-origin image to or a media element backed by a [MediaSource](http://w3c.github.io/media-source/) played a chunk from another origin, we'd first combine the new principal with the old (could be an upgrade or a downgrade), and only when we have confirmation from the MediaStreamGraph that the new principal has been rendered, would we apply the new principal completely.
- On adding a track to a stream, we immediately combine the new track's principal into the stream's. We also keep around a second principal for the stream, which is solely for its video tracks - this for APIs that only want to access video content of the stream, for instance when you draw a media element playing a stream onto a canvas.
- On removing a track from a stream, we keep returning the old principal (we keep the removed track's principal in a set of *tracks pending removal*) until the MediaStreamGraph has confirmed that we have now rendered another principal.

### <a name="intermittents"></a> Fixing tricky intermittent bugs - and some perf issues

All patches that cause major refactoring or changes in timing internally in the process tend to cause intermittent failures in automation.

After all the things above had been implemented we noticed how some automated tests started timing out, especially on platforms that were running on virtual machines. This wouldn't be reproduced on a similar setup on a local virtual machine either, a characteristic many of these intermittents share. [This particular performance issue](https://treeherder.mozilla.org/#/jobs?repo=try&revision=1678e9b22fa0) turned out to happen when sending a disabled screensharing-frame over an RTCPeerConnection. The fact that it was disabled was interesting and eventually pointed to two things:

- Frames going to be sent over an RTCPeerConnection did image format conversion if needed on the MediaStreamGraph thread (stalling the MSG in the worst case).
- Disabled frames had a separate buffer allocated and written to each time they came through - also on the MediaStreamGraph thread.

It was actually the latter case above that caused problems on this virtual machine. The allocation (screensharing frames tend to be high resolution!) took longer than a MediaStreamGraph iteration had budgeted. This lead to a much longer queue of frames to process on the next iteration, and then longer, and then longer, until we ran out of memory.

This was fixed by doing multiple things:

- [Don't queue up frames on the input side if the MediaStreamGraph cannot keep up.](https://hg.mozilla.org/mozilla-central/rev/b06d6ff27862)
- [Only pass on one black frame after disabling happens, so we don't do new allocations on each frame.](https://hg.mozilla.org/mozilla-central/rev/469e29166c55)
- [Send frames for image conversion onto a queue, processed by a separate thread - and drop frames if the separate thread is busy (> 1 frame queued up).](https://hg.mozilla.org/mozilla-central/rev/da8d6c4eab61)

With that done, the intermittents were gone. Jolly good!

---

Andreas Pehrson works with Mozilla's WebRTC team for Telenor Digital, as part of the joint WebRTC Competency Center.
