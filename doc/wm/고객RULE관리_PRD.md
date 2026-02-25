# 고객 RULE 관리 PRD

## 1. 개요
- **화면명**: 고객 RULE 관리 (Customer Rule Management)
- **메뉴 경로**: WMS > 고객 RULE 관리
- **화면 ID**: custRuleMngt.dev
- **목적**: 창고매니저가 고객별 Rule을 조회, 등록, 수정, 삭제하는 화면

## 2. User Flow (화면 간의 유기적인 흐름)
1. **조회**:
   - 사용자는 검색 필드에서 `작업장`, `고객`, `입출고구분`, `입출고유형`, `RULE 구분`, `사용(적용)여부`를 선택/입력 후 검색 버튼을 클릭한다.
   - 조건에 맞는 고객 RULE 목록이 그리드에 표시된다.
2. **고객/작업장 선택 팝업**:
   - 작업장 및 고객 필드는 돋보기 팝업 버튼을 제공하여, 팝업창에서 조회 후 부모 창에 적용된다.
3. **추가/수정/삭제 (인라인 그리드)**:
   - **추가**: 행추가 버튼을 클릭하여 새 행을 생성. `작업장`, `고객코드`는 현재 검색 조건이나 디폴트 값으로 채워짐. 필수값을 입력하고 '저장' 버튼을 클릭한다.
   - **수정**: 그리드의 Edit 필드(`입출고구분`, `입출고유형`, `RULE구분`, `적용여부`, `비고`)를 더블클릭/수정하고 '저장' 클릭.
   - **삭제**: 삭제할 행의 체크박스를 선택 후 '행삭제' 클릭 및 '저장'.

## 3. UI Component List (Rails 8 / ViewComponent)
`Ui::SearchFormComponent` 및 `Ui::AgGridComponent`를 바탕으로 한 시스템 표준 인라인 CRUD 페이지 구성을 사용한다.

- `Ui::SearchFormComponent` (조회 조건 구간)
  - `workpl_cd` (Popup/Input) - 작업장
  - `cust_cd` (Popup/Input) - 고객 (Customer)
  - `inout_sctn` (Select) - 입출고구분 (공통코드 82)
  - `inout_type` (Select) - 입출고유형 (공통코드 152 / 154)
  - `rule_sctn` (Select) - RULE 구분 (공통코드 106)
  - `aply_yn` (Select) - 적용(사용)여부 (공통코드 06)
- `Ui::GridHeaderComponent`
  - Title: "고객 Rule 목록"
  - Buttons: `행추가` (btn-primary), `행삭제` (btn-danger), `저장` (btn-success)
- `Ui::AgGridComponent`
  - Inline Editable Grid 세팅.
  - Columns: 상태, 작업장(R), 고객코드(R), 입출고구분(E), 입출고유형(E), RULE구분(E), 적용여부(E), 비고(E), 생성자, 생성일시, 수정자, 수정일시

## 4. Data Mapping
신규 테이블 `wm_cust_rules`을 생성하며, 각 필드는 다음과 매핑된다.

| 항목명(Kor) | Column명 | Type | Nullable | 비고 / 공통코드 |
|---|---|---|---|---|
| 작업장코드 | `workpl_cd` | String | False | 마스터(Session/선택) |
| 고객코드 | `cust_cd` | String | False | |
| 입출고구분 | `inout_sctn` | String | False | 코드: 82 |
| 입출고유형 | `inout_type` | String | False | 코드: 152(입고), 154(출고) |
| RULE 구분 | `rule_sctn` | String | False | 코드: 106 |
| 적용여부 | `aply_yn` | String(1) | False | 코드: 06 (기본: 'Y') |
| 비고 | `remark` | String | True | |
| (감사필드) | `create_by`, `create_time`, `update_by`, `update_time` | | | |

*Primary Key는 `id` 혹은 복합키(`workpl_cd`, `cust_cd`, `inout_sctn`, `inout_type`, `rule_sctn` 등 정책에 따름. 편의상 `id` + UUID 사용 또는 Rails 컨벤션 활용)*

## 5. Logic Definition
1. **행추가 로직** (`click->wm-cust-rule-grid#addRow`)
   - 빈 행을 맨 위에 삽입한다.
   - 신규 행의 `aply_yn` 기본값은 'Y'를 부여한다.
2. **행삭제 로직** (`click->wm-cust-rule-grid#deleteRows`)
   - 선택된 Row의 상태를 삭제(Delete) 모드로 변경하거나, 즉시 화면에서 지운 후 삭제 스택에 푸시한다 (BaseGridController 로직 활용).
3. **일괄 저장 로직** (`click->wm-cust-rule-grid#saveRows`)
   - GridCrudManager를 통해 Insert/Update/Delete 상태인 레코드들을 `/wm/cust_rules/batch_save` 엔드포인트로 전송한다.
   - 필수 필드(`inout_sctn`, `inout_type`, `rule_sctn`, `aply_yn`) 누락을 검증한다.
4. **입출고유형 Combo 연동 로직**
   - 입출고구분(82) 값이 '입고'이면 입출고유형(152) 콤보 리스트 표시.
   - 입출고구분 값이 '출고'이면 입출고유형(154) 콤보 리스트 표시.

## 6. 테스트 시나리오
1. **조회 테스트**: 아무 조건 없이 '검색' 클릭 시 전체 리스트가 조회되는가? 조건 입력 시 필터링되는가?
2. **행추가 테스트**: '행추가' 클릭 시 새 행이 생기고, 필수값 미입력 시 저장 실패 메시지가 뜨는가?
3. **저장/수정 테스트**: 값을 정상 입력하고 '저장' 클릭 시 DB에 변경사항이 반영되고 재조회 시 노출되는가?
4. **삭제 테스트**: 행 선택 후 '행삭제', '저장' 시 DB에서 삭제되는가?
5. **팝업 테스트**: 작업장 및 고객 팝업 클릭 시 팝업창이 열리고 반환된 값이 입력 필드에 들어가는가?
