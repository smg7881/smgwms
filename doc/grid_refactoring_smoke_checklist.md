# Grid Refactoring Smoke Checklist

## 공통 사전 확인
- 브라우저 콘솔 에러 없음
- 페이지 진입/이탈(Turbo 이동) 시 JS 에러 없음
- 그리드 렌더링 및 컬럼 상태 저장/복원 정상

## 단일 그리드 화면
- 조회(`refresh`) 동작 정상
- 행 추가/삭제/저장(CUD) 정상
- 저장 후 변경 상태(`__row_status`) 표시 정상
- 필터 초기화(`clearFilter`) 정상

## 마스터-디테일 화면
- 마스터 행 클릭/포커스 변경 시 디테일 로딩 정상
- 마스터 미저장 변경 시 디테일 액션 차단 경고 정상
- 마스터 저장 후 디테일 재조회 정상
- 디테일 저장 URL 템플릿 치환 정상

## 다중 그리드 등록 화면
- `ag-grid:ready` 순서와 관계없이 모든 그리드 등록 완료
- `registerGridInstance` 이후 콜백(onAllReady) 1회 정상 실행
- 화면 종료 시 이벤트 해제/메모리 누수 징후 없음

## 렌더러 분해 영향 확인
- 액션 버튼 렌더러(`*-ActionCellRenderer`) 클릭 이벤트 정상
- 공통 렌더러(link/status/lookup) 정상
- lookup 팝업 열기/선택 반영 정상

## 요청 공통화 영향 확인
- POST/JSON 요청 응답 처리 정상
- CSRF 헤더 누락 오류 없음
- Search Form 값 조회(`getSearchFormValue`) 정상
- Search Form 엘리먼트 조회(`getSearchFieldElement`) 정상

## 우선 점검 대상 컨트롤러
- `code_grid_controller`
- `zone_grid_controller`
- `role_user_grid_controller`
- `user_menu_role_grid_controller`
- `std_favorite_grid_controller`
- `std_region_zip_grid_controller`
- `om_pre_order_file_upload_controller`
- `search_popup_grid_controller`

