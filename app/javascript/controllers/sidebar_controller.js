/**
 * sidebar_controller.js
 * 
 * 좌측 네비게이션 트리형 메뉴에서 하위 폴더(자식 메뉴)를 갖고 있는 디렉토리 노드를
 * 클릭했을 때, 목록을 접고 펴는(아코디언 형태) 토글 UI만 전담하는 마이크로 컨트롤러입니다.
 */
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // 클릭 이벤트에서 전달받아 하위 컨테이너 토글
  toggleTree(event) {
    const button = event.currentTarget // 클릭한 <a> 또는 <div> 뎁스 엘리먼트
    // 트리 구조상 자식 폴더목록 컨테이너는 바로 아래 형제(nextElementSibling)에 위치함
    const children = button.nextElementSibling

    // 타겟이 없거나 클래스가 안맞으면 조기리턴 (하위 폴더가 없는 단말 메뉴일 경우 등)
    if (!children || !children.classList.contains("nav-tree-children")) return

    // 자신 버튼 아이콘(화살표 회전 등)을 의미하는 expanded 토글 상태 갱신
    const expanded = button.classList.toggle("expanded")

    // 하위 목록(ul) 표시 여부인 open 토글
    children.classList.toggle("open", expanded)

    // 스크린컨트롤(접근성) 위해 속성 변경
    button.setAttribute("aria-expanded", expanded ? "true" : "false")
  }
}
