#!/bin/bash
set -euo pipefail

# Docker 登录认证
docker login -u "$ALIYUN_REGISTRY_USER" -p "$ALIYUN_REGISTRY_PASSWORD" "$ALIYUN_REGISTRY"

# 遍历镜像定义文件
for it in images/*; do
    # 镜像重复检查逻辑
    declare -A duplicate_images
    declare -A temp_map
    
    while IFS= read -r line || [ -n "$line" ]; do
        [[ -z "$line" ]] || [[ "$line" =~ ^[[:space:]]*# ]] && continue
        
        image=$(echo "$line" | awk '{print $NF}' | sed 's/@.*//')
        image_name_tag=$(echo "$image" | awk -F'/' '{print $NF}')
        name_space=$(echo "$image" | awk -F'/' '{if (NF==3) print $2; else if (NF==2) print $1; else print ""}')
        image_name=$(echo "$image_name_tag" | awk -F':' '{print $1}')
        
        if [[ -n "${temp_map[$image_name]}" && "${temp_map[$image_name]}" != "${name_space}_" ]]; then
            duplicate_images[$image_name]="true"
        else
            temp_map[$image_name]="${name_space}_"
        fi
    done < "$it"

    # 镜像处理逻辑
    while IFS= read -r line || [ -n "$line" ]; do
        [[ -z "$line" ]] || [[ "$line" =~ ^[[:space:]]*# ]] && continue
        
        platform=$(echo "$line" | awk -F'--platform[ =]' '{if (NF>1) print $2}' | awk '{print $1}')
        platform_prefix=${platform:+${platform//\//_}_}
        
        image=$(echo "$line" | awk '{print $NF}' | sed 's/@.*//')
        image_name_tag=$(echo "$image" | awk -F'/' '{print $NF}')
        name_space=$(echo "$image" | awk -F'/' '{if (NF==3) print $2; else if (NF==2) print $1; else print ""}')
        image_name=$(echo "$image_name_tag" | awk -F':' '{print $1}')

        # 构建新镜像名称
        name_space_prefix=""
        [[ -n "${duplicate_images[$image_name]}" && -n "$name_space" ]] && name_space_prefix="${name_space}_"
        
        space_name=$(basename "$it" .txt)
        new_image="$ALIYUN_REGISTRY/$space_name/${platform_prefix}${name_space_prefix}${image_name_tag}"
        
        # 执行镜像操作
        docker pull "$image"
        docker tag "$image" "$new_image"
        docker push "$new_image"
        
        # 清理镜像
        docker rmi "$image" "$new_image"
    done < "$it"
done