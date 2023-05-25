# ffmpeg-dockerfile
A built-from-source `ffmpeg` docker image.

Use `docker run` to execute the image for arbitrary `ffmpeg` operations.

E.g., re-encode a video into AV1 using `libsvtav1`:

```
docker run --rm -t -v "${workdir}:/work" ffmpeg ffmpeg \
  -i "/work/input.mkv" \
  -c:v libsvtav1 \
  -preset 8 \
  -crf 30 \
  -c:a copy \
  "/work/output.mkv"
```
