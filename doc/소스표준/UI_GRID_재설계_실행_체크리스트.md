# UI/Grid 재설계 실행 체크리스트

## 공통 준비
- [ ] 기준 브랜치 생성
- [ ] 화면별 담당자 지정
- [ ] 기능 동결 범위 공지
- [ ] 회귀 테스트 대상 시나리오 확정

## 화면 단위 체크리스트

### A. PageComponent
- [ ] `collection_path`, `member_path` 구현
- [ ] master/detail URL template 주입
- [ ] search/master/detail 컬럼 분리
- [ ] selected label 값 주입

### B. Stimulus
- [ ] `BaseGridController` 상속
- [ ] `gridRoles()`에 master/detail 정의
- [ ] `detailLoader` 구현
- [ ] `masterManagerConfig`/`detailManagerConfig` 분리
- [ ] `saveMasterRows`/`saveDetailRows` 구현
- [ ] detail 액션 전 `blockIfPendingChanges` 호출
- [ ] `beforeSearchReset` 초기화 구현

### C. Controller
- [ ] `index` html/json dual response
- [ ] `batch_save` 트랜잭션 처리
- [ ] FK 서버 강제 주입
- [ ] 에러 응답 `errors.uniq`

### D. 테스트/검증
- [ ] 컨트롤러 테스트 추가/수정
- [ ] 계약 테스트 통과
- [ ] `bin/rubocop` 통과
- [ ] `bin/brakeman --no-pager` 통과

### E. 정리
- [ ] 레거시 분기 제거
- [ ] 중복 유틸 제거
- [ ] 문서 업데이트

## 우선순위 화면(권장)
1. wm/gr_prars
2. wm/pur_fee_rt_mngs
3. wm/sell_fee_rt_mngs
4. wm/rate_retroacts
5. std/work_routing_step

## 릴리즈 게이트
- [ ] 파일럿 화면 1개 운영 검증 완료
- [ ] 동일 패턴 화면 2개 연속 전환 완료
- [ ] 공통 모듈 사용률 증가(중복 코드 감소 확인)
