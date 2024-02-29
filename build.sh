#!/bin/sh

VERSION="1.0.0"
PNAME="server"

## 如果有Dockerfile模板，则需要以下代码来初始化
#sed 's/__VERSION__/'${VERSION}'/' Dockerfile-tpl  > Dockerfile-tmp
#sed 's/__PNAME__/'${PNAME}'/' Dockerfile-tmp > Dockerfile
#rm -f Dockerfile-tmp

# 开始编译Docker镜像，如果有一些初始化操作亦可以放到这里

#检查版本号是否存在
#function check_version() {
#    existVersion=$(docker images | awk '{if ($1 == "'$PNAME'") print $0}' | awk '{print $2}' |  grep $VERSION)
#    if [ x"$existVersion" == x"$VERSION" ];then
#        echo "bad version of build $PNAME-$VERSION"
#        exit -1
#    fi
#}

#if [ x"$1" != "test" ]; then
#    check_version
#fi

################################################################
#  以下代码一般无需更改，如果想配置推送机房，则更新REGIONS即可 #
################################################################



echo "docker build..."
docker build -t $PNAME .

if [ $? != 0 ];then
    echo "failed to build $PNAME-${PNAME} image"
    exit -1
fi

docker tag $PNAME:latest $PNAME:${VERSION}


# 清理本地的镜像，避免无用镜像过多
function clean() {
	DOCKER_REPO_TMP=$1
	if [ x$1 == x"" ]; then
		echo "not found docker repo argument."
                return -1
        fi
	docker rmi ${DOCKER_REPO_TMP}/${PNAME}:latest
	docker rmi ${DOCKER_REPO_TMP}/${PNAME}:${VERSION}
}

# 推送前打tag
function tag() {
	DOCKER_REPO_TMP=$1
	if [ x$1 == x"" ]; then
		echo "not found docker repo argument."
                return -1
        fi
	echo "docker tag ${DOCKER_REPO_TMP} latest..."
	docker tag ${PNAME}:latest ${DOCKER_REPO_TMP}/${PNAME}:latest
	echo "docker tag ${DOCKER_REPO_TMP} ${VERSION}..."
	docker tag ${PNAME}:latest ${DOCKER_REPO_TMP}/${PNAME}:${VERSION}
}
# 推送镜像，有三次重试
function push() {
	DOCKER_REPO_TMP=$1
	if [ x$1 == x"" ]; then
		echo "not found docker repo argument."
                return -1
        fi

	TAG_TMP=$2
	if [ x$2 == x"" ]; then
		echo "not found docker tag argument."
                return -1
        fi

	echo "starting to push ${PNAME}:${TAG_TMP} to ${DOCKER_REPO_TMP}/${PNAME}:${TAG_TMP}..."
	succ=0
	for i in `seq 1 3`; do
		docker push ${DOCKER_REPO_TMP}/${PNAME}:${TAG_TMP}
		if [ $? != 0 ];then
			echo "[$i times] docker push failed..."
			echo "trying to push ${PNAME}:${TAG_TMP} to ${DOCKER_REPO_TMP}/${PNAME}:${TAG_TMP}..."
		else
			echo "[$i times] docker push is successful..."
			succ=1
			break
		fi
	done


	if ( $succ == 0 ); then
		echo "failed to push docker images ${DOCKER_REPO_TMP}/${PNAME}:${TAG_TMP} at last..., exit now."
		exit -1
	fi
}

REGION="hangzhou"

DOCKER_REPO="registry.cn-$REGION.aliyuncs.com/q_cloud_ll/qcsh-rep"

echo "runing as region in $REGION.."
tag $DOCKER_REPO
if [ $? != 0 ];then
  echo "docker tag failed.."
  exit -1
fi
push $DOCKER_REPO latest
push $DOCKER_REPO ${VERSION}
clean $DOCKER_REPO



echo "cleaning none tag images"

#docker images|grep none|awk '{print $3}'|xargs docker rmi >/dev/null 2>&1

docker images |grep $PNAME

echo "build complete"
