+++
title = "Coursework: Die wunderbar unsichere Welt der IoT"
summary = "Course paper and very practical presentation on IoT security: Google Dorking for exposed cameras, Sub-GHz attacks with the Flipper Zero, and a suitcase full of demo gadgets."
date = "2024-01-31"
author = "Emanuel Mairoll"
tags = ['IoT', 'Security', 'Talk', 'PLUS', 'Flipper Zero']
showTableOfContents = false
+++

Course paper and presentation for *Einführung in die Cybersicherheit* at the University of Salzburg, January 2024.

The paper walks through the IoT security landscape - firmware patterns (web, REST, MQTT, vendor protocols, Matter), the usual challenges (constrained hardware, embedded toolchain pain, vendor cloud lock-in), and wireless layers (Sub-GHz, WiFi, ZigBee, Thread). Two practical mini-projects round it out: Google Dorking for exposed CCTV systems running *Webcam 7* (we found everything from chicken coops to a 12-camera company setup, all over plain HTTP), and Sub-GHz reconnaissance with a Flipper Zero against a remote socket, a fog machine, and a courtyard gate (where we fell back to a jamming attack against KeeLoq rolling codes).

We went hard on the practical side. I packed a full suitcase of demo hardware for the talk and even gave away a reflashed lightbulb on stage, just to drive home the point that with cheap IoT devices you genuinely don't know what's running inside.

{{< pdfcards >}}
{{< pdfcard file="paper.pdf" label="Paper" note="English" >}}
{{< pdfcard file="slides.pdf" label="Slides" note="German" >}}
{{< /pdfcards >}}
