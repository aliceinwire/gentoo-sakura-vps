# Gentoo Linux インストールスクリプト (さくらVPS v3)

## 使い方

https://github.com/aliceinwire/gentoo-sakura-vps.git のとおりです。

#### tag "kernel-3.5.7"が最新です。


### OS再インストール

CentOS 6.2 x86_64 (デフォルト) でOS再インストールを実行します。
設定したrootパスワードが新システムでも使われます。

### リモートコンソール

Scriptをクローンします。

    cd /root
    git clone git://github.com/rkmathi/gentoo-sakura-vps

make.confを適宜編集し、bootstrap-0-prepare.shを実行します。

    cd /root/gentoo-sakura-vps
    vi make.conf
    ./scripts/bootstrap-0-prepare.sh
    reboot

再起動後、メニューから `Gentoo install` を選択し、Gentooが起動したらbootstrap-1-base.shを実行します。

    cd /root/gentoo-sakura-vps
    ./scripts/bootstrap-1-base.sh
    reboot

再起動後、 root でログイン(パスワードはOS再インストール時のもの)し、ユーザーの作成と公開鍵の設定等を行います。

最後に、bootstrap-3-finalize.shを実行します。

    cd /root/gentoo-sakura-vps
    ./scripts/bootstrap-3-finalize.sh
    reboot

Enjoy your Gentoo Linuxヾ(＠⌒ー⌒＠)ノ
