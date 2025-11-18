# ffmpeg-dockerfile
A built-from-source `ffmpeg` docker image.

Use `docker run` to execute the image for arbitrary `ffmpeg` operations.

E.g., re-encode a video into AV1 using `libsvtav1`:

```
docker run --rm -t -v "${workdir}:/work" ffmpeg \
  -i "/work/input.mkv" \
  -c:v libsvtav1 \
  -preset 8 \
  -crf 30 \
  -c:a copy \
  "/work/output.mkv"
```


## NVIDIA CUDA HW Acceleration

Check out the [complete documentation](https://docs.nvidia.com/video-technologies/video-codec-sdk/12.0/ffmpeg-with-nvidia-gpu/index.html#basic-testing) for transcoding with NVIDIA GPU Hardware.

### Transcoding Example

This is an example of transcoding an H264 MKV into a 10Mbps AV1 MP4.

```
docker run --gpus all --rm -it \
  -v ".:/work" \
  ffmpeg -hwaccel cuda -hwaccel_output_format cuda \
  -c:v h264_cuvid \
  -i /work/input.mkv \
  -c:v av1_nvenc -b:v 10M \
  -c:a copy \
  -c:s copy \
  -movflags faststart \
  /work/output.mp4
```

### VMAF-CUDA Example

[NVIDIA Developer Documentation](https://developer.nvidia.com/blog/calculating-video-quality-using-nvidia-gpus-and-vmaf-cuda/)

This is an example of calculating VMAF score using CUDA HW acceleration:

```
docker run -it --rm --gpus all \
  -v ".:/work" \
  ffmpeg \
  -hwaccel cuda -hwaccel_output_format cuda -i /work/distorted.mkv \
  -hwaccel cuda -hwaccel_output_format cuda -i /work/reference.mkv \
  -filter_complex "[0:v]scale_cuda=format=yuv420p[dis],[1:v]scale_cuda=format=yuv420p[ref],[dis][ref]libvmaf_cuda" \
  -f null -
```