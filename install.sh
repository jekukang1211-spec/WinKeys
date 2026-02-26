#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

APP_NAME="WinKeys"
APP_BUNDLE="${APP_NAME}.app"
INSTALL_DIR="/Applications"

# 빌드
echo "=== ${APP_NAME} 빌드 중 ==="
./build.sh

# 기존 실행 중인 인스턴스 종료
if pgrep -x "${APP_NAME}" > /dev/null 2>&1; then
    echo "기존 ${APP_NAME} 종료 중..."
    killall "${APP_NAME}" 2>/dev/null || true
    sleep 1
fi

# /Applications에 복사
echo "${INSTALL_DIR}에 설치 중..."
rm -rf "${INSTALL_DIR}/${APP_BUNDLE}"
cp -R "${APP_BUNDLE}" "${INSTALL_DIR}/${APP_BUNDLE}"

echo ""
echo "=== 설치 완료 ==="
echo ""
echo "중요: ${APP_NAME}은 손쉬운 사용 권한이 필요합니다."
echo "권한 요청이 나타나면 아래 경로에서 허용해 주세요:"
echo "  시스템 설정 > 개인정보 보호 및 보안 > 손쉬운 사용"
echo ""

# 실행
echo "${APP_NAME} 실행 중..."
open "${INSTALL_DIR}/${APP_BUNDLE}"

echo "완료!"
