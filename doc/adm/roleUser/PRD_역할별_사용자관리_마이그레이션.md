# PRD - 시스템 역할별 사용자 관리(roleUser) 마이그레이션

## 1. 목적
- 원본 화면 `D:\project\soybean\src\views\system\roleUser\index.vue`의 기능을 우리 시스템(Rails + Hotwire + Stimulus + AG Grid) 구조로 이관한다.
- 메뉴 경로는 요청 기준 `system/roleUser`로 제공한다.
- 공통 프런트엔드 규약은 `doc/frontend/STIMULUS_COMPONENTS_GUIDE.md`를 따른다.

## 2. 범위
- 포함
1. 역할 선택
2. 역할 미할당/할당 사용자 2-그리드 조회
3. 좌/우 이동으로 역할 할당 대상 편집
4. 좌/우 각각 사용자명/부서명 로컬 검색
5. 저장 시 선택 역할의 사용자 일괄 재할당
6. 시스템 메뉴 등록

- 제외
1. 다중 역할(1사용자 N역할) 모델
2. 역할-권한 상세 정책 편집
3. 엑셀 업로드/다운로드

## 3. 원본(Vue) 기능 분석
- 상단 검색: 역할 선택(select)
- 좌측: 미할당 사용자 목록 + 검색
- 우측: 할당 사용자 목록 + 검색
- 중앙: 이동 버튼(->, <-)
- 저장: 우측 사용자 ID 목록을 roleId에 일괄 저장

## 4. 타겟 구조
- 페이지: `System::RoleUser::PageComponent`
- 엔트리: `app/views/system/role_user/index.html.erb`
- Stimulus: `role-user-grid_controller.js`
- API: `System::RoleUserController`
- 데이터 소스
1. 역할: `AdmRole`
2. 사용자: `User` (`adm_users.role_cd` 사용)

## 5. 화면/동작 요구사항
- 역할 선택
1. 사용여부 `Y` 역할만 노출
2. 첫 역할 자동 선택

- 리스트
1. 좌측(미할당): `role_cd != 선택 role_cd` 사용자
2. 우측(할당): `role_cd == 선택 role_cd` 사용자

- 이동
1. 좌측 선택행 -> 우측 추가, 좌측 제거
2. 우측 선택행 -> 좌측 추가, 우측 제거

- 검색
1. 좌/우 각 입력값으로 `user_nm`, `dept_nm` 부분일치 필터

- 저장
1. 요청 payload: `role_cd`, `user_ids[]`
2. 처리 규칙
- 기존 해당 역할 사용자 중 `user_ids`에 없는 사용자는 role_cd 해제
- `user_ids`에 있는 사용자는 role_cd를 선택 역할로 갱신

## 6. API 계약
- `GET /system/roleUser/available_users?role_cd=...`
- `GET /system/roleUser/assigned_users?role_cd=...`
- `POST /system/roleUser/save_assignments`

요청 예시:
```json
{
  "role_cd": "ADMIN",
  "user_ids": ["U001", "U002"]
}
```

응답 예시:
```json
{
  "success": true,
  "message": "역할 사용자 저장이 완료되었습니다."
}
```

## 7. 보안/권한
- `System::BaseController` 상속으로 관리자만 접근.
- Strong Parameters로 `role_cd`, `user_ids`만 허용.
- 저장은 트랜잭션으로 처리.

## 8. 라우팅/메뉴
- 라우트 path: `/system/roleUser`
- 메뉴 코드: `SYS_ROLE_USER`
- 상위 메뉴: `SYSTEM`

## 9. 테스트 전략
- 컨트롤러 테스트
1. available/assigned 조회 응답
2. save_assignments 저장 정합성
3. 비관리자 접근 차단

## 10. 완료 기준
1. `/system/roleUser`에서 역할 선택, 이동, 저장 가능
2. 저장 후 재조회 시 우측/좌측 목록 정합성 유지
3. 관련 테스트 통과