# Optimize Videos for Websites
On Windows ffmpeg build with rav1e and avc libs

```powershell
mkdir ~\ffmpeg
cd ~\ffmpeg
wget github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip -O ffmpeg.zip
unzip ffmpeg.zip

.\ffmpeg -i input.mp4 -t 10 -map_metadata -1 -an -c:v libx264 -crf 24 -preset veryslow -profile:v main -pix_fmt yuv420p -movflags +faststart -vf "scale=-1:720" output.h264.mp4

# .\ffmpeg -i input.mp4 -t 10 -map_metadata -1 -an -c:v libaom-av1 -crf 50 -b:v 0 -strict experimental -cpu-used 6 -tile-columns 2 -tile-rows 2 -pix_fmt yuv420p -movflags +faststart -vf "scale=-1:720" output.av1.mp4

.\ffmpeg -i input.mp4 -t 10 -map_metadata -1 -an -c:v librav1e -qp 150 -tile-columns 2 -tile-rows 2 -pix_fmt yuv420p -movflags +faststart -vf "scale=-1:720" output.av1.mp4

.\ffmpeg -i input.mp4 -t 10 -map_metadata -1 -an -c:v libx265 -crf 34 -preset veryslow -pix_fmt yuv420p -movflags +faststart -tag:v hvc1 -vf "scale=-1:720" output.hevc.mp4

```

# Example use in Elementor HTML widget:

```html
<video height="660" class="elementor-background-video-hosted elementor-html5-video" autoplay muted playsinline loop>
  <source
    src="output.av1.mp4"
    type="video/mp4; codecs=av01.0.05M.08"
  >
  <source
    src="output.hevc.mp4"
    type="video/mp4; codecs=hvc1"
  >
  <source
    src="output.h264.mp4"
    type="video/mp4; codecs=avc1.4D401E"
  >
</video>
```