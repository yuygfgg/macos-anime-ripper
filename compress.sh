#!/bin/bash

# 检查是否提供了目录路径
if [ -z "$1" ]; then
  echo "请提供目录路径。"
  exit 1
fi

# 目标目录
DIR="$1"

# 遍历目录中的每个MKV文件
for FILE in "$DIR"/*.mkv; do
  # 输出文件路径
  OUTPUT="${FILE%.mkv}_compressed.mkv"

  if [[ "$FILE" =~ S[0-9][0-9]E[0-9][0-9]\.mkv ]]; then
    # 正片使用指定的libx265压制，音频压缩为FLAC
    ffmpeg -init_hw_device opencl=gpu:0.0 -filter_hw_device gpu \
    -i "$FILE" \
    -vf "hwupload,nlmeans_opencl=7:3:3.0,hwdownload,unsharp=5:5:0.5:5:5:0.0" \
    -c:v libx265 \
    -preset slower \
    -x265-params "deblock=-1,-1:limit-tu=0:rskip=0:ctu=32:crf=16:pbratio=1.2:cbqpoffs=-3:crqpoffs=-3:sao=0:max-tu-size=16:qg-size=16:me=3:subme=5:merange=32:b-intra=1:amp=0:ref=5:weightb=1:keyint=240:min-keyint=1:bframes=8:aq-mode=3:aq-strength=0.8:rd=5:psy-rd=1.7:psy-rdoq=0.8:rdoq-level=1:rc-lookahead=80:scenecut=40:qcomp=0.65:open-gop=0:vbv-bufsize=42000:vbv-maxrate=35000:strong-intra-smoothing=0:transfer=bt709:colorprim=bt709:colormatrix=bt709:range=limited"\
    -c:a flac "$OUTPUT"
  else
    # 杂项使用videotoolbox进行硬件编码，音频压缩为256k AAC
    ffmpeg -i "$FILE" -c:v hevc_videotoolbox -b:v 3500k -c:a aac -b:a 256k "$OUTPUT"
  fi
done
