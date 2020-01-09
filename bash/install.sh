#!/bin/bash

# bash 版本
version=0.2

build_path=/opt/down
mkdir -p ${build_path}

install_path=/opt/openresty
mkdir -p ${install_path}

install_version=1.15.8.2
#1.11.2.2 nginx 1.11.2 , 1.11.2.1 nginx 1.11.2 , 1.9.15.1 nginx 1.9.15
openresty_uri=https://openresty.org/download/openresty-${install_version}.tar.gz

# centos 6 = remi-release-6.rpm ; centos 7 = remi-release-7.rpm
rpm_uri=http://rpms.famillecollet.com/enterprise/remi-release-7.rpm

purge_version=2.3
purge_uri=http://labs.frickle.com/files/ngx_cache_purge-${purge_version}.tar.gz

function YUM_start(){
    yum install -y htop goaccess dos2unix epel-release
    rpm -Uvh ${rpm_uri}
    yum groupinstall -y "Development tools"
    yum install -y wget make gcc readline-devel perl pcre-devel openssl-devel git unzip zip
}

#安装jemalloc最新版本
jemalloc_install(){
    cd ${build_path}
    wget https://github.com/jemalloc/jemalloc/releases/download/5.2.1/jemalloc-5.2.1.tar.bz2 || (echo "wget jemalloc Error" && exit 1)
    tar -xvf jemalloc-5.2.1.tar.bz2 || (echo "tar -xvf jemalloc-xxx.tar.bz2 Error" && exit 1)
    cd jemalloc-5.2.1
    ./configure || (echo "configure jemalloc Error" && exit 1)
    make && make install
    echo '/usr/local/lib' > /etc/ld.so.conf.d/local.conf
    ldconfig
}

function openresty(){
    jemalloc_install
    cd ${build_path}
    rm -rf openresty-${install_version}.tar.gz
    wget ${openresty_uri}
    tar zxvf openresty-${install_version}.tar.gz

    rm -rf ngx_cache_purge-${purge_version}.tar.gz
    wget ${purge_uri}
    tar zxvf ngx_cache_purge-${purge_version}.tar.gz

    cd ${build_path}/openresty-${install_version}
    ./configure --prefix=${install_path} --with-http_realip_module --with-http_v2_module --with-http_stub_status_module\
                --with-ld-opt='-ljemalloc' \
                --add-module=./../ngx_cache_purge-${purge_version}
    gmake
    gmake install

    chown nobody:nobody -R ${install_path}
    cd ${install_path}
    chown root:nobody nginx/sbin/nginx
    chmod 751 nginx/sbin/nginx
    chmod u+s nginx/sbin/nginx
}

function echo_ServerMsg(){
    #### 查看服务器信息 版本、内存、CPU 等等 ####
    echo "uname －a"
    uname -a
    echo "##########################"
    echo "cat /proc/version"
    cat /proc/version
    echo "##########################"
    echo "cat /proc/cpuinfo"
    cat /proc/cpuinfo
    echo "##########################"
    echo " cat /etc/issue  或cat /etc/redhat-release"
    cat /etc/redhat-release 2>/dev/null || cat /etc/issue
    echo "##########################"
    echo "getconf LONG_BIT  （Linux查看版本说明当前CPU运行在32bit模式下， 但不代表CPU不支持64bit）"
    getconf LONG_BIT
    echo "./install.sh install | openstar | openresty | check"
}

function check(){
    mkdir -p ${install_path}/nginx/conf/conf.d
    chown nobody:nobody -R ${install_path}
    chown root:nobody ${install_path}/nginx/sbin/nginx
    chmod 751 ${install_path}/nginx/sbin/nginx
    chmod u+s ${install_path}/nginx/sbin/nginx
    ln -sf ${install_path}/dynamic_upstream/conf/nginx.conf ${install_path}/nginx/conf/nginx.conf
    ln -sf ${install_path}/dynamic_upstream/conf/backend_demo.conf ${install_path}/nginx/conf/backend_demo.conf
    cd ${install_path}/nginx/html && (ls |grep "favicon.ico" || wget https://www.nginx.org/favicon.ico)
    cat /etc/profile |grep "openresty" ||(echo "PATH=${install_path}/nginx/sbin:\$PATH" >> /etc/profile && export PATH)
    echo "check Done~!"
}

##############################
if [ "$1" = "install" ];then
    YUM_start

    openresty

    ##############################
    cat /etc/profile |grep "openresty" ||(echo "PATH=${install_path}/nginx/sbin:\$PATH" >> /etc/profile && export PATH)

elif [ "$1" = "yum" ]; then
    YUM_start

elif [ "$1" = "openresty" ]; then
    openresty
    cat /etc/profile |grep "openresty" ||(echo "PATH=${install_path}/nginx/sbin:\$PATH" >> /etc/profile && export PATH)

elif [ "$1" = "check" ]; then

    check

else
    echo_ServerMsg
fi
