/**
 * search_popup_controller.js
 * 
 * 특정 필드(예: 창고, 품목 등)를 검색하기 위해 돋보기 아이콘을 눌렀을 때 나타나는 
 * [팝업 모달(Popup Modal)] 창을 띄우고 그 안의 동작을 제어하는 컨트롤러입니다.
 * 
 * - Turbo Frame을 이용해서 모달 안에 타 화면(검색 전용 페이지)을 비동기 로딩합니다.
 * - 모달 내에서 사용자가 특정 항목을 하나 '선택(Select)'하면 그 결과를 원래 화면의 인풋에 반영합니다.
 */
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    // code: 숨겨져 있는 실제 식별자(ID 또는 CD) 저장용 인풋
    // display: 사용자 눈에 보여지는 텍스트(이름) 저장용 인풋
    static targets = ["code", "display"]

    // type: 'item', 'warehouse' 등 무슨 데이터를 검색하는 창인지 식별하는 키 변수
    // url: (선택사항) 커스텀 검색 주소가 필요할 때 할당되는 엔드포인트
    static values = {
        type: String,
        url: String
    }

    connect() {
        // console.log("SearchPopup connected", this.typeValue)
    }

    // 돋보기 버튼 클릭 등 사용자가 팝업 열기를 트리거했을 때 실행
    async open(event) {
        event.preventDefault()

        const autoSelected = await this.tryAutoSelect()
        if (autoSelected) {
            return
        }

        // 1. 단일 모달 컨테이너 DOM 요소 탐색. 없으면 <dialog> 태그로 즉석 생성함.
        //    (여러 개의 팝업이 있더라도 화면 전체를 덮는 <dialog> 하나를 재활용함)
        let modal = document.getElementById("search-popup-modal")
        if (!modal) {
            modal = document.createElement("dialog")
            modal.id = "search-popup-modal"
            modal.className = "form-grid-modal" // 스타일 클래스 (form_modal 등과 유사)
            document.body.appendChild(modal)

            // 배경(Backdrop)인 회색 영역 클릭 시 모달 자동 닫기 처리
            modal.addEventListener("click", (e) => {
                if (e.target === modal) modal.close()
            })
        }

        // 2. 서버에서 모달 내용을 새로 불러올 주소 결정 
        //    URL이 명시되어있지 않다면 `/search_popups/{type}` 규약에 따름
        const baseUrl = this.urlValue || `/search_popups/${this.typeValue}`
        const src = `${baseUrl}?frame=search_popup_frame` // 쿼리 문자로 껍데기 말고 프레임만 달라고 표시

        // 3. 모달 컨테이너 내부에 뼈대 HTML 삽입 (이전 열렸던 모달 내용 초기화 효과 포함)
        //    핵심 로직: <turbo-frame id="search_popup_frame" src="...">를 배치하면 브라우저가 알아서 렌더링함
        modal.innerHTML = `
      <div class="form-grid-modal-content">
        <div class="form-grid-modal-header">
          <h3>${this.typeValue} 검색</h3>
          <button type="button" class="btn-close" onclick="document.getElementById('search-popup-modal').close()">×</button>
        </div>
        <div class="form-grid-modal-body">
           <turbo-frame id="search_popup_frame" src="${src}" loading="lazy">
             <div class="form-grid-loading">로딩 중...</div>
           </turbo-frame>
        </div>
      </div>
    `

        // 4. 모달 열기 명령 (브라우저 네이티브 Dialog API 호출)
        modal.showModal()

        // 5. 모달 안쪽의 Turbo Frame 화면에서 누군가가 행을 더블클릭/확인하여 "search-popup:select" 이벤트를
        //    버블링(위로 던지기) 했을 때, 그것을 낚아채는 일회성(once: true) 핸들러 등록
        const selectHandler = (e) => {
            this.select(e.detail) // 이벤트 상세 객체에 담긴 { code, display } 추출 후 본 컨트롤러의 목적지 인풋에 할당
            modal.close()
            modal.removeEventListener("search-popup:select", selectHandler) // 닫은 후 메모리 누수 방지 리스너 삭제
        }

        // 모달 DOM에 리스너 부착
        modal.addEventListener("search-popup:select", selectHandler, { once: true })
    }

    async tryAutoSelect() {
        const baseUrl = this.urlValue || `/search_popups/${this.typeValue}`
        const seedKeyword = this.seedKeyword
        if (!seedKeyword) {
            return false
        }

        const query = new URLSearchParams({
            q: seedKeyword,
            format: "json"
        })

        try {
            const response = await fetch(`${baseUrl}?${query.toString()}`, {
                headers: { Accept: "application/json" }
            })
            if (!response.ok) {
                return false
            }
            const rows = await response.json()
            if (!Array.isArray(rows)) {
                return false
            }
            if (rows.length !== 1) {
                return false
            }

            this.select(rows[0])
            return true
        } catch {
            return false
        }
    }

    get seedKeyword() {
        const code = this.hasCodeTarget ? this.codeTarget.value.toString().trim() : ""
        if (code) {
            return code
        }

        const display = this.hasDisplayTarget ? this.displayTarget.value.toString().trim() : ""
        return display
    }

    // 모달에서 값이 날아와 선택이 최종 이뤄진 시점에 돌아가는 콜백 역할
    select({ code, display }) {
        // 각 타겟 폼(input)에 값을 욱여넣음
        if (this.hasCodeTarget) this.codeTarget.value = code
        if (this.hasDisplayTarget) this.displayTarget.value = display

        // 데이터가 시스템이 아닌 브라우저 DOM 레벨 이벤트(사용자 타이핑 등)로 바꼈음을 
        // JS 에코시스템에 전파하기 위해 강제 change 이벤트를 발생시킴 (더티체킹, 의존성 필드 작동용)
        if (this.hasDisplayTarget) {
            this.displayTarget.dispatchEvent(new Event("change", { bubbles: true }))
        }
        if (this.hasCodeTarget) {
            this.codeTarget.dispatchEvent(new Event("change", { bubbles: true }))
        }
    }
}
