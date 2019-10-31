部分内容来自于[这里](https://github.com/huijiewei/CoreseekDocker)


# 一、 制作image

```
cd image
docker build . -t coreseek:latest
```
## 也可以将其上传到某些docker仓库，自己选择


# 二、部署
## 2.1 可使用如下方式
A： docker run

B: docker-compose

C: k8s
我这里选择B方式
## 2.2 部署步骤

### 修改docker-compose.yml脚本，相关路径修改为自己的实际路径
busybox容器只是用来测试，可以删掉
```
cd deploy
vim docker-compose.yml
```

### 运行
```
docker-compose up -d
```
### 此时由于数据库还没有数据导致coreseek容器无法拉起，需要导入数据库初始sql

导入的方式有很多，这里使用命令行
```
cat documents.sql | mysql -h**** -P3306 -uroot -proot -d sphinx

```

### 导入数据后，重新拉起即可启动
```
docker-compose up -d
```

## 2.3 启动后的效果如下：
```
CONTAINER ID        IMAGE              COMMAND                  CREATED              STATUS              PORTS                               NAMES
c46c9b05f5ff        busybox           "/bin/sh -c 'sleep 3…"   About a minute ago   Up About a minute                                       busybox
4dadc1b9591f        coreseek:latest   "/entrypoint.sh"         About a minute ago   Up About a minute   0.0.0.0:9312->9312/tcp              coreseek
5ec827535945        mysql:5.7.27      "docker-entrypoint.s…"   About a minute ago   Up About a minute   0.0.0.0:3306->3306/tcp, 33060/tcp   mysql
```

### 注意：documents.sql一定要和coreseek的配置文件docker-compose/sphinx/sphinx.conf中的"source search"段落的sql_query对应起来
