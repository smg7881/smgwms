# AG Grid 및 Favicon 404 오류 수정 내역

## 1. AG Grid 404 오류 수정

### 문제점
- `config/importmap.rb`에서 지정한 `ag-grid-community`의 버전(`35.1.0`)이 유효하지 않아 404 오류가 발생했습니다.
- 해당 URL: `https://cdn.jsdelivr.net/npm/ag-grid-community@35.1.0/dist/ag-grid-community.auto.esm.min.js` (존재하지 않음)

### 해결 방법
1. **버전 변경**: 안정적인 최신 버전인 `32.3.3`으로 변경했습니다.
2. **Import 경로 변경**: 브라우저의 `importmap`과 호환성을 위해 JSDelivr에서 제공하는 표준 ESM 래퍼(`+esm`)를 사용하도록 경로를 수정했습니다.
   - 변경 후 URL: `https://cdn.jsdelivr.net/npm/ag-grid-community@32.3.3/+esm`

### 코드 변경 사항

**`config/importmap.rb`**
```ruby
# 변경 전
pin "ag-grid-community", to: "https://cdn.jsdelivr.net/npm/ag-grid-community@35.1.0/dist/ag-grid-community.auto.esm.min.js"

# 변경 후
pin "ag-grid-community", to: "https://cdn.jsdelivr.net/npm/ag-grid-community@32.3.3/+esm"
```

**`app/javascript/controllers/ag_grid_controller.js`**
- `AllCommunityModule` 등 불필요하거나 존재하지 않는 모듈의 Import를 제거하고, `createGrid`, `themeQuartz`를 직접 Import 하도록 수정했습니다.

```javascript
// 변경 후
import {
  createGrid,
  themeQuartz
} from "ag-grid-community"
```

---

## 2. Favicon 404 오류 수정

### 문제점
- 브라우저가 자동으로 요청하는 `/favicon.ico` 파일이 `public` 디렉토리에 없어 404 오류가 발생했습니다.

### 해결 방법
- `app/views/layouts/application.html.erb` 파일의 `<head>` 태그 내에 명시적으로 파비콘 경로를 지정했습니다.
- `public/icon.png` 파일을 파비콘으로 사용하도록 설정했습니다.

### 코드 변경 사항

**`app/views/layouts/application.html.erb`**
```erb
<head>
  ...
  <title>WMS Pro</title>
  <link rel="icon" href="/icon.png" type="image/png"> <!-- 추가됨 -->
  ...
</head>
```
