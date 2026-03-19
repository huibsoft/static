#!/bin/bash

# 微信克隆脚本
# 需要管理员权限

set -e  # 出错时自动退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

set_app_name() {
    local app_name="$1"
    
    echo -e "\n${YELLOW}(只能包含字母、数字、下划线和连字符)${NC}"
    read -p "分身名称(默认: $app_name): " NEW_NAME

    TARGET_NAME="${NEW_NAME}"
    
    if [ -z "$NEW_NAME" ]; then
        TARGET_NAME="$app_name"
    fi

    # 验证格式
    if [[ ! "$TARGET_NAME" =~ ^[a-zA-Z0-9_\-]+$ ]]; then
        echo -e "${RED}错误: 名称 '$TARGET_NAME' 包含非法字符${NC}"
        return 1
    fi

    # 不能为 xinWeChat
    if [[ "$TARGET_NAME" == "xinWeChat" ]]; then
        echo -e "${RED}错误: 名称不能为 xinWeChat${NC}"
        return 1
    fi
    
    BUNDLE_ID="com.tencent.${TARGET_NAME}"
    TARGET_APP="/Applications/${TARGET_NAME}.app"
    echo -e "${GREEN}分身名称: $TARGET_NAME${NC}"
    return 0
}

SOURCE_APP="/Applications/WeChat.app"

# 检查原应用是否存在
if [ ! -d "${SOURCE_APP}" ]; then
    echo -e "${RED}错误: 未找到 ${SOURCE_APP}${NC}"
    exit 1
fi

if ! set_app_name "weixin"; then
    exit 1
fi

# 应用签名
fix_signature() {
    local app_path="$1"

    # 1. 先移除所有签名
    echo -e "${YELLOW}移除现有签名...${NC}"
    sudo codesign --remove-signature "$app_path" 2>/dev/null || true
    
    # 2. 清理扩展属性
    echo -e "${YELLOW}清理扩展属性...${NC}"
    sudo xattr -cr "$app_path" 2>/dev/null || true
    
    # 3. 尝试签名
    echo -e "${YELLOW}应用重新签名...${NC}"
    if sudo codesign --force --deep -s - "$app_path" 2>/dev/null; then
        echo -e  "${GREEN}✓ 应用签名成功${NC}"
        return 0
    fi
    
    echo -e "${RED}✗ 应用签名失败${NC}"
    return 1
}

# 用户确认
confirm_action() {
    local message="$1"
    local default="${2:-n}"
    
    if [[ "$default" == "y" ]]; then
        read -rp "$message[Y/n]: " -n 1 -r
        echo
        [[ $REPLY =~ ^[Nn]$ ]] && return 1
    else
        read -rp "$message[y/N]: " -n 1 -r
        echo
        [[ ! $REPLY =~ ^[Yy]$ ]] && return 1
    fi
    return 0
}

# 检查应用是否正在运行
check_app_running() {
    local app_name="$1"
    if pgrep -f "$app_name" > /dev/null; then
        echo -e "${YELLOW}警告: 检测到 $app_name 正在运行${NC}"
        if confirm_action "是否强制关闭 ${app_name} ？" "y"; then
            pkill -9 -f "$app_name" 2>/dev/null || true
            sleep 1
        else
            return 1
        fi
    fi
    return 0
}

# 验证目标名称合法性
if [[ ! "$TARGET_NAME" =~ ^[a-zA-Z0-9_\-]+$ ]]; then
    echo -e "${RED}错误: 目标名称只能包含字母、数字、下划线和连字符${NC}"
    exit 1
fi

# 检查目标应用是否已存在
if [ -d "${TARGET_APP}" ]; then
    echo -e "${YELLOW}警告: ${TARGET_APP} 已存在${NC}"

    if ! confirm_action "是否覆盖？" "y"; then
        echo "操作已取消"
        exit 0
    fi
        
    check_app_running "$TARGET_NAME" || exit 1
    
    echo -e "${YELLOW}删除旧版本...${NC}"
    sudo rm -rf "${TARGET_APP}"
fi

# 1. 复制应用
echo -e "${GREEN}步骤 1/3: 复制微信应用...${NC}"
sudo cp -R "$SOURCE_APP" "$TARGET_APP"
#if command -v ditto &> /dev/null; then
#    sudo ditto "$SOURCE_APP" "$TARGET_APP"
#else
#    sudo cp -R "$SOURCE_APP" "$TARGET_APP"
#fi

# 检查复制是否成功
if [ ! -d "${TARGET_APP}" ]; then
    echo -e "${RED}错误: 复制失败${NC}"
    exit 1
fi

# 2. 修改 Bundle Identifier
echo -e "${GREEN}步骤 2/3: 修改应用标识...${NC}"
INFO_PLIST="/Applications/${TARGET_NAME}.app/Contents/Info.plist"

# 检查 Info.plist 是否存在
if [ ! -f "$INFO_PLIST" ]; then
    echo -e "${RED}错误: 未找到 Info.plist 文件${NC}"
    exit 1
fi

# 修改 Bundle Identifier
sudo /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $BUNDLE_ID" "$INFO_PLIST" || {
    echo -e "${RED}错误: 修改 Bundle Identifier 失败${NC}"
    echo -e "${YELLOW}尝试使用 plutil 命令...${NC}"
    sudo plutil -replace CFBundleIdentifier -string "$BUNDLE_ID" "$INFO_PLIST"
}

# 验证修改
NEW_IDENTIFIER=$(sudo /usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$INFO_PLIST" 2>/dev/null || echo "")
if [ "$NEW_IDENTIFIER" != "$BUNDLE_ID" ]; then
    echo -e "${RED}警告: Bundle Identifier 可能未正确设置${NC}"
fi

# 3. 重新签名
echo -e "${GREEN}步骤 3/3: 重新签名应用...${NC}"

# 重新签名
if sudo codesign --force --deep --sign - "${TARGET_APP}" 2>/dev/null; then
    echo -e  "${GREEN}✓ 应用签名成功${NC}"
else
    echo -e "${YELLOW}尝试使用 ad-hoc 签名...${NC}"
    if ! fix_signature "${TARGET_APP}"; then
        exit 1
    fi
fi

# 验证签名
if codesign --verify --verbose "$TARGET_APP" 2>&1 | grep -q "valid on disk"; then
    echo -e "${GREEN}✓ 签名验证通过${NC}"
else
    echo -e "${RED}✗ 签名验证失败${NC}"
    exit 1
fi

# 4. 设置权限
sudo chown -R root:wheel "${TARGET_APP}"
sudo chmod -R 755 "${TARGET_APP}"

echo -e "${GREEN}✓ 操作完成！${NC}"
echo -e "${CYAN}微信分身信息:${NC}"
echo -e "  应用标识: ${YELLOW}$BUNDLE_ID${NC}"
echo -e "  应用路径: ${YELLOW}$TARGET_APP${NC}"
echo -e "${CYAN}注意：${NC}"
echo -e "  ${YELLOW}1. 首次启动可能需要到 系统设置 → 隐私与安全性 中允许运行${NC}"
echo -e "  ${YELLOW}2. 如果无法启动，尝试在终端运行: sudo xattr -cr '$TARGET_APP'${NC}"
echo -e "  ${YELLOW}3. 数据目录: ~/Library/Containers/$BUNDLE_ID/${NC}"

# 是否立即启动
if confirm_action "是否立即启动微信分身？" "y"; then
    open "$TARGET_APP"
fi