+++
title = "Guest Lecture: 10 Wege, wie ich deine App zerlege"
summary = "Guest lecture at FH Salzburg on mobile app reverse engineering: ten ways to take apart an iOS or Android app, demoed live against a deliberately broken Coffee Demo app I built for the occasion."
date = "2025-04-23"
author = "Emanuel Mairoll"
tags = ['Mobile', 'Reverse Engineering', 'Talk', 'iOS', 'Android']
showTableOfContents = false
+++

Guest lecture I gave at FH Salzburg on April 23, 2025. Title translates to *"10 Ways to Tear Your App Apart"*.

The connection came out of my HTL engineer certification - I was actually asked to lecture a full semester there, but had to decline due to my obligations at ETH, so we settled on this single guest lecture instead.

The plan was to keep slides minimal and let the live demos do the work. I built a small "Coffee Enjoyer" demo app in advance that was, security-wise, basically every anti-pattern in one place: world-readable preference files, plaintext API traffic, no jailbreak/root checks, no certificate pinning, no obfuscation. Then walked through ten different angles of attack against it - poking at local storage, MITM-ing the API, sideloading and re-signing, dumping decrypted IPAs, hooking with frida, the lot - on both iOS and Android.

A very practical talk, and the audience was genuinely engaged, which I really enjoyed. Hoping to do a few more guest lectures like this in the future.

{{< pdfcards >}}
{{< pdfcard file="slides.pdf" label="Slides" note="DE/EN" >}}
{{< /pdfcards >}}
