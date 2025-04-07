#!/bin/bash
set -euo pipefail

# 遍历镜像定义文件
# 函数定义前置
check_image_duplicates() {
    local file=$1
    declare -A temp_map
    while IFS= read -r line || [ -n "$line" ]; do
        [[ -z "$line" ]] || [[ "$line" =~ ^[[:space:]]*# ]] && continue
        
        eval "$(parse_image_info "$line")"
        
        if [[ -n "${temp_map[$image_name]:-}" && "${temp_map[$image_name]:-}" != "${name_space}_" ]]; then
            duplicate_images[$image_name]="true"
        else
            temp_map[$image_name]="${name_space}_"
        fi
    done < "$file"
}

process_image() {
    local line=$1
    local it=$2
    [[ -z "$line" ]] || [[ "$line" =~ ^[[:space:]]*# ]] && return
    
    eval "$(parse_image_info "$line")"
    
    local platform=$(echo "$line" | awk -F'--platform[ =]' '{if (NF>1) print $2}' | awk '{print $1}')
    local platform_prefix=${platform:+${platform//\//_}_}
    
    local name_space_prefix=""
    [[ -n "${duplicate_images[$image_name]:-}" && -n "$name_space" ]] && name_space_prefix="${name_space}_"
    
    local space_name=$(basename "$it" .txt)
    local new_image="$ALIYUN_REGISTRY/$space_name/${platform_prefix}${name_space_prefix}${image_name_tag}"
    
    docker pull "$image"
    docker tag "$image" "$new_image"
    docker push "$new_image"
    docker rmi "$image" "$new_image"
}

parse_image_info() {
    local line=$1
    local image=$(echo "$line" | awk '{print $NF}' | sed 's/@.*//')
    local image_name_tag=$(echo "$image" | awk -F'/' '{print $NF}')
    local name_space=$(echo "$image" | awk -F'/' '{if (NF==3) print $2; else if (NF==2) print $1; else print ""}')
    local image_name=$(echo "$image_name_tag" | awk -F':' '{print $1}')
    
    echo "local image='$image'; local image_name_tag='$image_name_tag';"
    echo "local name_space='$name_space'; local image_name='$image_name';"
}

# 镜像处理函数
process_image() {
    local line=$1
    local it=$2
    [[ -z "$line" ]] || [[ "$line" =~ ^[[:space:]]*# ]] && return
    
    local platform platform_prefix image_info
    
    platform=$(echo "$line" | awk -F'--platform[ =]' '{if (NF>1) print $2}' | awk '{print $1}')
    platform_prefix=${platform:+${platform//\//_}_}
    
    image_info=$(parse_image_info "$line")
    eval "$image_info"
    
    # 构建新镜像名称
    local name_space_prefix=""
    [[ -n "${duplicate_images[$image_name]:-}" && -n "$name_space" ]] && name_space_prefix="${name_space}_"
    
    local space_name new_image
    space_name=$(basename "$it" .txt)
    new_image="$ALIYUN_REGISTRY/$space_name/${platform_prefix}${name_space_prefix}${image_name_tag}"
    
    docker pull "$image"
    docker tag "$image" "$new_image"
    docker push "$new_image"
    docker rmi "$image" "$new_image"
}

# 镜像信息解析函数
parse_image_info() {
    local line=$1
    local image=$(echo "$line" | awk '{print $NF}' | sed 's/@.*//')
    local image_name_tag=$(echo "$image" | awk -F'/' '{print $NF}')
    local name_space=$(echo "$image" | awk -F'/' '{if (NF==3) print $2; else if (NF==2) print $1; else print ""}')
    local image_name=$(echo "$image_name_tag" | awk -F':' '{print $1}')
    
    echo "local image='$image'; local image_name_tag='$image_name_tag';"
    echo "local name_space='$name_space'; local image_name='$image_name';"
}

process_image() {
    local line="$1"
    local it="$2"
    [[ -z "$line" ]] || [[ "$line" =~ ^[[:space:]]*# ]] && return
    
    local platform=$(echo "$line" | awk -F'--platform[ =]' '{if (NF>1) print $2}' | awk '{print $1}')
    local platform_prefix=${platform:+${platform//\//_}_}
    
    eval "$(parse_image_info "$line")"
    
    local name_space_prefix=""
    [[ -n "${duplicate_images[$image_name]:-}" && -n "$name_space" ]] && name_space_prefix="${name_space}_"
    
    local space_name=$(basename "$it" .txt)
    local new_image="$ALIYUN_REGISTRY/$space_name/${platform_prefix}${name_space_prefix}${image_name_tag}"
    
    docker pull "$image"
    docker tag "$image" "$new_image"
    docker push "$new_image"
    docker rmi "$image" "$new_image"
}

parse_image_info() {
    local line="$1"
    local image=$(echo "$line" | awk '{print $NF}' | sed 's/@.*//')
    local image_name_tag=$(echo "$image" | awk -F'/' '{print $NF}')
    local name_space=$(echo "$image" | awk -F'/' '{if (NF==3) print $2; else if (NF==2) print $1; else print ""}')
    local image_name=$(echo "$image_name_tag" | awk -F':' '{print $1}')
    
    echo "local image='$image'; local image_name_tag='$image_name_tag';"
    echo "local name_space='$name_space'; local image_name='$image_name';"
}

# Docker 登录认证
docker login -u "$ALIYUN_REGISTRY_USER" -p "$ALIYUN_REGISTRY_PASSWORD" "$ALIYUN_REGISTRY"
# 主循环
for it in images/*; do
    declare -A duplicate_images
    check_image_duplicates "$it"
    
    while IFS= read -r line || [ -n "$line" ]; do
        process_image "$line" "$it"
    done < "$it"
done