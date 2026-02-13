# AG Grid v35.1.0 Importmap & ESM 설정 가이드

이 문서는 AG Grid v35.1.0을 Rails Importmap 및 Stimulus와 함께 사용할 때, ESM 호환성 및 모듈 등록 문제를 해결하기 위한 설정 변경 사항을 설명합니다.

## 핵심 변경 사항

1.  **ESM 엔트리 고정**: `config/importmap.rb`에서 UMD 번들(`ag-grid-community.min.js`) 대신 ESM 엔트리(`main.esm.mjs`)를 사용하도록 변경했습니다.
2.  **명시적 모듈 등록**: Stimulus 컨트롤러에서 `ModuleRegistry`를 통해 `AllCommunityModule`을 등록했습니다. (v35+ 필수 사항)
3.  **Undefined Map 방지**: `columns` 값에 기본값(`[]`)을 추가하여 런타임 에러를 방지했습니다.

---

## 1. `config/importmap.rb` 수정

기본 배포 파일(`dist/ag-grid-community.min.js`)은 브라우저 글로벌 변수(`agGrid`)를 생성하는 UMD 번들로, Importmap이 사용하는 ESM import 방식에는 적합하지 않습니다.

**조치**: `ag-grid-community`를 `dist/package/main.esm.mjs` (ESM 엔트리 포인트)로 고정(pin)합니다.

```ruby
# config/importmap.rb

# AG Grid Community (ESM 엔트리로 pin)
pin "ag-grid-community",
  to: "https://cdn.jsdelivr.net/npm/ag-grid-community@35.1.0/dist/package/main.esm.mjs",
  preload: true
```

*   **버전**: 재현성을 위해 `35.1.0` (patch 버전까지)으로 고정했습니다.
*   **파일**: `main.esm.mjs`는 `import ... from "ag-grid-community"` 구문에 올바르게 대응하는 엔트리 포인트입니다.

---

## 2. Stimulus 컨트롤러 업데이트 (`ag_grid_controller.js`)

AG Grid v33+ (특히 v35)부터는 모듈식 아키텍처를 도입하여, 사용하는 기능을 명시적으로 등록해야 합니다.

**조치**: `AllCommunityModule`을 import하고 등록합니다. 또한, `columns` 값에 빈 배열 기본값을 설정합니다.

```javascript
// app/javascript/controllers/ag_grid_controller.js

import { Controller } from "@hotwired/stimulus"
import {
  createGrid,
  themeQuartz,
  ModuleRegistry,
  AllCommunityModule
} from "ag-grid-community"

// Community 기능 전체 사용 (CSV export, filter 등 포함)
ModuleRegistry.registerModules([AllCommunityModule])

export default class extends Controller {
  static targets = ["grid"]

  static values = {
    // ★ 중요: default: []를 두어 undefined.map 에러 방지
    columns: { type: Array, default: [] },
    url: String,
    rowData: { type: Array, default: [] },
    pagination: { type: Boolean, default: true },
    pageSize: { type: Number, default: 20 },
    height: { type: String, default: "500px" },
    rowSelection: { type: String, default: "" },
  }

  // ... (connect, disconnect, private 메서드 등 기존 로직 유지)
}
```

### 왜 필요한가요?

*   **ModuleRegistry**: 모듈을 등록하지 않으면 CSV 내보내기, 필터링, 렌더링 등의 기능이 작동하지 않거나 "module not registered" 경고가 발생합니다.
*   **Columns Default**: 서버에서 `data-ag-grid-columns-value` 속성 없이 HTML을 렌더링하거나 값이 지연될 경우, `this.columnsValue.map` 호출 시 컨트롤러가 충돌하는 것을 방지하기 위해 기본값 `[]`이 필요합니다.

---

## 3. 테마 API (Theming API)

기존에 사용하던 `themeQuartz.withParams({...})` 방식은 v35의 Theming API와 호환되므로 변경할 필요가 없습니다.

```javascript
const darkTheme = themeQuartz.withParams({ ... })
```

---

## 4. 검증

변경 사항 적용 후 다음을 확인하세요:

1.  **Network 탭**: `main.esm.mjs` 파일이 200 OK 상태로 로드되는지 확인합니다.
2.  **Console**: "Failed to create grid" 또는 "module not registered" 경고가 사라졌는지 확인합니다.
3.  **기능 확인**: `exportCsv()` 등의 기능이 정상적으로 작동하는지 테스트하여 모듈이 활성화되었는지 확인합니다.
