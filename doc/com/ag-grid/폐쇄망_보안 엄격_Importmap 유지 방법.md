아래는 **“Importmap은 그대로 유지”하면서** `ag-grid-community@35.1.0`을 **프로젝트 내부에 고정(로컬 호스팅)**해서 **폐쇄망/보안 정책에서도 동작**하게 만드는 실전 절차입니다. (Rails 8 기준, bundler/esbuild 없이)

> 핵심 아이디어: **CDN URL로 pin 하지 말고**, `vendor/javascript`(또는 `vendor/assets`)에 파일을 넣고 **로컬 경로로 pin**합니다.

---

## 0) 왜 “한 파일만 복사”가 아니라 “패키지 복제”가 필요한가?

`main.esm.mjs`는 내부적으로 다른 모듈 파일을 **상대경로로 추가 import**하는 경우가 많습니다.
그래서 `main.esm.mjs`만 로컬에 두면, 실행 중에 `./core/...` 같은 파일을 찾다 404가 날 수 있습니다.

따라서 로컬 호스팅은 보통 **“패키지 디렉토리 자체를 통째로”** 갖고 오는 게 안전합니다.

---

## 방법 A) 가장 안전/단순: `vendor/javascript`에 패키지 디렉토리 복사 후 pin

### 1) 패키지 파일을 로컬로 다운로드

인터넷 되는 환경에서 한 번만 수행(배포 서버가 폐쇄망이어도, 소스에 포함되면 됨)

```bash
mkdir -p vendor/javascript/ag-grid-community
curl -L -o /tmp/ag-grid-community-35.1.0.tgz \
  https://registry.npmjs.org/ag-grid-community/-/ag-grid-community-35.1.0.tgz

tar -xzf /tmp/ag-grid-community-35.1.0.tgz -C vendor/javascript/ag-grid-community --strip-components=1
```

이렇게 하면 대략 아래처럼 생깁니다.

```
vendor/javascript/ag-grid-community/
  package.json
  dist/
    package/
      main.esm.mjs
    ...
```

### 2) importmap.rb를 로컬 경로로 변경

이제 CDN 대신 프로젝트 안 파일을 가리킵니다.

```ruby
# config/importmap.rb

pin "ag-grid-community",
  to: "ag-grid-community/dist/package/main.esm.mjs",
  preload: true
```

> `to:` 경로는 `vendor/javascript` 기준 상대경로로 인식되는 게 일반적입니다.

### 3) 서버 재시작 후 확인

브라우저 DevTools → Network에서

* `.../assets/ag-grid-community/dist/package/main.esm-<digest>.mjs` 같은 형태로 로드되면 성공입니다.

---

## 방법 B) 공식 권장에 가까운 운영 방식: “vendor에 넣고 정기 업데이트”

위 방식(A)을 그대로 쓰되, **버전 업그레이드도 동일 절차**로 반복합니다.

* `35.1.0` → `35.1.1`로 바꿀 때는

  * tgz URL만 바꾸고
  * importmap 버전 문자열만 바꾸면 됩니다.

---

## 오프라인/폐쇄망에서 특히 중요한 체크 3가지

### 1) CSP 설정 단순화 (좋아짐)

CDN을 안 쓰면 `script-src`에 jsDelivr 허용이 필요 없어서 **보안팀이 좋아합니다.**
(필요하면 CSP는 `'self'` 중심으로 유지 가능)

### 2) 캐시/무결성(좋아짐)

로컬 assets는 digest가 붙어서 배포마다 버전이 명확합니다.

* “어느 날 CDN이 바뀌어 깨짐” 같은 일이 없어집니다.

### 3) 라이선스/고지 확인

AG Grid Community는 MIT입니다(대체로 문제 없음). 그래도 기업/고객 환경이면 OSS 고지 프로세스에 포함하세요.

---

## “이 방식이 제대로 됐는지” 빠른 검증법

### A. 브라우저에서

* Network에 `cdn.jsdelivr.net` 요청이 **0건**
* 대신 `/assets/ag-grid-community/...` 로드

### B. Rails에서(간단)

* `vendor/javascript/ag-grid-community/dist/package/main.esm.mjs` 파일이 존재

---

## 자주 발생하는 실수와 해결

### 실수 1) `main.esm.mjs`만 복사함 → 실행 중 404

✅ 해결: `vendor/javascript/ag-grid-community`를 **tgz로 통째로** 풀어 넣기(방법 A).

### 실수 2) importmap 경로를 `vendor/javascript/...`로 적음

보통 `to:`에는 `vendor/javascript`를 빼고 **그 아래 상대경로**를 씁니다.
예: `to: "ag-grid-community/dist/package/main.esm.mjs"`

### 실수 3) Turbo 캐시로 그리드 재진입 시 깨짐

이미 하신 `turbo:before-cache` teardown 패턴 유지하면 해결됩니다.

---

## 추천 결론

* **폐쇄망/보안 엄격** + **Importmap 유지**가 목표면 → **방법 A가 정답**입니다.
* 이후에 필요하면 “사내 아티팩트 저장소(사설 npm/사설 CDN)”로도 확장 가능합니다.

원하시면, 현재 프로젝트가 **Propshaft인지(Sprockets인지)**에 따라 `vendor/javascript` 경로 인식이 100% 같게 맞는지 점검해드릴게요. `Gemfile.lock`에서 `propshaft` 사용 여부 한 줄만 알려주셔도 됩니다.
