+++
title = "ETH Quantum Hackathon: Q-Cut Logistics"
summary = "ETH Quantum Hackathon project: solving the Capacitated Vehicle Routing Problem via a two-phase decomposition that funnels each sub-TSP through QUBO and MaxCut for a quantum solver."
date = "2024-05-03"
author = "Emanuel Mairoll"
tags = ['Quantum Computing', 'Hackathon', 'Optimization', 'ETH']
showTableOfContents = false
+++

Project from the *ETH Quantum Hackathon 2024* in Zürich, attended during my BSc exchange semester at ETH. I put together a team with a few new-found friends from Politecnico di Milano - quantum technology and physics students who were in town for the hackathon.

We tackled the Capacitated Vehicle Routing Problem on the classic *CMT* benchmark dataset, splitting it into a clustering phase (assign customers to vehicles) and a routing phase (solve each per-vehicle TSP). The TSPs were encoded as QUBO instances and reduced to MaxCut to run on the quantum hardware available at the hackathon, with graph-separator tricks to keep the problems within the qubit budget.

Best part of the weekend was the people - still in touch with the PoliMi crew today. The hackathon also included a tour of the ETH quantum labs, where I finally got to physically touch a quantum computer. One off the bucket list. Nice.

{{< pdfcards >}}
{{< pdfcard file="slides.pdf" label="Slides" >}}
{{< /pdfcards >}}
