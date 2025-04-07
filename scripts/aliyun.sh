#!/bin/bash
set -euo pipefail

ALIYUN_REGISTRY="registry.cn-hangzhou.aliyuncs.com"

# 声明关联数组存储镜像映射
declare -a SOURCE_IMAGES
declare -a TARGET_IMAGES

# 遍历images目录下所有文本文件
for it in images/*.txt; do
  # 获取文件名（不含后缀）
  filename=$(basename "$it" .txt)
  
  # 逐行读取文件内容
  while IFS= read -r line || [[ -n "$line" ]]; do
    # 跳过空行和注释
    [[ -z "${line//[[:space:]]/}" || "$line" =~ ^[[:space:]]*# ]] && continue
    
    # 构造镜像路径
    SOURCE_IMAGES+=("$line")
    TARGET_IMAGES+=("$ALIYUN_REGISTRY/$filename/$(basename ${line%:*}):${line##*:}")
  done < "$it"
done

docker login "ghcr.io" -u "$GHRC_USER" -p "$GHRC_PASSWORD"

# 遍历并输出镜像映射
echo -e "镜像映射列表：\n"
for i in "${!SOURCE_IMAGES[@]}"; do
    echo "SOURCE_IMAGES: ${SOURCE_IMAGES[i]}"
    echo "TARGET_IMAGES: ${TARGET_IMAGES[i]}"
    echo -e "\n"
done

