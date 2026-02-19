# PRD - 시스템 역할관리(roles) 마이그레이션

## 1. 목적
- 원본 화면 `D:\project\soybean\src\views\system\roles\index.vue`의 역할관리 기능을 우리 시스템(Rails 8.1 + Hotwire + Stimulus + AG Grid) 구조로 마이그레이션한다.
- 메뉴 경로는 `system/roles`로 제공한다.
- `doc/frontend/STIMULUS_COMPONENTS_GUIDE.md` 규약을 준수한다.

## 2. 범위
- 포함
1. 역할 목록 조회(검색 포함)
2. AG Grid 기반 인라인 편집
3. 신규 행 추가
4. 다중 선택 삭제(소프트 삭제 표시)
5. 배치 저장(insert/update/delete 일괄 반영)
6. 시스템 메뉴 등록(`SYSTEM > 역할관리`)

- 제외
1. 권한별 상세 매핑(메뉴-권한 매트릭스)
2. 사용자-역할 연결 데이터 일괄 정합성 보정
3. 엑셀 업/다운로드

## 3. 원본(Vue) 기능 분석 요약
- 검색 조건: `name`
- 그리드: 역할명/설명 편집, 다중 선택
- 주요 액션
1. 추가: 빈 행 생성 후 즉시 편집
2. 삭제: 선택 행 삭제
3. 저장: 변경분(batch) 서버 전송

## 4. 타겟 아키텍처
- 서버 렌더링: `System::Roles::PageComponent`
- 화면 엔트리: `app/views/system/roles/index.html.erb`
- 클라이언트 컨트롤러: `role-grid`(Stimulus)
- API: `System::RolesController`
- 도메인 모델: `AdmRole`
- DB: `adm_roles`

## 5. 데이터 모델
- 테이블: `adm_roles`
- 컬럼
1. `role_cd` (string, unique, not null)
2. `role_nm` (string, not null)
3. `description` (text, null)
4. `use_yn` (string(1), default `Y`, not null)
5. `create_by`, `create_time`, `update_by`, `update_time` (감사 컬럼)

- 규칙
1. `role_cd`, `role_nm` 필수
2. `use_yn`은 `Y/N`만 허용
3. 저장 시 코드/사용여부 대문자 정규화

## 6. UI/동작 요구사항
- 검색 영역
1. 역할코드(`role_cd`)
2. 역할명(`role_nm`)
3. 사용여부(`use_yn`)

- 툴바
1. 추가 (`role-grid#addRow`)
2. 삭제 (`role-grid#deleteRows`)
3. 저장 (`role-grid#saveRows`)

- 그리드 컬럼
1. 상태(`__row_status`)
2. 역할코드(신규행만 수정 가능)
3. 역할명(편집 가능)
4. 설명(편집 가능)
5. 사용여부(Select: Y/N)
6. 수정자/수정일시/생성자/생성일시(읽기 전용)

## 7. API 계약
- `GET /system/roles.json`
1. 쿼리: `q[role_cd]`, `q[role_nm]`, `q[use_yn]`
2. 응답: 역할 목록 배열

- `POST /system/roles/batch_save`
1. 요청
- `rowsToInsert`: [{ role_cd, role_nm, description, use_yn }]
- `rowsToUpdate`: [{ role_cd, role_nm, description, use_yn }]
- `rowsToDelete`: [role_cd]
2. 응답
- 성공: `{ success: true, data: { inserted, updated, deleted } }`
- 실패: `{ success: false, errors: [...] }`, 422

## 8. 권한/보안
- `System::BaseController` 상속으로 관리자만 접근.
- Strong Parameters로 허용 필드 제한.
- 배치 저장은 트랜잭션 단위로 처리.

## 9. 마이그레이션 전략
1. DB 스키마 추가(`adm_roles`)
2. 메뉴 데이터 추가(`SYS_ROLE`, `/system/roles`)
3. 서버/화면/Stimulus 배포
4. 기존 사용자의 `role_cd`는 유지(참조 무결성 강제는 후속)

## 10. 테스트 전략
- 모델 테스트
1. 필수값/고유성/`use_yn` 검증

- 컨트롤러 테스트
1. 목록 JSON 응답
2. batch_save insert/update/delete 정상 동작
3. 비관리자 접근 차단

## 11. 완료 기준(Definition of Done)
1. `system/roles` 접속 시 조회/검색/추가/삭제/저장 동작
2. 배치저장 후 재조회 시 데이터 정합성 유지
3. 테스트 통과(roles 관련 모델/컨트롤러)
4. 메뉴에서 `역할관리` 진입 가능