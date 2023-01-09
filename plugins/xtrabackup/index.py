# coding:utf-8

import sys
import io
import os
import time
import re

sys.path.append(os.getcwd() + "/class/core")
import mw

app_debug = False
if mw.isAppleSystem():
    app_debug = True

def getPluginName():
    return 'xtrabackup'  

def getPluginDir():
    return mw.getPluginDir() + '/' + getPluginName()

def getServerDir():
    return mw.getServerDir() + '/' + getPluginName()

def runLog():
    return getServerDir() + '/xtrabackup.log'  

def status():
    return 'start'

def getArgs():
    args = sys.argv[2:]
    tmp = {}
    args_len = len(args)

    if args_len == 1:
        t = args[0].strip('{').strip('}')
        t = t.split(':')
        tmp[t[0]] = t[1]
    elif args_len > 1:
        for i in range(len(args)):
            t = args[i].split(':')
            tmp[t[0]] = t[1]

    return tmp

def checkArgs(data, ck=[]):
    for i in range(len(ck)):
        if not ck[i] in data:
            return (False, mw.returnJson(False, '参数:(' + ck[i] + ')没有!'))
    return (True, mw.returnJson(True, 'ok'))

def doMysqlBackup():
    log_file = runLog()
    xtrabackupScript = getServerDir() + '/xtrabackup.sh'
    mw.execShell('echo $(date "+%Y-%m-%d %H:%M:%S") "备份开始" >> ' + log_file)
    execResult = mw.execShell("sh %(xtrabackupScript)s >> %(logFile)s" % {'xtrabackupScript': xtrabackupScript, 'logFile': log_file })
    if execResult[1]:
        return mw.returnJson(False, '备份失败!' + execResult[1])
    mw.execShell('echo $(date "+%Y-%m-%d %H:%M:%S") "备份成功" >> ' + log_file)
    return mw.returnJson(True, '备份成功!')


def backupList():
    result = []
    for d_walk in os.walk('/www/backup/xtrabackup_data_history'):
        for d_list in d_walk[2]:
            result.append(d_list)
    return mw.returnJson(True, 'ok', result)

def doRecoveryBackup():
    args = getArgs()
    data = checkArgs(args, ['filename'])
    if not data[0]:
        return data[1]
    filename = args['filename']

    # 获取的mysql目录
    mysqlDir = ''
    if os.path.exists('/www/server/mysql-apt'):
        mysqlDir = '/www/server/mysql-apt/data'
    elif os.path.exists('/www/server/mysql'):
        mysqlDir = '/www/server/mysql/data'
    else :
        return mw.returnJson(False, '未检测到安装的mysql插件!')

    mw.execShell('mv %s %s_%s' % (mysqlDir, mysqlDir, time.strftime('%Y%m%d%H%M%S', time.localtime(time.time()))))

    mw.execShell('rm -rf /www/backup/xtrabackup_data_restore')
    mw.execShell('unzip -d /www/backup/xtrabackup_data_restore /www/backup/xtrabackup_data_history/%s' % (filename))
    mw.execShell('mv /www/backup/xtrabackup_data_restore/www/backup/xtrabackup_data %s' % (mysqlDir))
    mw.execShell('chown -R mysql:mysql %s' % (mysqlDir))
    mw.execShell('systemctl restart mysql')

    return mw.returnJson(True, '恢复成功，请到mysql插件的管理列表-点击【修复ROOT密码】更新ROOT密码!!')


def doDeleteBackup():
    args = getArgs()
    data = checkArgs(args, ['filename'])
    if not data[0]:
        return data[1]
    filename = args['filename']
    mw.execShell('rm -f /www/backup/xtrabackup_data_history/' + filename)
    return mw.returnJson(True, '删除成功!')

def getConf():
    path = getServerDir() + "/xtrabackup.sh"
    return path
    
if __name__ == "__main__":
    func = sys.argv[1]
    if func == 'status':
        print(status())
    elif func == 'run_log':
        print(runLog())
    elif func == 'conf':
        print(getConf())     
    elif func == 'do_mysql_backup':
        print(doMysqlBackup())
    elif func == 'backup_list':
        print(backupList())
    elif func == 'do_recovery_backup':
        print(doRecoveryBackup())
    elif func == 'do_delete_backup':
        print(doDeleteBackup())
    else:
        print('error')
