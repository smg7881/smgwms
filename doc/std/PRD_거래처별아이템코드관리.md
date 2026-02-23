# PRD: 거래처별아이템코드관리

## 1. 개요
- 기능명: 거래처별아이템코드관리
- 원본 화면 ID: `bzacEachItemCdMngt`
- 메뉴 위치: `기준정보(STD)` 하위
- 목표:
  - 거래처별 아이템 코드/속성 정보를 조회/등록/수정/삭제(소프트 삭제)한다.
  - 그리드에서 관리 대상 항목을 모두 표시한다.
  - 그리드 상단 `항목추가` 버튼으로 입력 팝업을 열어 등록한다.
  - 그리드 `작업항목` 컬럼에 수정/삭제 아이콘을 제공한다.

## 2. 소스 문서
- `D:\_LOGIS\1.공통\pdf\LogisT-CM-AN13(화면정의서-V1.0)_거래처별아이템코드관리_20100607.pdf`
- `D:\_LOGIS\1.공통\pdf\LogisT-CM-DS02(화면설계서-V1.0)-거래처별아이템코드관리.pdf`

## 3. 구현 범위
- DB:
  - 신규 테이블 `std_client_item_codes`
  - 코드성 선택값(단위코드) 신규 코드셋 생성
- 백엔드:
  - `StdClientItemCode` 모델
  - `Std::ClientItemCodesController` (HTML/JSON + 모달 CRUD)
- 프론트:
  - `Std::ClientItemCode::PageComponent`
  - `std-client-item-code-crud` Stimulus 컨트롤러
  - AG Grid 액션 렌더러(`작업항목`)
- 라우트:
  - `GET /std/client_item_codes`
  - `POST /std/client_item_codes`
  - `PATCH /std/client_item_codes/:id`
  - `DELETE /std/client_item_codes/:id`
- 메뉴/권한:
  - `adm_menus`: `STD_CLIENT_ITEM`
  - `adm_user_menu_permissions`: 기존 사용자 전체 기본 `Y` 부여

## 4. 화면/UX 요구사항
- 검색영역:
  - 거래처(팝업), 거래처아이템코드, 아이템명, 사용여부
- 그리드:
  - 문서 기준 상세 입력 항목을 전부 컬럼으로 표시
  - 마지막 컬럼 `작업항목`: 수정(`✎`) / 삭제(`X`)
- 입력:
  - 그리드 상단 `항목추가` 버튼 클릭 시 모달 팝업 오픈
  - 입력 폼 순서는 화면설계서(1.3.3) 순서와 동일
  - 기본값:
    - `use_yn_cd = Y`
    - 등록자/수정자/등록일시/수정일시는 현재 사용자/현재시각
- 삭제:
  - 물리삭제 대신 `use_yn_cd = N` 처리

## 5. 데이터 모델
- 테이블명: `std_client_item_codes`
- PK: `id` (Rails 기본 정수 PK)
- 유니크 키: `(bzac_cd, item_cd)`
- 컬럼 목록:
  - `item_cd`, `item_nm`
  - `bzac_cd`
  - `goodsnm_cd`
  - `danger_yn_cd`, `png_yn_cd`, `mstair_lading_yn_cd`, `if_yn_cd`
  - `wgt_unit_cd`, `qty_unit_cd`, `tmpt_unit_cd`, `vol_unit_cd`, `basis_unit_cd`, `len_unit_cd`
  - `pckg_qty`, `tot_wgt_kg`, `net_wgt_kg`
  - `vessel_tmpt_c`, `vessel_width_m`, `vessel_vert_m`, `vessel_hght_m`, `vessel_vol_cbm`
  - `use_yn_cd`, `prod_nm_cd`
  - `regr_nm_cd`, `reg_date`, `mdfr_nm_cd`, `chgdt`
  - `create_by`, `create_time`, `update_by`, `update_time`

## 6. 입력 항목 순서 (화면설계서 기준)
1. `item_cd`
2. `item_nm`
3. `bzac_cd`
4. `goodsnm_cd`
5. `danger_yn_cd`
6. `png_yn_cd`
7. `mstair_lading_yn_cd`
8. `if_yn_cd`
9. `wgt_unit_cd`
10. `qty_unit_cd`
11. `tmpt_unit_cd`
12. `vol_unit_cd`
13. `basis_unit_cd`
14. `len_unit_cd`
15. `pckg_qty`
16. `tot_wgt_kg`
17. `net_wgt_kg`
18. `vessel_tmpt_c`
19. `vessel_width_m`
20. `vessel_vert_m`
21. `vessel_hght_m`
22. `vessel_vol_cbm`
23. `use_yn_cd`
24. `prod_nm_cd`
25. `regr_nm_cd`
26. `reg_date`
27. `mdfr_nm_cd`
28. `chgdt`

## 7. 공통코드/팝업 연동
- Y/N: `CMM_USE_YN`
- 단위코드(신규):
  - `STD_WGT_UNIT` (중량)
  - `STD_QTY_UNIT` (수량)
  - `STD_TMPT_UNIT` (온도)
  - `STD_VOL_UNIT` (부피)
  - `STD_BASIS_UNIT` (기본)
  - `STD_LEN_UNIT` (길이)
- 팝업:
  - 거래처: `popup_type = client`
  - 품명: `popup_type = good` (신규 매핑)

## 8. 권한/메뉴
- 메뉴 코드: `STD_CLIENT_ITEM`
- 메뉴명: `거래처별아이템코드관리`
- URL: `/std/client_item_codes`
- 탭 ID: `std-client-item-codes`
- 부모 메뉴: `STD`(`기준정보`)
- 비관리자 접근:
  - `adm_user_menu_permissions`에서 `menu_cd=STD_CLIENT_ITEM` + `use_yn=Y`일 때 허용

## 9. 검증 규칙
- 필수:
  - `item_cd`, `item_nm`, `bzac_cd`, `goodsnm_cd`
  - `danger_yn_cd`, `png_yn_cd`, `mstair_lading_yn_cd`, `if_yn_cd`
  - `use_yn_cd`, `prod_nm_cd`
- Y/N 필드: `Y` 또는 `N`
- 숫자 필드: 음수 불가
- 코드/명칭 값: trim + 코드 uppercase 정규화

## 10. 테스트 기준
- 컨트롤러:
  - HTML/JSON 조회 성공
  - 생성/수정/삭제(소프트) 성공
  - 비관리자 권한 미부여 시 `403`
  - 비관리자 권한 부여 시 정상 응답
- 모델:
  - 정규화(trim/uppercase/default) 검증
  - 필수값/유니크키 검증
