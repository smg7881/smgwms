## 변경 요약
- 

## 검증 방법
1. 

## 체크리스트
- [ ] `ruby bin/rails test` 통과
- [ ] `ruby bin/rubocop` 통과
- [ ] 메뉴/권한/라우트 영향 범위 확인
- [ ] 화면 변경 시 스크린샷 또는 동영상 첨부

### Master-Detail 패턴 체크
- [ ] `BaseGridController + gridRoles()` 패턴 사용
- [ ] `masterGrid` / `detailGrid` 타겟 사용
- [ ] master/detail 각각 `batch_save` 계약 유지
- [ ] `config/master_detail_screen_contracts.yml` 등록 또는 변경 없음 확인
- [ ] `test/contracts/master_detail_pattern_contract_test.rb` 통과

## 예외 사항(선택)
- 표준 패턴에서 벗어난 경우 사유와 대체 설계를 작성합니다.
