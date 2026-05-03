+++
title = "OpenGLHF: An Entity-Overlay Minecraft Hack"
summary = "Computer Graphics course project at the University of Salzburg: a Minecraft Fabric hack that hooks into the entity rendering pipeline to draw bounding boxes, tracers and entity info."
date = "2023-06-15"
author = "Emanuel Mairoll"
tags = ['Computer Graphics', 'OpenGL', 'Minecraft', 'PLUS']
showTableOfContents = false
+++

Project for the *Computer Graphics* course with Prof. Held at the University of Salzburg, summer semester 2023.

The semester worked through a wide spread of computer graphics concepts - rendering pipelines, transformations, shading, framebuffer manipulation - and the open-ended project was where it all had to land in practice. My own development journey actually started years ago writing Minecraft client mods of the less wholesome kind, so the project was a nice excuse to come back to that world with a more grown-up toolchain. We built an entity overlay - bounding boxes around mobs, tracers from the player to entities, name/health/distance labels - using Fabric for the loader and working at two layers, both through Minecraft's own *Blaze3D* render pipeline and around it with raw OpenGL via LWJGL.

This is also the project that produced the "best screenshot ever" in my collection: Prof. Held on a Zoom call with full-screen Minecraft behind him during the live demo. Worth the entire semester on its own.

{{< pdfcards >}}
{{< pdfcard file="slides.pdf" label="Slides" >}}
{{< /pdfcards >}}
