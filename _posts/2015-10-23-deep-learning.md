---
layout:   post
title:    "Live analyzing movement through machine learning"
date:     2015-10-23 11:51:00
author:   "Bjørn Remseth and Jan Jongboom"
tags:     deep-learning hackathon
comments: false
---

Twice a year Telenor Digital organises an internal hackathon, a two-day offsite where we have the chance to mingle with other teams and work on things we'd normally never touch. Given Jan's [fascination with phone sensors](https://www.youtube.com/watch?v=u6twcglDFNc) he was wondering whether we could feed the data from the gyroscope and the accelerometer into a machine learning algorithm and that way classify what a person is doing. Could we create a model that would check the stream of data coming off these sensors and then tell whether the person is sitting, walking or dancing?

<!--more-->

<iframe width="420" height="315" src="https://www.youtube.com/embed/I0cho9xLv0E" frameborder="0" allowfullscreen></iframe>

We quickly assembled our dream team consisting of Bjørn Remseth, who took a class or two in machine learning; Audun Torp, a mathematician; and Jan Jongboom, a certified data gatherer. And with that we were off to work, having 36 hours to start building our classifier...

## Gathering data

The first step in training a model is to acquire some test data. In this phase there's no fancy processing, but just recording data of the sensors, tagging it with a movement (sitting, walking, dancing) and storing it. To get up to speed as fast as possible we decided to hack together a simple JavaScript web application that uses the [device orientation and device motion](http://www.html5rocks.com/en/tutorials/device/orientation/) APIs to acquire data from the gyroscope (alpha, beta, gamma axes) and the accelerometer (x, y, z axes); giving us six data streams to work with.

The web application is connected over a web socket to a node.js server sitting on a laptop, and creates per measurement a CSV file that contains the timestamp and the raw data from each of the sensor axes. The application we built [is hosted on GitHub](https://github.com/la3lma/movement-analysis/tree/master/data-gathering), and outputs it's data into the 'raw-data' folder.

To get some nice training data, we then take an ordinary Android or iOS phone, navigate the browser to the client web page, and hit 'Start measurement'. For 30 seconds (indicated by beeps every 10 seconds) we then record the data, and later tag it by renaming the file to something like 'jan-dancing-v1.csv'.

<img src="{{ site.baseurl }}/assets/movement1.png" width="200" title="The client application"> <img src="{{ site.baseurl }}/assets/movement2.png" width="430" title="Raw data flowing into the computer">

*Data gets measured 30 times per second and dumped into a file*

## Training the model

Bjorns gonna write something here

## Live classifying the data

Now that we have a trained model we can start classifying data as it flows in. For this we can re-use the app we used for data gathering. As it already writes to a file whenever new data flows in we can have our Python application monitor the directory and read the last touched file. Then take the last 3 seconds and feed it into the classifier (cleaned up a bit for readability):

{% highlight python %}
data_feed = arguments['--data']

if data_feed:
    print "Monitoring folder " + data_feed
    while True:
        try:
            all_files_in_df = map(lambda f: os.path.join(data_feed, f), os.listdir(data_feed))
            data_file = max(all_files_in_df, key = os.path.getmtime)

            sample = sample_file(data_file)
            # get 6 seconds * 30 samples
            sample.keep_last_lines(180) 
            samples = sample.get_samples()

            # dump the classification into a file
            pr = clf.predict(samples)
            with open('../data-gathering/classification', 'w') as f:
                f.truncate()
                f.write(str(pr))
        except:
            print "Unexpected error", sys.exc_info()[0]

        time.sleep(1)
{% endhighlight %}

This reads data from the data-gathering application, and writes the result from the classifier back to a file, looking something like this, where the numbers on the right are the most recent:

<pre>
[0 2 2 2 0 0 0 1 1 0 1 0 0 0 0 0 2 2 2 2 2 2 2 2 2 2 2 2 2 2]
</pre>

*0=sitting, 1=walking, 2=dancing*

In the node.js app we can monitor the classification file, and then send this data over a web socket to a web browser to visualise the movement:

{% highlight javascript %}
fs.watch('./classification', function(curr, prev) {
  fs.readFile('./classification', 'utf-8', function(err, data) {
    if (err) {
      return console.error('Cannot read classification file', err);
    }
    broadcast(JSON.stringify({
      type: 'classification',
      classification: data.match(/\d/g)
    }));
  });
});
{% endhighlight %}

Based on that we can create a simple [web page](https://github.com/la3lma/movement-analysis/blob/master/data-gathering/server/index.html) that then shows this data to the user, giving live feedback on what the classifier thinks he's doing at this very moment!

<img src="{{ site.baseurl }}/assets/movement3.png" title="Jan dancing!">

*The classifier giving live feedback on the computer screen on what the model thinks Jan is doing. This is all based on just one axis of his phone's gyroscope in his front pocket.*

## Conclusion

We were incredibly surprised how far we managed to get in 36 hours. The classifier is rough around the edges, and more training data probably helps, it's surprising to see how well the classifier already manages to distinguish movement. It's even more surprising to see that we even managed to get proper results by just using one out of the six axes. Just imagine how much better this can get with more data. Machine learning is really maturing.

I'd like to encourage everyone reading this to actually try our project. We already trained the model, and all code and instructions are listed in [this GitHub repo](https://github.com/la3lma/movement-analysis). You'll just need a phone. Of course you can just throw away our model and use our code to train a completely new one. To get you started we already included some data of people walking up the stairs. Try feeding that data into the model, and see what happens, we'd love to see your results!

---

*Jan Jongboom is a Strategic Engineer for Telenor Digital, working on the Internet of Things. He's also a Google Developer Expert for web.*

<a href="https://twitter.com/janjongboom" class="twitter-follow-button" data-show-count="false" data-size="large">Follow @janjongboom</a>
<script>!function(d,s,id){var js,fjs=d.getElementsByTagName(s)[0],p=/^http:/.test(d.location)?'http':'https';if(!d.getElementById(id)){js=d.createElement(s);js.id=id;js.src=p+'://platform.twitter.com/widgets.js';fjs.parentNode.insertBefore(js,fjs);}}(document, 'script', 'twitter-wjs');</script>
