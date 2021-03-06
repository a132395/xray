#/bin/bash
depend(){
apt-get update -y && apt-get upgrade -y
apt-get install wget socat curl zip -y
read -p "请输入域名:" domain
echo "您输入的域名是：$domain"
}

ngx(){
apt-get install nginx  -y
systemctl restart nginx || /etc/init.d/nginx restart
}

install_acme(){
if [ ! -d "/root/.acme.sh" ]; then
echo "安装acme.sh"
curl  https://get.acme.sh | sh > /dev/null
echo "alias acme.sh=~/.acme.sh/acme.sh" >> /root/.bashrc
source /root/.bashrc
echo "acme.h 安装完成!"
fi
}

acme_cer(){
echo "生成证书中……"
systemctl stop nginx || /etc/init.d/nginx stop
/root/.acme.sh/acme.sh  --issue -d $domain  --standalone --force
if [ $? == 0 ]; then
echo "证书生成完成！"
else
echo "安装证书，请检查配置或者重新安装！"
exit 2
fi
systemctl start nginx || /etc/init.d/nginx start

}

acme_cer_renew(){
read -p "请输入域名:" renewdomain
echo "您输入的域名是：$renewdomain"
echo "生成证书中……"
systemctl stop nginx || /etc/init.d/nginx stop
/root/.acme.sh/acme.sh  --issue -d $renewdomain  --standalone --force
systemctl start nginx || /etc/init.d/nginx start
echo "证书生成完成！"
}

xray(){
echo "开始安装/更新xray"
bash <(curl -L https://raw.githubusercontent.com/XTLS/Xray-install/main/install-release.sh)  > /dev/null
if [ $? == 0 ]; then
echo "xray 安装完成！"
systemctl restart xray
else
echo "安装xray失败，请检查网络或者重新安装！"
exit 2
fi
}

change_xrayconf(){
wget -qO  /usr/local/etc/xray/config.json  https://raw.githubusercontent.com/huya1121/xray/master/config.json
ouid=`sed -n '16p' /usr/local/etc/xray/config.json | awk -F'"' '{print $4}'`
uid=`cat /proc/sys/kernel/random/uuid`
sed -i "s/$ouid/$uid/g" /usr/local/etc/xray/config.json
systemctl restart xray
}

conf_nginx(){
wget -qO /etc/nginx/sites-available/xray.conf https://raw.githubusercontent.com/huya1121/xray/master/xray.conf
ln -s /etc/nginx/sites-available/xray.conf /etc/nginx/sites-enabled/xray.conf
sed -i "s/abc.com/$domain/g" /etc/nginx/sites-available/xray.conf
systemctl restart nginx || /etc/init.d/nginx restart
}

xray_info(){
echo "服务器配置信息如下:"
echo "服务器: $domain"
echo "端口：443"
echo "AlterID：64"
echo "UUID：$uid"
echo "PATH：/api/"
echo "WS+TLS"
echo "安装完成"
}

install(){
depend
ngx
install_acme
acme_cer
xray
change_xrayconf
conf_nginx
xray_info
exit 0
}

#main
case $1 in
  install | start)
  install
  ;;
  renew)
  acme_cer_renew
  ;;
  *)
  echo "please use bash xray.sh install or bash xray.sh renew"
  ;;
esac

