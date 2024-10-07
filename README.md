# Note: replaced by: https://github.com/dyphire/uosc_danmaku

# mpv-load-danmaku

## Description

This is a lua script for mpv player. It will load danmaku files (`.xml`) of the same name in the playback directory.

## Requirements

Need [DanmakuFactory](https://github.com/hihkm/DanmakuFactory) to be installed or explicitly specified.

## Usage

### Keybinds

You can add bindings to input.conf:
```ini
key        script-message-to load-danmaku load-local-danmaku
key        script-message-to load-danmaku toggle-local-danmaku
```

### Script message

#### load-danmaku

`script-message load-danmaku input <xml_path>`

Allows loading of danmaku by passing the path to a given danmaku file (.xml) with a script-message.

## Todo

- [ ] consider using osd-overlay for rendering danmaku?
- [x] add script-message support

## Acknowledgement

- Modified from [MPV-Play-BiliBili-Comments](https://github.com/itKelis/MPV-Play-BiliBili-Comments)
- [DanmakuFactory](https://github.com/hihkm/DanmakuFactory) Provide danmaku file format conversion
