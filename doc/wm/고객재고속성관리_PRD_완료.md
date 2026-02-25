# 고객재고속성관리 (Customer Inventory Attribute Management) PRD

## 1. 개요
본 문서는 창고매니저가 고객재고속성을 조회, 등록, 수정, 삭제하는 화면에 대한 요구사항 및 시스템 설계 세부사항을 정의합니다. `screen-development-patterns`의 **유형 1: 조회조건 + 인라인 편집 그리드** 패턴을 따릅니다.

## 2. User Flow (화면 간 유기적인 흐름)
1. **메뉴 진입**: 사용자가 WMS 메뉴에서 `고객재고속성관리` 화면으로 진입합니다.
2. **검색 조건 설정**:
   - `고객`: 검색팝업을 띄워 고객을 선택합니다. (팝업에서 고객 선택 시 고객코드와 고객명이 부모 창으로 반환됨)
   - `입출고구분`: 기타코드(82) 목록에서 입출고구분을 선택합니다.
3. **목록 조회**: '검색' 버튼을 클릭하여 입력된 검색 조건에 맞는 고객재고속성 목록을 조회하여 그리드에 표시합니다.
4. **목록 추가/수정/삭제 (인라인 편집)**:
   - **추가**: '행추가' 버튼 클릭 시 빈 행이 그리드 최하단에 생성됩니다.
   - **수정**: 그리드 내의 셀을 클릭하여 값(입출고구분, 재고속성구분, 속성설명, 관련테이블, 관련칼럼, 사용여부)을 직접 변경합니다.
   - **삭제**: 삭제할 행의 체크박스를 선택하고 '행삭제' 버튼을 클릭합니다. (화면에서만 임시 삭제 상태 표시)
5. **목록 저장 (Batch Save)**:
   - '저장' 버튼을 클릭하여 추가, 수정, 삭제된 변경사항 모음을 백엔드로 일괄 전송(Batch Save)합니다.
   - 백엔드에서 트랜잭션 처리 후 성공/실패 메시지 팝업을 표시하고 그리드를 새로고침합니다.

## 3. UI Component List (Rails 8 기반 컴포넌트)
- **`System::BasePageComponent` 상속 페이지 컴포넌트**: 전체 레이아웃 구성 (`app/components/wm/cust_stock_attr/page_component.rb`)
- **`Ui::SearchFormComponent`**: 검색 조건 폼 (고객 팝업, 입출고구분 셀렉트)
- **`Ui::GridHeaderComponent`**: 그리드 상단 타이틀 및 공통 액션 버튼(추가/삭제/저장) 영역
- **`Ui::AgGridComponent`**: 데이터를 표시하고 인라인 편집을 수행하는 테이블 그리드

## 4. Data Mapping (데이터베이스 매핑)
- **Table Name**: `cust_stock_attrs` (추정)
- **Model**: `CustStockAttr`

| 화면 항목 (KOR) | 화면 항목 (ENG) | 백엔드 속성명 (Column) | 데이터 타입 | 속성 | 필수 (M/O) | 공통코드 연동 |
| --- | --- | --- | --- | --- | --- | --- |
| 고객코드 | Customer Code | `cust_cd` | String | PK (일부) | M | - |
| 고객명 | Customer Name | `cust_nm` | String | - | M | - (팝업) |
| 입출고구분 | InoutSection | `inout_sctn` | String | Editable | M | 기타코드분류: 82 |
| 재고속성구분 | StockAttributeSection | `stock_attr_sctn` | String | Editable | M | 기타코드분류: 101 |
| 속성설명 | AttributeDescription | `attr_desc` | String | Editable | O | - |
| 관련테이블 | RelationTable | `rel_tbl` | String | Editable | O | - |
| 관련칼럼 | RelationColumn | `rel_col` | String | Editable | O | - |
| 사용여부 | UseYesOrNo | `use_yn` | String | Editable | M | 기타코드분류: 06 |

## 5. Logic Definition (비즈니스 로직)
- **OPEN 이벤트**:
  - 입출고구분 조건의 드롭다운을 공통코드(82)로 채웁니다.
- **고객선택 (팝업) 이벤트**:
  - 고객명 찾기 아이콘 클릭 시 공통 거래처(거래처그룹-고객) 선택 팝업을 호출합니다.
  - 선택된 결과(고객코드, 고객명)가 검색 조건의 필드에 맵핑 및 바인딩됩니다.
- **조회 (Search) 로직**:
  - 매개변수: `cust_cd`, `inout_sctn`
  - 고객코드 단위로 필터링 된 데이터 레코드 세트를 반환하여 그리드에 표시합니다.
- **저장 (Batch Save) 처리 로직**:
  - **RowsToInsert (추가)**: 신규 행 데이터에 대한 유효성 검사 필수(고객코드, 입출고구분). 이후 DB에 INSERT 합니다.
  - **RowsToUpdate (수정)**: 변경된 행의 PK를 기준으로 찾아 데이터를 갱신(UPDATE) 합니다.
  - **RowsToDelete (삭제)**: 선택된 데이터의 PK를 기준으로 찾아 식별된 레코드를 DB에서 하드 삭제(DELETE) 합니다.
  - Transaction 단위로 묶어 처리하며 하나라도 실패 시 전체 롤백(Rollback) 합니다.
  - 처리 결과를 JSON 포맷 (`{ success: true, message: "...", data: {...} }`)으로 응답합니다.
