"""
This module provides functions to parse command line arguments for additional file operations.
Usage example:
    result = parse_more("ln", ["source1", "source2", "destination"])
"""

from operands import _scan, _empty
import os

def parse_more(cmd, args):
    if cmd == "ln":
        return _ln(args)
    elif cmd == "mkdir":
        return _mkdir(args)
    elif cmd in ("chown", "chgrp"):
        return _owner(args)
    elif cmd == "shred":
        return _shred(args)
    elif cmd == "wget":
        return _wget(args)
    elif cmd == "umount":
        return _umount(args)
    else:
        return None

def _ln(args):
    operands, opts = _scan(args, {"-t", "-S", "--target-directory", "--suffix"})
    dest = None
    for opt, value in opts:
        if opt in ("-t", "--target-directory"):
            dest = value
            break
    if dest:
        sources = operands
    else:
        if len(operands) > 1:
            sources = operands[:-1]
            dest = operands[-1]
        elif len(operands) == 1:
            sources = [operands[0]]
            dest = os.path.basename(operands[0].rstrip("/")) or operands[0]
        else:
            sources = []
    return {"sources": sources, "dest": dest, "mode": None, "url": None, "output": None}

def _mkdir(args):
    operands, opts = _scan(args, {"-m", "--mode", "-Z", "--context"})
    mode = None
    for opt, value in opts:
        if opt in ("-m", "--mode"):
            mode = value
            break
    return {"sources": operands, "dest": None, "mode": mode, "url": None, "output": None}

def _owner(args):
    operands, opts = _scan(args, {"--reference", "--from"})
    if any(opt == "--reference" for opt, _ in opts):
        mode = None
    else:
        mode = operands[0] if operands else None
        operands = operands[1:]
    return {"sources": operands, "dest": None, "mode": mode, "url": None, "output": None}

def _shred(args):
    operands, _ = _scan(args, {"-n", "--iterations", "-s", "--size", "--random-source"})
    return {"sources": operands, "dest": None, "mode": None, "url": None, "output": None}

def _url_name(url):
    if "://" in url:
        url = url.split("://", 1)[1]
    if "/" in url:
        path = url.split("/", 1)[1]
    else:
        path = ""
    path = path.split("?", 1)[0].split("#", 1)[0]
    name = path.rsplit("/", 1)[-1] or "index.html"
    return name

def _wget(args):
    operands, opts = _scan(args, {"-O", "--output-document", "-P", "--directory-prefix", "-o", "-a", "-e", "-U", "--user-agent", "--header", "--post-data", "--post-file", "-t", "--tries", "-T", "--timeout", "--limit-rate", "-w", "--wait", "-i", "--input-file", "-B", "--base", "--user", "--password", "--referer", "--load-cookies", "--save-cookies", "--ca-certificate"})
    url = operands[0] if operands else None
    output = None
    named = False              # True when -O/--output-document was given ("-" means standard output: no name)
    prefix = None
    for opt, value in opts:
        if opt in ("-O", "--output-document"):
            named = True
            output = None if value == "-" else value
        elif opt in ("-P", "--directory-prefix"):
            prefix = value
    if url and not named:
        output = _url_name(url)
        if prefix:
            output = os.path.join(prefix, output)
    return {"sources": [], "dest": None, "mode": None, "url": url, "output": output}

def _umount(args):
    operands, _ = _scan(args, {"-t", "--types", "-O", "--test-opts"})
    return {"sources": operands, "dest": None, "mode": None, "url": None, "output": None}
