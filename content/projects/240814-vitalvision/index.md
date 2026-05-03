+++
title = "Bachelor Thesis: VitalVision"
summary = "Bachelor thesis at ETH SIPLAB: a mobile platform for real-time signal-quality validation of wearable ECG and PPG data during long, in-the-wild physiological studies."
date = "2024-08-14"
author = "Emanuel Mairoll"
tags = ['Bachelor Thesis', 'ETH', 'Wearables', 'Rust', 'Swift', 'BLE']
showTableOfContents = false
+++

My BSc Computer Science thesis, written at ETH Zürich's *Sensing, Interaction & Perception Lab* during my exchange semester in spring 2024 and finalized in August. Co-supervised across two universities: Prof. Christian Holz and Manuel Meier at ETH, Prof. Andreas Naderlinger at the University of Salzburg.

In long-term wearable studies (24-36 h continuous ECG/PPG), data quality silently degrades: an electrode peels off, an arm moves, sweat interferes with the sensor contact, and you only find out after the study that hours of recording are useless. VitalVision puts a smartphone in the loop as a live quality monitor. It connects to multiple wearables over BLE, runs lightweight quality-assessment algorithms (R-peak consistency for ECG, pulse morphology for PPG) on the phone, and warns the experimenter when something goes off the rails - without taking the recording duties away from the wearable. The core is written in Rust and exposed to Swift via UniFFI bindings, with a native Swift/SwiftUI frontend.

I had a lot of freedom on the build - the lab brought me in for the software side specifically because mobile wasn't their home turf, and I had been doing mobile dev for years at that point. Beyond the thesis itself, the BSc exchange at ETH was a great way to collect a few experiences there before going all-in for my Master's the following autumn.

I was really honored that the thesis went on to receive a [*teampool Auszeichnung für Abschlussarbeiten*](https://informatik.cs.plus.ac.at/de/post/teampool-awards/) from the Department of Computer Science at PLUS in October 2024 - one of three €1000 prizes given out per year for outstanding bachelor's and master's theses in computer science.

{{< pdfcards >}}
{{< pdfcard file="thesis.pdf" label="Thesis" >}}
{{< pdfcard file="slides.pdf" label="Defense slides" >}}
{{< /pdfcards >}}
