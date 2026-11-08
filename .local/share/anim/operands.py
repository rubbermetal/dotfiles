"""
This module provides functions to parse command line arguments for various file operations.
Usage example:
    result = parse_operands("mv", ["source1", "source2", "destination"])
"""

import re

def parse_operands(cmd, args):
    if cmd in ("mv", "cp"):
        return _move_copy(args)
    elif cmd == "rm":
        return _remove(args)
    elif cmd == "chmod":
        return _chmod(args)
    elif cmd == "rsync":
        return _rsync(args)
    elif cmd == "curl":
        return _curl(args)
    else:
        return _empty()

def _empty():
    return {"sources": [], "dest": None, "mode": None, "url": None, "output": None}

def _scan(args, arg_options):
    operands = []
    opts = []
    in_operands = False
    i = 0
    while i < len(args):
        arg = args[i]
        if in_operands:
            operands.append(arg)
        elif arg == "--":
            in_operands = True
        elif arg.startswith("-") and len(arg) > 1:
            if arg.startswith("--") and "=" in arg:
                name, value = arg.split("=", 1)
                opts.append((name, value))
            elif arg in arg_options:
                value = args[i + 1] if i + 1 < len(args) else None
                opts.append((arg, value))
                i += 1
            else:
                opts.append((arg, None))
        else:
            operands.append(arg)
        i += 1
    return operands, opts

def _move_copy(args):
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
        else:
            sources = []
    return {"sources": sources, "dest": dest, "mode": None, "url": None, "output": None}

def _remove(args):
    operands, _ = _scan(args, set())
    return {"sources": operands, "dest": None, "mode": None, "url": None, "output": None}

def _chmod(args):
    operands, opts = _scan(args, {"--reference"})
    mode = None
    if not any(opt == "--reference" for opt, _ in opts):
        for opt, _ in opts:
            if re.match(r"^-[rwxXstugoa]+$", opt):
                mode = opt
                break
        if mode is None and operands:
            mode = operands[0]
            operands = operands[1:]
    return {"sources": operands, "dest": None, "mode": mode, "url": None, "output": None}

def _rsync(args):
    operands, _ = _scan(args, {"-e", "--rsh", "-f", "--filter", "--exclude", "--include", "--exclude-from", "--include-from", "--files-from", "--bwlimit", "--port", "--partial-dir", "--log-file", "--timeout", "--max-size", "--min-size", "--backup-dir", "--suffix", "--temp-dir", "-T", "--compare-dest", "--copy-dest", "--link-dest", "--out-format", "--chmod", "--chown", "--usermap", "--groupmap", "--password-file", "--sockopts", "--address", "--rsync-path"})
    dest = None
    if len(operands) > 1:
        sources = operands[:-1]
        dest = operands[-1]
    else:
        sources = list(operands)
    return {"sources": sources, "dest": dest, "mode": None, "url": None, "output": None}

def _curl(args):
    operands, opts = _scan(args, {"-o", "-H", "-d", "-X", "-u", "-A", "-e", "-b", "-c", "-F", "-T", "-m", "-w", "-x", "-y", "-Y", "-z", "-C", "-E", "-K", "-r", "-t", "-U", "-D", "-P", "-Q", "--output", "--header", "--data", "--data-raw", "--data-binary", "--data-urlencode", "--data-ascii", "--request", "--user", "--user-agent", "--referer", "--cookie", "--cookie-jar", "--form", "--upload-file", "--max-time", "--write-out", "--proxy", "--retry", "--connect-timeout", "--json", "--dump-header", "--cacert", "--cert", "--key", "--resolve", "--limit-rate", "--range", "--output-dir", "--url"})
    url = None
    output = None
    for opt, value in opts:
        if opt in ("-o", "--output"):
            output = value
        elif opt == "--url":
            url = value
    if not url and operands:
        url = operands[0]
    if not output:
        for opt, _ in opts:
            if opt in ("-O", "--remote-name"):
                if url:
                    rest = url.split("://", 1)[-1]
                    path = rest.split("/", 1)[1] if "/" in rest else ""
                    output = path.split("?")[0].split("#")[0].rsplit("/", 1)[-1] or "index.html"
                break
    return {"sources": [], "dest": None, "mode": None, "url": url, "output": output}
