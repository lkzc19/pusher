#!/opt/homebrew/Cellar/bash/5.2.37/bin/bash
set -euo pipefail

ALIYUN_REGISTRY="registry.cn-hangzhou.aliyuncs.com"

declare -A IMAGE_MAP
declare -A REPO_MAP
declare -a REPO_KEYS

# 遍历images目录下所有文本文件
for it in images/*.txt; do
  # 获取文件名（不含后缀）
  filename=$(basename "$it" .txt)
  
  # 逐行读取文件内容
  while IFS= read -r line || [[ -n "$line" ]]; do
    # 跳过空行和注释
    [[ -z "${line//[[:space:]]/}" || "$line" =~ ^[[:space:]]*# ]] && continue

    # 提取仓库前缀
    if [[ "$line" =~ / ]]; then
        repo="${line%%/*}"
    else
        repo="docker.io"
    fi
    
    # 按仓库分类存储
    if [[ -z "${REPO_MAP[$repo]+_}" ]]; then
        REPO_KEYS+=("$repo")
        repo_var="REPO_IMAGES_${repo//./_}"
        declare -a "$repo_var"
        REPO_MAP["$repo"]="$repo_var"
    fi
    eval "${REPO_MAP[$repo]}+=(\"$line\")"

    # 原始镜像和目标镜像的映射
    IMAGE_MAP["$line"]="$ALIYUN_REGISTRY/$filename/$(basename ${line%:*}):${line##*:}"
  done < "$it"
done

# docker login "ghcr.io" -u "$GHCR_USER" -p "$GHCR_PASSWORD"

# 遍历并输出镜像映射
echo -e "镜像映射列表：\n"
for key in "${!IMAGE_MAP[@]}"; do
    echo "原始镜像: $key"
    echo "目标镜像: ${IMAGE_MAP[$key]}"
    
    echo -e "\n"
done


