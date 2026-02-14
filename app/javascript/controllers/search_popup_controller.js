import { Controller } from "@hotwired/stimulus"

// Phase 3: Popup Modal Controller
// - Opens a modal dialog
// - Loads content via Turbo Frame
// - Handles selection
export default class extends Controller {
    static targets = ["code", "display"]
    static values = {
        type: String,
        url: String // Optional: URL to fetch the popup content (default to standard pattern)
    }

    connect() {
        // console.log("SearchPopup connected", this.typeValue)
    }

    open(event) {
        event.preventDefault()

        // 1. Create or Find Modal Container
        let modal = document.getElementById("search-popup-modal")
        if (!modal) {
            modal = document.createElement("dialog")
            modal.id = "search-popup-modal"
            modal.className = "form-grid-modal"
            document.body.appendChild(modal)

            // Close on backdrop click
            modal.addEventListener("click", (e) => {
                if (e.target === modal) modal.close()
            })
        }

        // 2. Construct URL
        const baseUrl = this.urlValue || `/search_popups/${this.typeValue}`
        const src = `${baseUrl}?frame=search_popup_frame`

        // 3. Set Content (Turbo Frame)
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

        // 4. Show Modal
        modal.showModal()

        // 5. Listen for selection event (bubbled from inside the frame)
        // The frame content should emit 'search-popup:select' with detail: { code, display }
        const selectHandler = (e) => {
            this.select(e.detail)
            modal.close()
            modal.removeEventListener("search-popup:select", selectHandler)
        }

        // We attach to the modal because the frame content is dynamic
        modal.addEventListener("search-popup:select", selectHandler, { once: true })
    }

    // Called when selection is made
    select({ code, display }) {
        if (this.hasCodeTarget) this.codeTarget.value = code
        if (this.hasDisplayTarget) this.displayTarget.value = display

        // Trigger change event for dirty checking if needed
        this.displayTarget.dispatchEvent(new Event("change", { bubbles: true }))
    }
}

