#!/bin/bash

WALLPAPER_DIR="$HOME/wallpapers"   # 请替换为你的壁纸目录
LAST_WALLPAPER_FILE="$HOME/.last_wallpaper" # 用于记录上一次壁纸的文件

# 获取所有图片文件的列表
mapfile -t ALL_PICS < <(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.bmp" -o -iname "*.gif" \))

# 如果没有找到任何图片，报错退出
if [ ${#ALL_PICS[@]} -eq 0 ]; then
    echo "错误：在 $WALLPAPER_DIR 中没有找到图片文件。"
    exit 1
fi

# 读取上一次的壁纸（如果存在）
if [ -f "$LAST_WALLPAPER_FILE" ]; then
    LAST_PIC=$(cat "$LAST_WALLPAPER_FILE")
else
    LAST_PIC=""
fi

# 如果总图片数大于1，则排除上一次的图片，否则（只有一张图）就只能选它
if [ ${#ALL_PICS[@]} -gt 1 ] && [ -n "$LAST_PIC" ]; then
    # 创建一个新数组，包含除上一次图片外的所有图片
    CANDIDATES=()
    for pic in "${ALL_PICS[@]}"; do
        if [ "$pic" != "$LAST_PIC" ]; then
            CANDIDATES+=("$pic")
        fi
    done
else
    # 如果只有一张图，或者没有上一次记录，则候选列表就是所有图片
    CANDIDATES=("${ALL_PICS[@]}")
fi

# 从候选列表中随机选择一张
WALLPAPER=${CANDIDATES[RANDOM % ${#CANDIDATES[@]}]}

# 用 awww 设置壁纸（假设子命令为 img，请根据你的 awww 版本调整）
/usr/bin/awww img "$WALLPAPER"

# 将本次选择的壁纸保存到记录文件中，供下次使用
echo "$WALLPAPER" > "$LAST_WALLPAPER_FILE"
