# 本地的bash环境与actions不同, 执行时指定bash环境

set -euo pipefail

docker login -u $ALIYUN_REGISTRY_USER -p $ALIYUN_REGISTRY_PASSWORD $ALIYUN_REGISTRY

for it in images/*.txt; do
  # 清理文件名（只允许字母、数字、点、下划线、短横线）
  NAMESPACE="$(basename "$it" .txt | tr -cd '[:alnum:]._-')"
  
  declare -A processed_images  # 当前文件的去重检查
  line_number=0

  while IFS= read -r line || [[ -n "$line" ]]; do
    line_number=$((line_number + 1))
    
    # 忽略空行与注释
    [[ -z "$line" ]] && continue
    if echo "$line" | grep -q '^\s*#'; then
        continue
    fi

    # 检查当前文件内重复
    if [[ -n "${processed_images[$line]:-}" ]]; then
      echo "[$it 第${line_number}行] 镜像重复: $line"
      continue
    fi
    processed_images["$line"]=1

    # windows换行符处理 & 删除多余的空白符
    line="$(echo "$line" | tr -d '\r' | xargs)"
    # 去掉域名部分(保留最后一个/之后的部分)
    image_tag="${line##*/}"       
    
    # 构建目标镜像名
    new_image="$ALIYUN_REGISTRY/$NAMESPACE/$image_tag"
    printf '新镜像: %q\n' "$new_image"

    docker pull "$line"
    docker tag "$line" "$new_image"
    docker push "$new_image"
    docker rmi "$line" "$new_image"
  done < "$it"
done
