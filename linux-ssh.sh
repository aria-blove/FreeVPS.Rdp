#!/bin/bash

# بررسی وجود Secrets ضروری
if [[ -z "$LINUX_USER_PASSWORD" ]]; then
  echo "Please set 'LINUX_USER_PASSWORD' for user: $LINUX_USERNAME"
  exit 3
fi

# ایجاد کاربر و تنظیمات
sudo useradd -m $LINUX_USERNAME
sudo adduser $LINUX_USERNAME sudo
echo "$LINUX_USERNAME:$LINUX_USER_PASSWORD" | sudo chpasswd
sudo sed -i 's/\/bin\/sh/\/bin\/bash/g' /etc/passwd
sudo hostname $LINUX_MACHINE_NAME

echo "### نصب tmate ###"
sudo apt update
sudo apt install -y tmate

echo "### تنظیم رمز کاربر ###"
echo -e "$LINUX_USER_PASSWORD\n$LINUX_USER_PASSWORD" | sudo passwd "$LINUX_USERNAME"

echo "### راه‌اندازی جلسه tmate ###"

# ایجاد جلسه tmate در background
tmate -S /tmp/tmate.sock new-session -d
tmate -S /tmp/tmate.sock wait tmate-ready

# گرفتن آدرس SSH
SSH_ADDR=$(tmate -S /tmp/tmate.sock display -p '#{tmate_ssh}')

echo ""
echo "=========================================="
echo "✅ سرور لینوکس شما آماده است!"
echo ""
echo "🔗 برای اتصال SSH، این آدرس را در PuTTY یا ترمینال وارد کنید:"
echo ""
echo "$SSH_ADDR"
echo ""
echo "=========================================="
echo "⚠️ توجه: این سرور به مدت 6 ساعت فعال خواهد ماند."
echo "=========================================="

# نگه داشتن جلسه به مدت 6 ساعت
sleep 21600
