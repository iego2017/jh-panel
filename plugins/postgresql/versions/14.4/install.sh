#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#https://www.postgresql.org/ftp/source/

curPath=`pwd`
rootPath=$(dirname "$curPath")
rootPath=$(dirname "$rootPath")
serverPath=$(dirname "$rootPath")
sysName=`uname`

install_tmp=${rootPath}/tmp/mw_install.pl
postgreDir=${serverPath}/source/postgresql

VERSION=14.4

# su - postgres -c "/www/server/postgresql/bin/pg_ctl start -D /www/server/postgresql/data"

Install_App()
{
	mkdir -p ${postgreDir}
	echo '正在安装脚本文件...' > $install_tmp

	if id postgres &> /dev/null ;then 
	    echo "postgres uid is `id -u postgres`"
	    echo "postgres shell is `grep "^postgres:" /etc/passwd |cut -d':' -f7 `"
	else
	    groupadd postgres
		useradd -g postgres postgres
	fi

	if [ ! -d /home/postgres ];then
		mkdir -p /home/postgres
	fi

	if [ "$sysName" != "Darwin" ];then
		mkdir -p /var/log/mariadb
		touch /var/log/mariadb/mariadb.log
	fi

	# ----- cpu start ------
	if [ -z "${cpuCore}" ]; then
    	cpuCore="1"
	fi

    if [ -f /proc/cpuinfo ];then
		cpuCore=`cat /proc/cpuinfo | grep "processor" | wc -l`
    fi

	MEM_INFO=$(free -m|grep Mem|awk '{printf("%.f",($2)/1024)}')
	if [ "${cpuCore}" != "1" ] && [ "${MEM_INFO}" != "0" ];then
	    if [ "${cpuCore}" -gt "${MEM_INFO}" ];then
	        cpuCore="${MEM_INFO}"
	    fi
	else
	    cpuCore="1"
	fi

	# for stable installation
	if [ "$cpuCore" -gt "1" ];then
		cpuCore=`echo "$cpuCore" | awk '{printf("%.f",($1)*0.8)}'`
	fi
	# ----- cpu end ------

	if [ ! -f ${postgreDir}/postgresql-${VERSION}.tar.bz2 ];then
		wget --no-check-certificate -O ${postgreDir}/postgresql-${VERSION}.tar.bz2 --tries=3 https://ftp.postgresql.org/pub/source/v${VERSION}/postgresql-${VERSION}.tar.bz2
	fi

	if [ ! -d ${postgreDir}/postgresql-${VERSION} ];then
		cd ${postgreDir} && tar -jxvf  ${postgreDir}/postgresql-${VERSION}.tar.bz2
	fi
	

	if [ ! -d $serverPath/postgresql ];then
		cd ${postgreDir}/postgresql-${VERSION} && ./configure \
		--prefix=$serverPath/postgresql \
		--with-openssl
		# --with-pgport=33067

		echo "cd ${postgreDir}/postgresql-${VERSION} && ./configure \
		--prefix=$serverPath/postgresql \
		--with-openssl"
		# --with-pgport=33067
		make -j${cpuCore} && make install && make clean
	fi

	if [ -d $serverPath/postgresql ];then
		echo "${VERSION}" > $serverPath/postgresql/version.pl
		echo 'install successful' > $install_tmp
	else
		echo 'install fail' > $install_tmp
	fi
}

Uninstall_App()
{
	rm -rf $serverPath/postgresql
	echo '卸载完成' > $install_tmp
}

action=$1
if [ "${1}" == "install" ];then
	Install_App
else
	Uninstall_App
fi
