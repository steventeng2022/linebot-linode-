#!/usr/bin/env bash
set -euo pipefail

APP_REPO="https://github.com/steventeng2022/116-linebot.git"
APP_SOURCE="/opt/lineb-source"
APP_DIR="/opt/lineb"
APP_USER="lineb"

if [[ "${EUID}" -ne 0 ]]; then
  echo "請使用 root 執行此腳本。" >&2
  exit 1
fi

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y python3 python3-venv nginx git

if ! id "${APP_USER}" >/dev/null 2>&1; then
  useradd --system --home /nonexistent --shell /usr/sbin/nologin "${APP_USER}"
fi

if [[ -d "${APP_SOURCE}/.git" ]]; then
  git -C "${APP_SOURCE}" fetch --prune origin
  git -C "${APP_SOURCE}" checkout main
  git -C "${APP_SOURCE}" reset --hard origin/main
else
  git clone "${APP_REPO}" "${APP_SOURCE}"
fi

install -d -o "${APP_USER}" -g "${APP_USER}" -m 750 "${APP_DIR}" /var/lib/lineb
python3 -m venv "${APP_DIR}/.venv"
"${APP_DIR}/.venv/bin/pip" install --upgrade pip
"${APP_DIR}/.venv/bin/pip" install -r "${APP_SOURCE}/requirements.txt"
install -o "${APP_USER}" -g "${APP_USER}" -m 640 "${APP_SOURCE}/main.py" "${APP_DIR}/main.py"

if [[ ! -f /etc/lineb/lineb.env ]]; then
  install -d -o root -g "${APP_USER}" -m 750 /etc/lineb
  install -o root -g "${APP_USER}" -m 640 "${APP_SOURCE}/.env.example" /etc/lineb/lineb.env
  echo "請先編輯 /etc/lineb/lineb.env，再重新執行部署。" >&2
  exit 1
fi

install -o root -g root -m 644 "$(dirname "$0")/lineb.service" /etc/systemd/system/lineb.service
if [[ ! -f /etc/nginx/sites-available/lineb ]]; then
  install -o root -g root -m 644 "$(dirname "$0")/nginx-bot.steventeng.uk.conf" /etc/nginx/sites-available/lineb
else
  echo "保留既有 Nginx／Certbot HTTPS 設定。"
fi
ln -sfn /etc/nginx/sites-available/lineb /etc/nginx/sites-enabled/lineb

systemctl daemon-reload
systemctl enable --now lineb.service
nginx -t
systemctl reload nginx

echo "部署完成："
systemctl --no-pager --full status lineb.service | head -n 12
