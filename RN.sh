#!/bin/bash
#
# Parallels Desktop 
#

set -euo pipefail

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${GREEN}[✓]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
err()  { echo -e "${RED}[✗]${NC} $*"; }

# 记录调用 sudo 的真实用户
REAL_USER="${SUDO_USER:-$USER}"
if [[ "$REAL_USER" == "root" ]]; then
  err "无法确定真实用户，请使用 sudo 运行，而不是直接以 root 身份运行。"
  exit 1
fi

# 获取真实用户 HOME
REAL_HOME=$(dscl . -read "/Users/${REAL_USER}" NFSHomeDirectory 2>/dev/null | awk '{print $2}')
if [[ -z "$REAL_HOME" || ! -d "$REAL_HOME" ]]; then
  err "无法确定用户 ${REAL_USER} 的Home目录。"
  exit 1
fi

# ---------- 查找虚拟机文件 ----------
SEARCH_DIRS=("${REAL_HOME}/Parallels" "/Users/Shared/Parallels")

echo
echo "========================================================"
echo

for dir in "${SEARCH_DIRS[@]}"; do
  [ -d "$dir" ] || continue
  while IFS= read -r -d '' pvm; do
    chmod -RN "$pvm"
    log "$pvm 权限修复完成！"
  done < <(find "$dir" -maxdepth 6 -type d -iname "*.pvm" -print0 2>/dev/null)
done

echo
echo "========================================================"
echo "请重新启动 Parallels Desktop 生效！"
echo