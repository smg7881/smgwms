# AG Grid showLoadingOverlay Deprecation 수정

## 문제점
- AG Grid v32부터 `api.showLoadingOverlay()` 메서드가 Deprecated 되었습니다.
- 콘솔에 다음과 같은 경고 메시지가 출력됩니다:
  `AG Grid: Since v32 api.showLoadingOverlay is deprecated. Use the grid option "loading"=true instead or setGridOption("loading", true).`

## 해결 방법
- `showLoadingOverlay()` 대신 `setGridOption("loading", true/false)` API를 사용하도록 변경했습니다.

### 코드 변경 사항

**`app/javascript/controllers/ag_grid_controller.js`**

1. **데이터 로딩 시작 시**
   ```javascript
   // 변경 전
   this.gridApi.showLoadingOverlay()

   // 변경 후
   this.gridApi.setGridOption("loading", true)
   ```

2. **데이터 로딩 완료/실패 시**
   ```javascript
   // 추가됨 (로딩 상태 해제)
   this.gridApi.setGridOption("loading", false)
   ```

## 참고 사항
- `setGridOption("loading", true)`는 그리드 자체의 로딩 상태를 제어하며, 오버레이를 표시하는 새로운 표준 방식입니다.
- 데이터를 받아온 후나 에러 발생 시 반드시 `false`로 설정하여 로딩 표시를 제거해야 합니다.
