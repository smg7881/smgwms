# System Controller Development Standard

## 1. 목적
- 본 문서는 `app/controllers/system/` 전체 소스를 분석해 도출한 표준 개발 규칙이다.
- 특히 `code` 도메인(`CodeController`, `CodeDetailsController`) 정리에 즉시 적용할 수 있도록 작성한다.
- 목표는 "동작 유지 + 규격 통일 + 유지보수성 향상"이다.

## 2. 분석 대상
- `app/controllers/system/base_controller.rb`
- `app/controllers/system/code_controller.rb`
- `app/controllers/system/code_details_controller.rb`
- `app/controllers/system/dept_controller.rb`
- `app/controllers/system/excel_import_tasks_controller.rb`
- `app/controllers/system/login_histories_controller.rb`
- `app/controllers/system/menus_controller.rb`
- `app/controllers/system/menu_logs_controller.rb`
- `app/controllers/system/notice_controller.rb`
- `app/controllers/system/roles_controller.rb`
- `app/controllers/system/role_user_controller.rb`
- `app/controllers/system/users_controller.rb`
- `app/controllers/system/user_menu_role_controller.rb`
- `test/controllers/system/*`

## 3. 현재 패턴 요약

### 3.1 공통점
- 대부분 `System::BaseController` 상속, 관리자 권한 전제.
- 검색 파라미터는 `params.fetch(:q, {}).permit(...)` 패턴 사용.
- `index`는 `html + json` dual response를 많이 사용.
- CRUD JSON 응답은 `{ success:, message:, ... }` 또는 `{ success: false, errors: [...] }` 패턴이 주류.
- private serializer 메서드(`*_json`)를 두는 패턴이 다수.

### 3.2 편차(정리 대상)
- Finder 정규화 편차:
  - 어떤 컨트롤러는 `strip/upcase` 적용, 일부는 raw `params[:id]` 사용.
- 삭제 정책 편차:
  - 트리/참조 보호(메뉴, 부서) vs 즉시 삭제(일부 도메인).
- 목록 응답 편차:
  - 일반 목록은 배열, 로그인 이력은 `{ rows, total }`.
- 배치 저장 구현 편차:
  - `code`, `roles`에 존재하나 메시지/에러/중복 처리 규칙이 완전히 동일하지 않음.
- 네임스페이스/파일 구조 편차:
  - 코드 도메인 컨트롤러가 `system/` 루트에 존재(향후 `system/code/` 구조 고려 가능).

## 4. 표준 분류(Controller Type)
- Type A: Grid CRUD + 검색 + (선택)배치저장
  - 예: `code`, `roles`, `menus`, `dept`, `users`, `notice`
- Type B: 조회 전용(로그/작업이력)
  - 예: `menu_logs`, `login_histories`, `excel_import_tasks`
- Type C: 관계/할당 관리 API
  - 예: `role_user`, `user_menu_role`

각 Type은 아래 공통 규칙을 따르고, 필요한 예외만 명시한다.

## 5. 공통 코딩 규칙

### 5.1 클래스/파일 규칙
- 클래스명과 경로를 최대한 일치시킨다.
- `code` 도메인 정리 시 권장 구조:

```text
app/controllers/system/code/
  base_controller.rb
  headers_controller.rb
  details_controller.rb
```

- 단, 기존 라우트/JS 계약을 즉시 깨면 안 되므로 단계적으로 이관한다.

### 5.2 메서드 순서 규칙
- public action 선언 순서:
  - `index`, `show`, `create`, `update`, `destroy`, `batch_save`, 기타 custom action
- `private` 아래 순서:
  - finder
  - scope/search
  - params(Strong Params)
  - serializer
  - helper

### 5.3 Finder 정규화 규칙
- 코드성 키는 조회 전에 표준화한다.
  - `to_s.strip.upcase`
- 숫자 PK는 `to_i` 또는 ActiveRecord 기본 find를 사용한다.
- 원칙:
  - `code`, `role_cd`, `menu_cd`, `dept_code`, `detail_code`, `user_id_code`는 정규화 후 조회.

## 6. 액션별 표준 계약

### 6.1 index
- 기본: `respond_to do |format|` 사용.
- `html`: 화면 렌더링.
- `json`:
  - 비페이지형: 배열 반환 (`render json: rows.map { ... }`)
  - 페이지형(Type B): `{ rows:, total:, page:, per_page: }` 권장.

### 6.2 create/update/destroy
- 성공:
  - `{ success: true, message: "...", resource_key: serializer(resource) }`
  - 삭제는 필요 시 `resource_key` 생략 가능.
- 실패:
  - `{ success: false, errors: [...] }`, `status: :unprocessable_entity`
- update 시 PK 수정 금지:
  - attrs 변환 후 PK 삭제(`attrs.delete(...)`).

### 6.3 batch_save (사용 도메인 한정)
- 입력 키는 고정:
  - `rowsToInsert`, `rowsToUpdate`, `rowsToDelete`
- 단일 트랜잭션 처리.
- 개별 행 에러 수집 후 1건이라도 있으면 rollback.
- 응답:
  - 성공: `{ success: true, message: "...", data: { inserted:, updated:, deleted: } }`
  - 실패: `{ success: false, errors: errors.uniq }`, `status: :unprocessable_entity`

## 7. 검색/파라미터 표준
- 검색 파라미터는 `search_params`로 통일.
- 모든 검색 조건은 `q` 네임스페이스 사용.
- SQL LIKE 조건은 파라미터 바인딩 사용 (`where("x LIKE ?", "%#{...}%")`).
- 날짜/시간 검색은 파싱 헬퍼를 공통화한다.
  - 권장: `parse_time_param(value)` 헬퍼(실패 시 nil).

## 8. JSON 직렬화 표준
- `render json: model` 직접 반환보다 `*_json` serializer 메서드 사용을 기본으로 한다.
- serializer 키 규칙:
  - 그리드 key로 쓰는 `id` 반드시 포함.
  - 화면 컬럼과 동일한 필드명 유지.
- 배열 응답은 반드시 serializer를 거친다.

## 9. 삭제 정책 표준
- 도메인별 삭제 정책을 문서로 고정하고, 단건/배치 동작을 동일하게 맞춘다.
- 정책 유형:
  - `restrict`: 하위/참조 존재 시 삭제 불가(메뉴/부서형)
  - `cascade`: 하위 데이터 먼저 삭제 후 본체 삭제
- `code` 도메인 현재 이슈:
  - 단건 destroy와 batch destroy 정책 차이가 생기기 쉬움.
  - 정리 시 단일 정책으로 통일해야 한다.

## 10. 예외 도메인 표준

### 10.1 Notice(첨부파일 포함)
- 파라미터 병합(`adm_notice`/`notice`)은 한 곳(`notice_params`)에서 처리.
- 첨부파일 처리 메서드 분리:
  - `uploaded_attachments`, `removed_attachment_ids`, `attach_files`, `purge_files`
- show/create/update 응답에는 첨부 메타 포함 옵션을 명시한다.

### 10.2 Role/User Assignment
- 집합 갱신 API는 트랜잭션 필수.
- 입력 배열은 `uniq + blank 제거`.
- 도메인 검증 실패는 `422 + errors`.

### 10.3 Logs/History
- 조회 전용 컨트롤러는 CUD action을 두지 않는다.
- 대량 데이터는 페이지네이션 표준 적용.

## 11. 권한/보안 표준
- `System::BaseController`의 `require_admin!`를 기본 보안 경계로 사용.
- 비관리자 접근 시 `403` 계약을 테스트로 고정.
- Strong Params 외 입력값은 저장 로직에 직접 전달하지 않는다.

## 12. 테스트 표준
- 위치: `test/controllers/system/*_controller_test.rb`
- 최소 케이스:
  - index html/json 성공
  - create/update/destroy 성공/실패
  - 비관리자 403
  - batch_save(있는 경우): insert/update/delete + rollback 케이스
  - 삭제 정책(restrict/cascade) 검증
- JSON 계약 테스트:
  - 필수 키(`id`, 주요 컬럼, success/errors/data`) 존재 검증

## 13. Code 도메인 정리 가이드(즉시 적용)

### 13.1 구조
- 1단계: 기존 `System::CodeController`, `System::CodeDetailsController` 유지 + 규격 통일.
- 2단계: `System::Code::*Controller`로 이관(필요 시 route alias 유지).

### 13.2 통일 우선순위
1. Finder 정규화 통일(`code_id`, `detail_code`, `id`)
2. 단건/배치 삭제 정책 통일
3. batch_save 에러/메시지 규약 통일
4. serializer 키/응답 구조 통일
5. 테스트 강화(rollback/정책 일치)

### 13.3 권장 응답 예시
```json
{
  "success": true,
  "message": "코드 저장이 완료되었습니다.",
  "data": { "inserted": 1, "updated": 2, "deleted": 0 }
}
```

## 14. 체크리스트
- [ ] `search_params`는 `q` 기반인가
- [ ] Finder에 코드 정규화가 반영되었는가
- [ ] update에서 PK 수정이 차단되는가
- [ ] serializer를 통해 응답하는가
- [ ] batch_save가 트랜잭션 + rollback + 표준 응답을 지키는가
- [ ] 삭제 정책이 단건/배치에서 동일한가
- [ ] 비관리자 403 테스트가 있는가

## 15. 운영 원칙
- 기능 추가보다 계약 통일을 우선한다.
- 컨트롤러는 요청/응답 조립에 집중하고, 복잡한 규칙은 모델/도메인 로직으로 이동한다.
- 표준 위반이 필요한 경우, 주석과 테스트로 의도를 명시한다.
