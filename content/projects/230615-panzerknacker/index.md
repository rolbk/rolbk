+++
title = "Coursework: Smart Cards"
summary = "Seminar talk at the University of Salzburg covering smart card history, the ISO 7816 / 14443 protocol layers, and a live demo cloning a UID with a Flipper Zero to bypass an access-control gate."
date = "2023-06-15"
author = "Emanuel Mairoll"
tags = ['Smart Cards', 'NFC', 'Security', 'Talk', 'PLUS']
showTableOfContents = false
+++

Seminar talk for *Kryptografie und IT-Sicherheit* with Prof. Uhl at the University of Salzburg, summer semester 2023. The talk covered the protocol layers that smart cards live on - physical structure (contact pad, antenna inlay), the ISO 7816 stack for contact cards and ISO 14443 for contactless, and the application-level APDU protocol sitting on top of both - with a quick historical detour for context.

Like most of my talks, the goal was to keep things practical. I built a small access-control demo - a software "gate" that unlocks when it sees a known card UID - and used a Flipper Zero on stage to copy the UID from a valid card onto a blank one, then opened the gate with both. Always nice when the room sees the abstract protocol diagram turn into a working bypass in front of them.

{{< pdfcards >}}
{{< pdfcard file="slides.pdf" label="Slides" >}}
{{< /pdfcards >}}
