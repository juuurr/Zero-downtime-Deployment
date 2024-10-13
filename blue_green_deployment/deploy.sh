#!/bin/bash

# 설정
CURRENT_ENV_FILE=".env.dev"
BLUE_TAG="blue"
GREEN_TAG="green"
BLUE_COMPOSE_FILE="docker-compose.blue.yml"
GREEN_COMPOSE_FILE="docker-compose.green.yml"
CURRENT_ENV=$(cat $CURRENT_ENV_FILE)

# 현재 실행 중인 환경 확인
function check_if_running() {
    if docker ps -q -f name=blue | grep -q .; then
        CURRENT_ENV="blue"
    elif docker ps -q -f name=green | grep -q .; then
        CURRENT_ENV="green"
    else
        CURRENT_ENV="없음"
    fi
}




# 현재 환경 상태를 파일로 저장
echo "현재 환경 확인 중..."
check_if_running
echo "현재 환경: $CURRENT_ENV"
echo $CURRENT_ENV > $CURRENT_ENV_FILE 



# 프록시 전환 함수
function change_conf() {
    echo "프록시 전환.."
    if [[ "$CURRENT_ENV" == "blue" ]]; then
        cp nginx/nginx.blue.conf nginx/nginx.conf
    elif [[ "$CURRENT_ENV" == "green" ]]; then
        cp nginx/nginx.green.conf nginx/nginx.conf
    fi
}


# Blue 환경 시작
function start_blue() {
    echo "Blue 환경 시작중..."
    docker-compose -f $BLUE_COMPOSE_FILE up -d --build
    if [ $? -eq 0 ]; then
        echo "Blue 환경이 실행되었습니다."
        echo "blue" > $CURRENT_ENV_FILE
        echo "Blue environment is now live!"
    else
        echo "Blue 환경 실행에 실패하였습니다."
        exit 1
    fi
}

# Green 환경 시작
function start_green() {
    echo "Green 환경 시작중..."
    docker-compose -f $GREEN_COMPOSE_FILE up -d --build # web-green
    if [ $? -eq 0 ]; then
        echo "Green 환경이 실행되었습니다."
        echo "green" > $CURRENT_ENV_FILE
        echo "Green environment is now live!"
    else
        echo "Green 환경 실행에 실패하였습니다."
        exit 1
    fi
}



# Blue 환경 중지
function stop_blue() {
    echo "Blue 환경을 중지합니다."
    docker-compose -f $BLUE_COMPOSE_FILE stop
}

# Green 환경 중지
function stop_green() {
    echo "Green 환경을 중지합니다."
    docker-compose -f $GREEN_COMPOSE_FILE stop
}

# 환경 전환
function switch_environment() {
    if [[ $CURRENT_ENV == $BLUE_TAG ]]; then
        echo "현재 Blue 환경에서 Green 환경으로 전환합니다."
        change_conf
        start_green
        if [[ $? -eq 0 ]]; then
            sleep 3
            stop_blue
        else
            echo "Green 환경 시작 실패. Blue 환경은 계속 실행됩니다."
        fi

    elif [[ $CURRENT_ENV == $GREEN_TAG ]]; then
        echo "현재 Green 환경에서 Blue 환경으로 전환합니다."
        change_conf
        start_blue
        # start_blue가 성공적으로 실행되었는지 확인
        if [[ $? -eq 0 ]]; then
            sleep 3
            stop_green
        else
            echo "Blue 환경 시작 실패. Green 환경은 계속 실행됩니다."
        fi
    else
        echo "현재 실행 중인 환경이 없습니다. Blue 환경을 실행합니다."
        start_blue
    fi
}


# 배포 시작
function deploy() {
    echo "배포를 시작합니다."
    switch_environment
    echo "배포가 끝났습니다!"
}

# 롤백 함수
function rollback() {
    echo "이전 버전으로 롤백합니다."
    if [[ $CURRENT_ENV == $BLUE_TAG ]]; then
        start_green
        stop_blue
    else
        start_blue
        stop_green
    fi
}

# Main 스크립트 실행
if [[ $# -ne 1 ]]; then
    usage
    exit 1
fi

case "$1" in
    deploy)
        deploy
        ;;
    rollback)
        rollback
        ;;
esac