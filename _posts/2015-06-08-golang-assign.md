---
layout: post
title:  "Assigned and Not Used"
date:   2015-06-08 12:00:00
categories: golang
author: "Gordon Klaus"
tags: golang
comments: false
---

One of the more common bugs that [Go](https://golang.org) programmers write involves shadowing an error variable, as in the following code (taken from [this relevant blog post](http://www.qureet.com/blog/golang-beartrap/)):

{% highlight go %}
var err error
if isSecure {
	config, err := GetTLSConfig()
	if err != nil {
		return err
	}
	conn, err = tls.Dial("tcp", server + ":443", &config) // BUG
} else {
	conn, err = net.Dial("tcp", server)
}
if err != nil {
	return err
}
// use conn...
{% endhighlight %}

The intention of the line marked `// BUG` is to assign to the outermost declared `err`.  However, the `err` declared in the if-block shadows the outer `err`, rendering the assignment useless.  An error returned from tls.Dial will never reach the final `if err != nil` check.  Not good.

I have on multiple occasions seen people bitten by this type of bug, but it wasn't until a week ago that I realized that the compiler's failure to detect it was probably unintentional.  Go is kind enough to tell us when we declare but do not use a variable but, strangely, it doesn't say anything about assigned and thereafter unused variables, which is our situation above.

I pointed out this omission in [Issue #10989](https://github.com/golang/go/issues/10989); and Robert Griesemer, while agreeing that it would be good to flag such "assigned and not used" errors, confirmed my suspicion that it would constitute a backwards-incompatible language change, and thus probably not find its way into the compilers.

Nevertheless, I had a hunch that it would highlight only buggy code, which might justify breaking such code.  I decided to investigate.  The convenience of the Go standard library's [go/ast](http://golang.org/pkg/go/ast/) package enabled me to quickly whip together [a tool](https://github.com/gordonklaus/ineffassign) that approximates the desired behavior.

The implementation was fairly straightforward.  I won't go into details; the essential observations are of the scopes in which variables are declared and used, especially regarding loops, and of whether a variable can *escape* (by taking its address or being referenced in a function literal (closure)) and possibly be assigned later.  I would later find that Alan Donovan had given a good [lowdown of the problem](https://github.com/golang/go/issues/6072#issuecomment-66083545) when a nearly identical issue was filed a year and a half ago.

Running my tool against the standard library and a few packages in my GOPATH flagged 72 "assigned and not used" errors.  A perusal revealed most of them to be innocuous (but sloppy) code, and 7 of them to be real errors.  Not enough to justify a breaking language change, I thought.  But when I [posted my findings on the Go mailing list](https://groups.google.com/d/topic/golang-nuts/MdDLbvOjb4o/discussion), Rob Pike made it clear that he thought the compiler should do this check.

We shall see.  But honestly, I don't see how this could happen without flagrantly violating the [Go 1 Compatibility Guarantee](https://golang.org/doc/go1compat).