# AG Grid 컬럼 상태 저장 및 그리드 액션 아이콘 PRD

## 개요

AG Grid 사용자가 조정한 컬럼 순서, 너비, 정렬 상태를 localStorage에 저장/복원하고,
그리드 타이틀 옆에 공통 액션 아이콘(컬럼 저장, 초기화, 엑셀 다운로드)을 제공합니다.

## 기능 요구사항

### 컬럼 상태 저장
- localStorage 키: `ag-grid-state:{gridId}` (예: `ag-grid-state:dept`)
- 저장 데이터: `gridApi.getColumnState()` 반환 배열 (colId, width, sort, pinned, hide, flex 등)
- 저장 시점: 사용자가 저장 아이콘 클릭 시
- 복원 시점: 그리드 초기화(`initGrid`) 완료 후 자동 복원

### 컬럼 상태 초기화
- localStorage에서 해당 키 제거
- `gridApi.resetColumnState()` 호출로 기본 상태 복원

### 그리드 액션 아이콘
- 저장 (`save` 아이콘): 현재 컬럼 상태를 localStorage에 저장
- 초기화 (`rotate-ccw` 아이콘): 저장된 상태 제거 후 기본값 복원
- 엑셀 다운로드 (`file-spreadsheet` 아이콘): CSV 내보내기 또는 커스텀 엑셀 다운로드

### 토스트 알림
- 저장/초기화 완료 시 하단 우측에 2초간 토스트 메시지 표시

## 적용 대상 페이지

| 페이지 | grid_id | 비고 |
|--------|---------|------|
| 부서 관리 | `dept` | 엑셀 다운로드 연동 |
| 사용자 관리 | `users` | 엑셀 다운로드 연동 |
| 메뉴 관리 | `menus` | CSV fallback |
| 역할 관리 | `roles` | CSV fallback |
| 코드 관리 (마스터) | `code-master` | CSV fallback |
| 코드 관리 (상세) | `code-detail` | CSV fallback |
| 로그인 이력 | `login-history` | CSV fallback |
| 역할별 사용자 | `role-user-left`, `role-user-right` | CSV fallback |
| 사용자 메뉴 역할 | `user-menu-role-user`, `user-menu-role-role`, `user-menu-role-menu` | CSV fallback |
| 메뉴 접속 로그 | `menu-logs` | CSV fallback |
