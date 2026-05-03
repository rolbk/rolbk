+++
title = "OSS-Fuzz: Improving binutils harnesses"
summary = "Software Security lab at EPFL: improving the OSS-Fuzz harnesses for binutils' strings and objcopy utilities, finding a real (low-severity) DoS along the way, and upstreaming the strings fix to OSS-Fuzz."
date = "2025-05-15"
author = "Emanuel Mairoll"
tags = ['Fuzzing', 'EPFL', 'CS-412', 'binutils']
showTableOfContents = false
+++

Group lab project for *Software Security* at EPFL, during my exchange in spring 2025. The course ran two projects in sequence: a semester-long CTF first, and then a fuzzing lab where we had to take a real OSS-Fuzz target and improve its harnesses. For the second project we picked binutils - the GNU suite of binary tools (objdump, strings, objcopy, ld, ...) that anyone doing reverse engineering or malware analysis spends half their day inside.

The first surprise was how much there was to improve. The *strings* harness was only achieving 3.66 % line coverage of itself: the existing fuzzer never actually called into strings, just a tiny section parser, and the entry point fell into infinite loops printing blank lines because the global state it needed was never initialized. The *objcopy* harness hardcoded its options, leaving the giant switch-case in the option parser entirely unreached. We rewrote both harnesses to expose program flags to the fuzzer, fixed the strings initialization, lifted objcopy's line coverage from 27 % to 44 %, and surfaced a low-severity DoS in `strings -d` on a specific architecture target. The strings fix was upstreamed to OSS-Fuzz as [PR #14782](https://github.com/google/oss-fuzz/pull/14782).

Surprisingly satisfying lesson in how a fuzzing harness that exists is not necessarily a fuzzing harness that works. Also a fun look at how OSS-Fuzz infrastructure actually fits together once you start patching it.

{{< pdfcards >}}
{{< pdfcard file="report.pdf" label="Lab report" >}}
{{< /pdfcards >}}
