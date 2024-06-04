function runJar(){
	COUNT=$(ps -ef |grep -iw $2 |grep -v "grep" |wc -l)
	echo $COUNT
	if [ $COUNT -eq 0 ]; then
        echo "RUN ${3}"
        #后台运行
        # java -jar $1 >> $4 2>&1 &
        #前台运行
        # java -jar $1 $5 2>&1 |tee $4 
        java -cp $1 $2 $5 2>&1 |tee $4 
        echo "RUN ${3} OVER"
	else
        echo "${3} is RUN"
	fi
	
}
cd /Users/zxl/documents/autoscripts
# source ~/.bash_profile
number=10000
APP_NAME=/Users/zxl/ideaprojects/zxlspider/out/spiderpak-1.0-SNAPSHOT.jar

if [ -n "$1" ]; then
  
  if [ "$1" -ge 500 ] && [ "$1" -le 100000 ]; 
  then
    number=$1
    if [ -n "$2" ] &&  [ "$2" = "all" ]; then app3policy=$2; fi
  else
    echo "error: 第一个参数只能500-100000内数字！"
    exit 1
  fi
else
  echo "DEFULT CONFIG"
fi


LOG1_FILE=$(pwd)/logs/spider2oracle.log
# APP1_NAME=/Users/zxl/ideaprojects/zxlspider/out/artifacts/spider2oracle/zxlspider.jar
APP1_MAINNAME=run.spiderstart
APP1_SHOWNAME=spiderstart

if [ ! -e "$APP_NAME" ]; then
 echo "error: ${APP_NAME} 不存在或没有可执行权限"
 exit 1
fi

#刷新/创建日志文件
 touch "$LOG1_FILE"

#spider部分
sh startdocker.sh
#启动容器
sh startcontainer.sh oracle11g
#阻塞检查
echo "检查oracle端口"
while ! nc -z 127.0.0.1 1521; 
  do printf ".";
  sleep 1
done
#应用内会阻塞等待oracle启动
#  sleep 60
#启动jar。 参数：500-100000数字 
runJar $APP_NAME $APP1_MAINNAME $APP1_SHOWNAME $LOG1_FILE $number




LOG2_FILE=$(pwd)/logs/put2redis.log
# APP2_NAME=/Users/zxl/ideaprojects/zxlspider/out/artifacts/put2redis/zxlspider.jar
APP2_MAINNAME=run.putDataToRedis
APP2_SHOWNAME=put2redis
if [ ! -e "$APP_NAME" ]; then
 echo "error: ${APP_NAME} 不存在或没有可执行权限"
 exit 1
fi
#刷新/创建日志文件
 touch "$LOG2_FILE"

#putredis部分
sh startdocker.sh
#启动容器
sh startcontainer.sh oracle11g
sh startcontainer.sh redis
#阻塞检查
echo "检查redis端口"
while ! nc -z 127.0.0.1 6379; 
  do printf ".";
  sleep 1
done
echo "检查oracle端口"
while ! nc -z 127.0.0.1 1521; 
  do printf ".";
  sleep 1
done
#启动jar
runJar $APP_NAME $APP2_MAINNAME $APP2_SHOWNAME $LOG2_FILE 



#数据给es统计，再抽取结果推给redis 参数：all(全量) 默认增量
sh plan3.sh $app3policy


docker stop  esdata4
docker stop  logstash
docker stop  oracle11g
# docker stop  redis


LOG4_FILE=$(pwd)/logs/analyse2Redis.log
# APP2_NAME=/Users/zxl/ideaprojects/zxlspider/out/artifacts/put2redis/zxlspider.jar
APP4_MAINNAME=run.analyseToRedis
APP4_SHOWNAME=analyse2Redis
if [ ! -e "$APP_NAME" ]; then
 echo "error: ${APP_NAME} 不存在或没有可执行权限"
 exit 1
fi
#刷新/创建日志文件
 touch "$LOG4_FILE"

#putredis部分
sh startdocker.sh
#启动容器
sh startcontainer.sh redis
#阻塞检查
echo "检查redis端口"
while ! nc -z 127.0.0.1 6379; 
  do printf ".";
  sleep 1
done
#启动jar
runJar $APP_NAME $APP4_MAINNAME $APP4_SHOWNAME $LOG4_FILE 


su zxl
cat /Users/zxl/documents/autoscripts/logs/spider2oracle.log /Users/zxl/documents/autoscripts/logs/putes2redis.log | mail -v -s "planlog" 15273376301@163.com

echo "ok"
