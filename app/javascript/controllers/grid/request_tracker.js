/**
 * request_tracker.js
 * 
 * Fetch API 등 비동기 네트워크 요청 시 이전 요청을 취소(Abort)하고
 * 항상 최후의 요청만 유효하도록 보장해주는 토큰(AbortController) 추적 유틸리티입니다.
 * (Debounce/Throttle을 보완하는 레이스 컨디션 방지 목적)
 */
export class AbortableRequestTracker {
  constructor() {
    this.requestId = 0            // 발급된 요청 시퀀스 번호
    this.abortController = null   // 현재 활성화된 Fetch AbortController 인스턴스
  }

  // 신규 요청을 시작할 때 호출하며, 이전 요청이 있다면 취소(Cancel)시킵니다.
  begin() {
    this.cancelCurrent()
    this.requestId += 1
    this.abortController = new AbortController()

    return {
      requestId: this.requestId,
      signal: this.abortController.signal // fetchOptions 에 주입할 signal 반환
    }
  }

  // 응답이 돌아왔을 때, 해당 응답이 가장 마지막에 요청한 구문인지 식별합니다. (낡은 데이터 렌더 방지)
  isLatest(requestId) {
    return requestId === this.requestId
  }

  // 비동기 요청이 성공적으로 완료되면 호출하여 컨트롤러를 메모리에서 해제합니다.
  finish(requestId) {
    if (!this.isLatest(requestId)) return
    this.abortController = null
  }

  // 현재 활성 상태인 비동기 요청을 즉시 강제 취소(Abort)합니다.
  cancelCurrent() {
    if (!this.abortController) return
    this.abortController.abort() // 연계된 fetch() 들이 AbortError를 발생시키며 중단됨
    this.abortController = null
  }

  // ID 시퀀스를 올린 후 모두 취소 (보통 페이지 이동, 컴포넌트 마운트 해제 시 사용됨)
  cancelAll() {
    this.requestId += 1
    this.cancelCurrent()
  }
}

// Fetch Catch 블록에서 발생한 에러가 의도된 요청 취소인지 점검하는 헬퍼 함수
export function isAbortError(error) {
  return error?.name === "AbortError"
}
