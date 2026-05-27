#!/bin/bash
# ==========================================
# 一键部署到 GitHub Pages
# 用法: source .env && bash setup.sh
# ==========================================

set -e

# 加载 .env
if [ ! -f .env ]; then
  echo "❌ 未找到 .env 文件。请先复制 .env.template 并填写："
  echo "   cp .env.template .env"
  echo "   然后编辑 .env 填入你的 GitHub 信息"
  exit 1
fi
source .env

# 检查必填字段
MISSING=""
[ -z "$GITHUB_USER" ] && MISSING="$MISSING GITHUB_USER"
[ -z "$GITHUB_TOKEN" ] && MISSING="$MISSING GITHUB_TOKEN"
[ -z "$GIT_USER_NAME" ] && MISSING="$MISSING GIT_USER_NAME"
[ -z "$GIT_USER_EMAIL" ] && MISSING="$MISSING GIT_USER_EMAIL"

if [ -n "$MISSING" ]; then
  echo "❌ 以下字段未填写: $MISSING"
  echo "   请编辑 .env 补全后再运行"
  exit 1
fi

REPO_NAME="${GITHUB_USER}.github.io"

echo "========================================"
echo "  部署聚变装置目录 → GitHub Pages"
echo "  GitHub: $GITHUB_USER"
echo "  Repo:   $REPO_NAME"
echo "========================================"

# 配置 git
cd "$(dirname "$0")"
git init
git config user.name "$GIT_USER_NAME"
git config user.email "$GIT_USER_EMAIL"

# 确保 .env 不会被提交
echo ".env" >> .gitignore 2>/dev/null

# 提交
git add -A
git commit -m "聚变装置目录 v2 — 初始部署"

# 设置 remote（用 token 做认证）
git remote add origin "https://${GITHUB_USER}:${GITHUB_TOKEN}@github.com/${GITHUB_USER}/${REPO_NAME}.git"

# 检查 repo 是否存在（用 API 验证 token 和 repo）
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/repos/${GITHUB_USER}/${REPO_NAME}")

if [ "$HTTP_CODE" = "200" ]; then
  echo "✓ 仓库已存在，将强制推送"
  git push -f origin main:main
elif [ "$HTTP_CODE" = "404" ]; then
  echo "⚠  仓库 ${REPO_NAME} 不存在，正在创建..."
  curl -s -X POST \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/user/repos" \
    -d "{\"name\":\"${REPO_NAME}\",\"description\":\"磁约束聚变装置目录\",\"homepage\":\"https://${GITHUB_USER}.github.io/\"}" > /dev/null
  echo "✓ 仓库已创建"
  git push -u origin main:main
else
  echo "❌ GitHub API 响应 $HTTP_CODE，请检查 token 权限"
  echo "   确保 token 有 repo 和 pages 权限"
  exit 1
fi

# 启用 GitHub Pages（从 main 分支根目录）
echo "正在启用 GitHub Pages..."
curl -s -X PUT \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/${GITHUB_USER}/${REPO_NAME}/pages" \
  -d "{\"source\":{\"branch\":\"main\",\"path\":\"/\"}}" > /dev/null

echo ""
echo "========================================"
echo "✅ 部署完成！"
echo "   站点地址: https://${GITHUB_USER}.github.io/"
echo ""
echo "   GitHub Pages 需要几分钟才能首次生效。"
echo "   通常 1-5 分钟后可访问。"
echo "========================================"
