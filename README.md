# LINE Bot Linode 部署

這個儲存庫存放 `steventeng2022/116-linebot` 的 Linode 部署設定，不存放任何密碼、LINE Token 或學生資料。

## 檔案

- `deploy.sh`：安裝或更新應用程式
- `lineb.service`：systemd 常駐服務
- `nginx-bot.steventeng.uk.conf`：Nginx 反向代理與登入限速

## 部署

```bash
chmod +x deploy.sh
sudo ./deploy.sh
```

正式環境變數位於 `/etc/lineb/lineb.env`，資料庫位於 `/var/lib/lineb/lineb.db`。兩者都不應提交到 GitHub。

HTTPS 憑證可在 DNS 指向伺服器後使用 Certbot 建立：

```bash
sudo certbot --nginx -d bot.steventeng.uk
```
