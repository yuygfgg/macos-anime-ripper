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
  OUTPUT="${FILE%.mkv}_compressed1.mkv"

  if [[ "$FILE" =~ S[0-9][0-9]E[0-9][0-9]\.mkv ]]; then
    # 正片使用指定的libx265压制，音频压缩为FLAC
    ffmpeg -init_hw_device opencl=gpu:0.0 -filter_hw_device gpu -i "$FILE" \
    -vf "hwupload,nlmeans_opencl=7:3:3.0,hwdownload,unsharp=5:5:0.5:5:5:0.0" -c:v libx265 \
    -preset veryslow \
    -x265-params "crf=18.5:qcomp=0.65:qg-size=16:rect=0:amp=0:ctu=32:limit-tu=3:tu-intra-depth=3:tu-inter-depth=3:me=star:subme=4:rc-grain=0:merange=32:open-gop=0:min-keyint=1:ref=5:keyint=240:ipratio=1.2:pbratio=1.3:bframes=10:aq-mode=1:aq-strength=0.75:rd=5:deblock=-1,-1:colormatrix=bt709:rc-lookahead=80:range=limited:psy-rdoq=0.5:rdoq-level=2:psy-rd=1.5:cbqpoffs=-2:crqpoffs=-2:strong-intra-smoothing=0:sao=0" \
    -c:a flac "$OUTPUT"
  else
    # 杂项使用videotoolbox进行硬件编码，音频压缩为256k AAC
    ffmpeg -i "$FILE" -c:v hevc_videotoolbox -b:v 3500k -c:a aac -b:a 256k "$OUTPUT"
  fi
done
