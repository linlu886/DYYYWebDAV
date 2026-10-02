# DYYYWebDAV

Minimal Theos/Logos tweak for Douyin 40.6.0, based on the public DYYY long-press panel structure.

## Build

Requires Theos and an iOS SDK:

```sh
make clean package SCHEME=rootless
```

## First-run configuration

Long-press a Douyin work and tap **WebDAV 设置**. Configure:

- Parser API: GET endpoint; `{url}` is replaced with URL-encoded share URL.
- WebDAV URL
- Username/password
- Remote directory

Then tap **解析并上传**.

The parser accepts the common DYYY response fields: `video_list`, `videos`, `video_url`, `video`, `url`, `images`, `img`, `cover`, `pics`, `music`, `music_url`.
