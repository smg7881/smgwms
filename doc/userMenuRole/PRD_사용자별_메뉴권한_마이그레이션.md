# PRD - 시스템 사용자별 메뉴권한(userMenuRole) 마이그레이션

## 1. 목적
- 원본 화면 `D:\project\soybean\src\views\system\userMenuRole\index.vue` 기능을 우리 시스템(Rails 8 + Hotwire + Stimulus + AG Grid) 구조로 이관한다.
- 메뉴 경로는 요청 기준 `system/userMenuRole`로 제공한다.
- 프런트엔드 규약은 `doc/frontend/STIMULUS_COMPONENTS_GUIDE.md`를 따른다.

## 2. 범위
- 포함
1. 사용자 검색(사원명/부서명)
2. 사용자 목록(상단 그리드) 조회
3. 사용자 선택 시 역할 목록(하단 좌측 그리드) 조회
4. 역할 선택 시 메뉴 목록(하단 우측 그리드) 조회
5. 각 그리드 데이터 로드 시 첫 행 자동 선택(연쇄 조회)
6. 시스템 메뉴 등록 및 탭 식별자 등록

- 제외
1. 역할-메뉴 매핑 수정/저장 기능
2. 다중 역할 할당(1사용자 N역할) 데이터 모델 변경
3. 엑셀 업로드/다운로드

## 3. 원본(Vue) 기능 분석
- 상단: 검색폼 + 사용자 그리드
- 하단 좌측: 선택 사용자의 역할 그리드
- 하단 우측: 선택 사용자 + 선택 역할 기준 메뉴 그리드
- 동작: 사용자 선택 -> 역할 조회, 역할 선택 -> 메뉴 조회

## 4. 우리 시스템 기준 마이그레이션 정책
- 데이터 모델 제약
1. `adm_users.role_cd` 단일 컬럼 구조이므로 사용자별 다중 역할은 지원하지 않음
2. `adm_role_menu` 성격의 매핑 테이블이 없어 역할별 메뉴를 직접 계산할 수 없음

- 대체 규칙
1. 역할 그리드: 선택 사용자의 `role_cd`로 `adm_roles` 단건(또는 없음) 조회
2. 메뉴 그리드: 역할 선택 시 활성 메뉴(`adm_menus.use_yn='Y'`)를 레벨/정렬 기준으로 조회
3. 메뉴 API 파라미터에는 원본 호환성을 위해 `user_id_code`, `role_cd`를 모두 받되, 현재 시스템에서는 `role_cd` 유효성 확인 후 활성 메뉴를 반환

## 5. 타겟 아키텍처
- Controller: `System::UserMenuRoleController`
- Page Component: `System::UserMenuRole::PageComponent`
- View Entry: `app/views/system/user_menu_role/index.html.erb`
- Stimulus: `app/javascript/controllers/user_menu_role_grid_controller.js`
- Routes
1. `GET /system/userMenuRole`
2. `GET /system/userMenuRole/users`
3. `GET /system/userMenuRole/roles_by_user`
4. `GET /system/userMenuRole/menus_by_user_role`

## 6. 화면/동작 요구사항
- 검색
1. `q[user_nm]`, `q[dept_nm]` 조건으로 사용자 조회
2. 검색/초기화는 공통 SearchForm 패턴 사용

- 사용자 그리드
1. 컬럼: 사번, 사용자명, 부서명, 역할코드
2. 단일 선택
3. 데이터 로딩 완료 시 첫 행 자동 선택

- 역할 그리드
1. 컬럼: 역할코드, 역할명, 설명
2. 단일 선택
3. 데이터 로딩 완료 시 첫 행 자동 선택

- 메뉴 그리드
1. 컬럼: 메뉴코드, 메뉴명, URL, 타입, 레벨
2. 읽기 전용

## 7. API 계약
- `GET /system/userMenuRole/users?q[user_nm]=...&q[dept_nm]=...`
- `GET /system/userMenuRole/roles_by_user?user_id_code=...`
- `GET /system/userMenuRole/menus_by_user_role?user_id_code=...&role_cd=...`

응답 샘플(사용자):
```json
[
  {
    "id": 1,
    "user_id_code": "admin01",
    "user_nm": "관리자",
    "dept_nm": "IT",
    "role_cd": "ADMIN"
  }
]
```

응답 샘플(역할):
```json
[
  {
    "role_cd": "ADMIN",
    "role_nm": "관리자",
    "description": "시스템 관리자"
  }
]
```

응답 샘플(메뉴):
```json
[
  {
    "menu_cd": "SYS_USER",
    "menu_nm": "사용자관리",
    "menu_url": "/system/users",
    "menu_type": "MENU",
    "menu_level": 2
  }
]
```

## 8. 보안/권한
- `System::BaseController` 상속으로 관리자 접근만 허용
- Strong Parameters 기반 검색 파라미터 허용
- JSON 응답은 화면 표시에 필요한 필드만 반환

## 9. 라우팅/메뉴/탭
- 라우트 path: `/system/userMenuRole`
- 메뉴 코드: `SYS_USER_MENU_ROLE`
- 상위 메뉴: `SYSTEM`
- 탭 ID: `system-user-menu-role`

## 10. 테스트 전략
- 컨트롤러 테스트
1. HTML 인덱스 응답
2. 사용자 검색 JSON 응답
3. 사용자 기반 역할 조회 응답
4. 사용자+역할 기반 메뉴 조회 응답
5. 비관리자 접근 차단

## 11. 완료 기준
1. `/system/userMenuRole`에서 사용자/역할/메뉴 3단 조회가 동작한다.
2. 사용자 선택 시 역할, 역할 선택 시 메뉴가 연쇄 조회된다.
3. 메뉴에서 `system/userMenuRole` 진입이 가능하다.
4. 관련 테스트가 통과한다.