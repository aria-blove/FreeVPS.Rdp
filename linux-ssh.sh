#!/bin/bash

# بررسی وجود Secrets ضروری
if [[ -z "$NGROK_AUTH_TOKEN" ]]; then
  echo "Please set 'NGROK_AUTH_TOKEN'"
  exit 2
fi

if [[ -z "$LINUX_USER_PASSWORD" ]]; then
  echo "Please set 'LINUX_USER_PASSWORD' for user: $LINUX_USERNAME"
  exit 3
fi

# ایجاد کاربر و تنظیمات
sudo useradd -m $LINUX_USERNAME
sudo adduser $LINUX_USERNAME sudo
echo "$LINUX_USERNAME:$LINUX_USER_PASSWORD" | sudo chpasswd
sed -i 's/\/bin\/sh/\/bin\/bash/g' /etc/passwd
sudo hostname $LINUX_MACHINE_NAME

echo "### نصب ngrok (نسخه جدید) ###"

# روش جدید نصب ngrok (حل مشکل ERR_NGROK_121)
curl -sSL https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null
echo "deb https://ngrok-agent.s3.amazonaws.com bookworm main" | sudo tee /etc/apt/sources.list.d/ngrok.list
sudo apt update
sudo apt install -y ngrok

echo "### تنظیم رمز کاربر ###"
echo -e "$LINUX_USER_PASSWORD\n$LINUX_USER_PASSWORD" | sudo passwd "$LINUX_USERNAME"

echo "### شروع تونل ngrok برای پورت 22 ###"

# حذف فایل لاگ قبلی
rm -f .ngrok.log

# تنظیم توکن و اجرای ngrok
ngrok config add-authtoken "$NGROK_AUTH_TOKEN"
ngrok tcp 22 --log ".ngrok.log" &

sleep 10

# بررسی خطا
HAS_ERRORS=$(grep "command failed" < .ngrok.log)

if [[ -z "$HAS_ERRORS" ]]; then
  echo ""
  echo "=========================================="
  echo "✅ برای اتصال SSH، از این آدرس استفاده کنید:"
  echo ""
  # استخراج آدرس tcp از لاگ
  NGROK_ADDR=$(grep -o -E "tcp://(.+)" < .ngrok.log | head -1)
  if [[ -n "$NGROK_ADDR" ]]; then
    echo "$NGROK_ADDR" | sed "s/tcp:\/\//ssh $LINUX_USERNAME@/" | sed "s/:/ -p /"
  else
    echo "⚠️ آدرس در لاگ پیدا نشد. لطفاً لاگ را بررسی کنید."
  fi
  echo "=========================================="
else
  echo "❌ خطا در اجرای ngrok:"
  echo "$HAS_ERRORS"
  exit 4
fi
