---
layout: post
title:  "RTCPeerConnection.getStats: Chrome vs Firefox"
date:   2015-06-11 15:40:00
categories: webrtc
author: "Gordon Klaus"
tags: webrtc
comments: false
---

Neither Chrome nor Firefox quite conforms to [the spec](http://w3c.github.io/webrtc-pc/#statistics-model) for [WebRTC statistics](http://w3c.github.io/webrtc-stats/), nor is the spec done evolving.  I'll try to document some of their peculiarities here and to update this post when changes arise.

###API

The spec says `RTCPeerConnection.getStats` takes a nullable `MediaStreamTrack`, a success callback, and a failure callback, in that order.  The success callback is passed an `RTCStatsReport` which has a getter for accessing its various `RTCStats` by ID.

Chrome reverses the order of the first two parameters, and its success callback is passed a `RTCStatsResponse` whose `result` method returns a list of `RTCStatReport` objects.  Chrome's `RTCStatsReport` does not correspond to the spec's type of the same name, but to its `RTCStats`; it is just a dictionary.

Firefox matches the spec; but the callbacks are optional, and if both callbacks are omitted then a `Promise` is returned.  Presumably the spec will eventually prefer Promises as it already does for other methods.

The two APIs can be unified with the following code:

{% highlight javascript %}
function getStats(pc, selector) {
	if (navigator.mozGetUserMedia) {
		return pc.getStats(selector);
	}
	return new Promise(function(resolve, reject) {
		pc.getStats(function(response) {
			var standardReport = {};
			response.result().forEach(function(report) {
				var standardStats = {
					id: report.id,
					type: report.type
				};
				report.names().forEach(function(name) {
					standardStats[name] = report.stat(name);
				});
				standardReport[standardStats.id] = standardStats;
			});
			resolve(standardReport);
		}, selector, reject);
	});
}
{% endhighlight %}

###Stats

Each `RTCStats` (or `RTCStatsReport` in Chrome) object is a dictionary with three default attributes: `timestamp`, `type`, and `id`; and various other attributes: some required, depending on `type`, and others that are implementation specific.

Firefox does not include `timestamp`.

The spec defines various stats report types.  Instead of `outboundrtp` and `inboundrtp`, Chrome uses `ssrc`.  The exact type can be inferred from the presence of attributes such as `bytesSent` vs `bytesReceived`.

The spec decrees that `roundtriptime` shall be defined on an RTPOutboundRTPStreamStats object.  Google calls this `googRtt`.  Firefox calls it `mozRtt` and puts it on the inbound stats rather than the outbound.
