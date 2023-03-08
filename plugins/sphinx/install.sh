#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

curPath=`pwd`
rootPath=$(dirname "$curPath")
rootPath=$(dirname "$rootPath")
serverPath=$(dirname "$rootPath")
sysName=`uname`

install_tmp=${rootPath}/tmp/mw_install.pl


bash ${rootPath}/scripts/getos.sh
OSNAME=`cat ${rootPath}/data/osname.pl`
OSNAME_ID=`cat /etc/*-release | grep VERSION_ID | awk -F = '{print $2}' | awk -F "\"" '{print $2}'`

if [ ${OSNAME} == "centos" ] || 
	[ ${OSNAME} == "fedora" ] ||
	[ ${OSNAME} == "alma" ]; then
	yum install -y postgresql-libs unixODBC
fi

Install_sphinx()
{

	echo '正在安装脚本文件...' > $install_tmp
	mkdir -p $serverPath/sphinx

	SPHINX_DIR=${serverPath}/source/sphinx
	mkdir -p $SPHINX_DIR
	
	if [ ! -f ${SPHINX_DIR}/sphinx-3.1.1.tar.gz ];then
		if [ $sysName == 'Darwin' ]; then
			wget -O ${SPHINX_DIR}/sphinx-3.1.1.tar.gz http://sphinxsearch.com/files/sphinx-3.1.1-612d99f-darwin-amd64.tar.gz
		else
			curl -sSLo ${SPHINX_DIR}/sphinx-3.1.1.tar.gz http://sphinxsearch.com/files/sphinx-3.1.1-612d99f-linux-amd64.tar.gz
		fi
	fi

	if [ ! -f ${SPHINX_DIR}/sphinx-3.1.1.tar.gz ];then
		curl -sSLo ${SPHINX_DIR}/sphinx-3.1.1.tar.gz https://github.com/jianghujs/jh-panel/releases/download/init/sphinx-3.1.1.tar.gz
	fi


	cd ${SPHINX_DIR} && tar -zxvf sphinx-3.1.1.tar.gz
	
	if [ "$?" == "0" ];then
		mkdir -p $SPHINX_DIR
		cp -rf ${SPHINX_DIR}/sphinx-3.1.1/ $serverPath/sphinx/bin
	fi
	
	if [ -d $serverPath/sphinx ];then
		echo '3.1.1' > $serverPath/sphinx/version.pl
		echo '安装完成' > $install_tmp
		cd ${rootPath} && python3 ${rootPath}/plugins/sphinx/index.py start
		cd ${rootPath} && python3 ${rootPath}/plugins/sphinx/index.py initd_install
	fi
}

Uninstall_sphinx()
{
	if [ -f /usr/lib/systemd/system/sphinx.service ] || [ -f /lib/systemd/system/sphinx.service ];then
		systemctl stop sphinx
		systemctl disable sphinx
		rm -rf /usr/lib/systemd/system/sphinx.service
		rm -rf /lib/systemd/system/sphinx.service
		systemctl daemon-reload
	fi

	if [ -f $serverPath/sphinx/initd/sphinx ];then
		$serverPath/sphinx/initd/sphinx stop
	fi

	rm -rf $serverPath/sphinx
	echo "Uninstall_sphinx" > $install_tmp
}

action=$1
if [ "${1}" == 'install' ];then
	Install_sphinx
else
	Uninstall_sphinx
fi
