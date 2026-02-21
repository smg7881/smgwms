/**
 * lucide_controller.js
 * 
 * 외부 오픈소스 아이콘 라이브러리인 'lucide' 스크립트를 사용하여 
 * 문서상의 특정 태그(예: <i data-lucide="home"></i>)를 실제 SVG 이미지 객체로 변형시키는 컨트롤러입니다.
 * 
 * Turbo 페이지 라우팅 특성 상 DOM이 수시로 교체되므로, 
 * 문서 렌더링 이벤트(turbo:load, turbo:frame-load 등)가 발생할 때마다 아이콘 바인딩을 리프레시합니다.
 */
import { Controller } from "@hotwired/stimulus"
import { createIcons, icons } from "lucide"

export default class extends Controller {
  connect() {
    // this 바인딩을 유지하여 리스너 삭제 시 동일 객체 포인터를 식별하도록 함
    this.renderIcons = this.renderIcons.bind(this)

    this.renderIcons() // 생성 직후 즉시 변환

    // Turbo 전용 이벤트들에 재렌더링 예약
    document.addEventListener("turbo:load", this.renderIcons)
    document.addEventListener("turbo:frame-load", this.renderIcons)
    document.addEventListener("turbo:render", this.renderIcons)
  }

  // 화면 요소 소멸 시 불필요 이벤트 리스너 제거 방어
  disconnect() {
    document.removeEventListener("turbo:load", this.renderIcons)
    document.removeEventListener("turbo:frame-load", this.renderIcons)
    document.removeEventListener("turbo:render", this.renderIcons)
  }

  // 실제 lucide 라이브러리를 콜하여 DOM SVG 교체
  renderIcons() {
    createIcons({ icons })
  }
}
