---
layout:   post
title:    "Software Security in the Agile Way"
date:     2017-02-17 14:19:00
author:   "Mari Grini"
tags:     Security
categories: Security
comments: false
---

<img src="{{ site.baseurl }}/assets/security_agile.jpeg" title="I totally wanted a pic where security is in control">

Software security is an important part of the overall security in Telenor Digital. The outset for building secure software in Telenor Digital is to embrace the opportunities that DevOps approaches like agile, continuous integration and continuous delivery give us to improve security. As our organisation doesn´t have a massive history of legacy systems and legacy ways of working – we are allowed to tap from some of the most recent practices for securing our code. It is the ideal starting point for a journey to improve our software security.

<!--more-->

---

Software security is the idea of engineering software so that it continues to function correctly under malicious attack.It is about designing software to be secure, making sure that the software is secure, educating developers, architects and users about how to build secure things.

On the other hand – application security is about protecting the software after the development is complete. For example by protecting against malicious code, locking down executables, monitoring programs as they run etc (1)
It is generally agreed that the best option is to build secure software from the start. In the long run it is easier to build security in than to protect code.
Software security is about helping builders to do a better job and to design for security – so that malicious attacks get difficult.

## The state of software security

As stated by Mark Andreesen, maybe best known from being the one of the coauthors of one of the first widely used web browser mosaic- in a 2011 wall street journal essay “software is eating the world”. More and more software is built into things - and more and more is actually virtualized or digitalised. Industries are disrupted by software.
Or more pessimistically put by Josh Corman in a OWASP AppSec Conference presentation: “Software is infecting the world. In other words we need to build security into the software in order to create the necessary foundation for trust.

Let´s take a look at the state of software security as of today. Statistics from CVE, a dictionary of publicly known information security vulnerabilities and exposures, shows this year a significantly lower number of such vulnerabilities than earlier years.

SANS has published as study that shows that the gap between so-called
Defenders – i.e. the security and operations teams responsible for securing applications and running secure systems and Builders – developers and development organisations is decreasing. According to SANS reliable and secure systems is dependent on these groups climbing out of their silos and more closely together. The study shows this is already happening – However while we are working in the right direction – we still need a bigger effort:
Management must provide developers with time, tools and training to build secure systems
Developers must understand that they share important responsibilities for security.
Security and operations teams must understand and adapt to the ways development is changing and accelerating.

Software building practices are changing and offer opportunities to improve security – that we must embrace.

The software (security) development lifecycle (SSDL) is important  in ensuring predictable quality of the security work as it helps developers build more secure software and address security compliance requirements.

## Disadvantages to traditional approach to security in a SSDL
Before looking at how newer software building practices allow building security in, we will take a look at some of the disadvantages of the traditional approach to security in a SSDL that we would like to improve.

Traditional approaches to software the SSDL includes extensive documentation, often extensive requirements analysis and design and risk analysis before development. After development there were extensive test periods where all kinds of checks were done including manual check-off by the security officer before code went into production. This approach implied long feedback and learning loops for security as it might have been a long period of time between when risk analysis was performed and when the security checks were completed.

Security benefits from short feedback and learning loops for security. Getting feedback shortly after the code is committed makes it easier to correct and improve security as the code is still fresh in the mind of the developer.  

The traditional SSDL implemented in many organisations implies that developers deliver their code to operational people for pushing it to production. Because quality controls in traditional SSDLs are implemented through gateways that enforce isolations of developers from the operational environment, they are disenfranchised from caring or even knowing about security or operational issues.

In this approach operational people and not the developer is operationally responsible for that the code might have security implications.The emphasize is in this case not on making the developer aware of operational consequences of his or her code and of empowering him or her to fix.

Security benefits from software developers that are operationally responsible for that the code might have security implications if they also are empowered and enabled to fix.
In traditional software development lifecycles there is an emphasize on doing a risk analysis upfront. But as innovative software projects imply unknown factors that only can be learned by trial and error – understanding all of the risk upfront might not be possible because enough information is simply not available at that point.

Security benefits from learning by doing and from continuously harvesting new knowledge from trying out in real life is anticipated solutions work as expected.

Furthermore the requirements to deliver new features of changes in an ever bigger tempo simply does not fit with huge time consuming analysis of a possible future and a manual approach to security testing done at infrequent time slots. And as results from thorough security tests are ready, the developers long have changed the code and might have difficulties in understanding if the findings still apply.

When code is ready there would be no real reason why it should not be available to customers as quickly as possible.  

## How to improve? Agile as a basis for building secure code

According to SANS improvement can be done by “Wiring security into development tools and continuous integration and continuous delivery pipelines. Build feedback loops between builders, operations and defenders. Work together to continuously review and improve how application security is done”.

An agile development team who continuously deliver code to production is a very good starting point for improvement.

Let´s first look at agile software development as a basis for building secure code. Agile software development is a group of software development methods in which solutions evolve through collaboration between self-organizing, cross-functional teams.
It promotes adaptive planning, evolutionary development, early delivery, continuous improvement and encourages rapid and flexible response to change.

Some has questioned agile teams and their ability to deliver secure software. In a case study by NTNU and Sintef they found that small and medium sized agile software development organisations do not use any particular methodology to achieve security goals – even when their software is web-facing and potential targets of attacks.  Their study confirmed that even in cases where security is an articulated requirement – and where security design is fed as input to the implementation team – there is no guarantee that the end result meets the security objectives.

However that many agile teams do not consider security as of now – does not imply that agile methodologies gives less opportunity to deliver secure software.

In fact – agile methodologies might be particularly well fit to improve security by allowing to “wire security into development processes and tools and building feedback loops between builders, operations and defenders.

The outset for the security initiative in Telenor Digital is therefore to embrace the opportunities that DevOps approaches like agile, continuous delivery and continuous delivery gives us to close the gap and improve security. According to Sintef, there are at current no commonly agreed scientific approaches to security in agile development as of yet - but there are plenty of ideas and practices out there.

## How to improve. Continuous integration and delivery as a basis for building secure software
In addition to Agile, the concepts of Continuous integration and continuous delivery would thus also be a basis for our approach to building secure software.
The practice of building and testing your application on every check-in is called continuous integration (CI). It has also been described by some as the practice in software engineering of merging all developer working copies with a shared mainline several times a day. Continuous integration detects changes that breaks the system at the time the change is introduced to the system. And then the issues can be fixed. And the software is always in a releasable state.

Continuous delivery is a software strategy that enables organization to deliver features to users as fast and efficiently as possible. It extends CI by making sure the software checked in on the mainline is always in a state that can be deployed to users. The ultimate goal of Continuous delivery is to enable a constant flow of changes into production via an automated production line.

Continuous integration and continuous delivery are concepts that fit very well with the slogan of “building security in” and the idea that security shall be considered already from the start – because the process would be designed to try to detect errors and weaknesses as early as possible in the process. This could also include security weaknesses.

Continuous delivery allows for smaller changes at the time. Smaller changes reduces code complexity And if an error is found it is easier to fix or possibly roll-back. This means that every small change is less likely to contain security issues. And it is also less likely that one of the small changes contains a critical security issue.
From a security point of view continuous integration and continuous delivery could thus be viewed as keys to fast feedback and learning loops to detect and correct possible security deficiencies as quickly as possible.

## How to improve: Controls as part of an automated pipeline
In traditional lifecycles a basic control mechanism is segregation of duties. It is implemented by building upon the clear division of labor where some people develop code while others operate it. It thus ensures:
That at least two people must be involved in putting code into production
That the privileges to change the production environment are restricted
That those responsible for operating the code are aware of that new code is pushed to production and that they are handed over the responsibilities to operate it.

In DevOps it is not inherently the same clear division of labor between those developing and those operating code. Therefore it would not necessarily be the same kind of gateway where you manually approve security at at delivery from development to operations.

A well defined Deployment Pipeline could provide alternative controls to those found traditionally. Automated pipeline means that it is easier to know the exact steps that were followed both prior to and at pushing the code to production than when people are left to manually follow written manuals.  A push to production functionality could for example only be allowed to be triggered after security tests are passed with an acceptable result.

## How to improve: Scheduled manual security tests to get hold of the high hanging fruits
Periodically it would be recommended that competent externals take a look at the product. Involving manual experts with specialist competencies allows discovery of issues that the devops team and the automated tests might not have thought about or that they don´t have abilities to detect.

Getting someone from outside to look at the product could involve both functional, dynamic and static security tests or other aspects of the security. This is great input for improvement - Especially when the security experts  are allowed to focus on finding the high hanging fruits – and not only the trivia that the team easily can fix themselves by use of tools.

## Building secure software in Telenor Digital
So let´s take a closer look at what this would look like in a case built from software development processes in the Telenor Digital

## Development
In Telenor Digital Git is used for source code version control. Git allows efficient tracking and logging of all changes to the code. It also allows branching and merging of code according to the needs of the team. Typically the developer will branch for developing the features that he or she will deliver. Risky features can be identified for threat modeling to identify possible security design flaws. And as part of developing the new features, the coder will make the adequate unit tests to verify the code. As part of this task it should be considered if security unit tests should be written to verify the business logic security of the feature.

In Telenor Digital code shall go through a code review by peer. For the ultimate security and enforcement of segregation of duties in the development pipeline, the code review should be enforced. During the code review for security verification – it could be verified that business logic security risk is understood and that adequate unit tests for business logic security verification are made. In addition to finding possible security issues  - code review implements a 4 eyes principle for every change to the authoritative repository.

## Test /Staging
During test and staging different types of security test can be run. Including dynamic security tests, static security tests and third party dependency tests. Some vulnerabilities can only be found with static testing while others are best found with dynamic testing tools. For example: Many web apps use quite a lot of client side code – which typically must be analysed by use of static tools.

In addition a lot of applications use 3rd party libraries – and it is well know that these might be prone to vulnerabilities too. Thus to check for security in  3rd party code, a check of this code should be done too.

Some tests can be run inline – while others can be run only as part of the nightly build. The reason for running them as part of the nightly build could be:
Because trends are followed up for the code base as a whole
Because the tests simply are too time consuming

There are lots of security testing tools out there – some are commercial tools while others are open source. To enable an accumulated security status report that covers the different teams some tools should as appropriate be standardised. Each and every team would be encouraged to add additional tools to their pipeline as required and share experiences for possible generic improvements across the organisation.

## Push to production
The automated pipeline should gradually be professionalised to ensure that the adequate controls before production are implemented (and documented as of implementing the pipeline) and to make sure that the push to production is done only in the right conditions.  


*Mari Grini is the Head of Security at Telenor Digital.*

<a href="https://twitter.com/MariGrini" class="twitter-follow-button" data-show-count="false" data-size="large">Follow @janjongboom</a>
<script>!function(d,s,id){var js,fjs=d.getElementsByTagName(s)[0],p=/^http:/.test(d.location)?'http':'https';if(!d.getElementById(id)){js=d.createElement(s);js.id=id;js.src=p+'://platform.twitter.com/widgets.js';fjs.parentNode.insertBefore(js,fjs);}}(document, 'script', 'twitter-wjs');</script>
