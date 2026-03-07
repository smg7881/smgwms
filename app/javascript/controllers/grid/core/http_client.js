/**
 * HTML 문서의 `<head>` 태그 내부에 기록된 Rails CSRF 인증 토큰 값을 읽어옵니다.
 * 비동기 폼 POST 요청 시 백엔드 검증을 통과하기 위해 필수적입니다.
 * 
 * @returns {string} CSRF 토큰 문자열 (없으면 빈칸)
 */
export function getCsrfToken() {
  return document.querySelector("[name='csrf-token']")?.content || ""
}

/**
 * Rails 백엔드와 규격화된 JSON 통신을 주고 받기 위해 작성된 비동기 Fetch 래퍼 함수입니다.
 * 기본적으로 X-CSRF-Token 을 포함하며, 요청 Payload 파싱과 응답 JSON 변환까지 한 큐에 처리합니다.
 *
 * @param {string} url 요청 엔드포인트 URL
 * @param {Object} [options] Fetch 요청 옵션 및 커스텀 헤더 값들
 * @param {string} [options.method="GET"] HTTP 데이터 요청 방식 (GET, POST, PATCH, DELETE 등)
 * @param {any} [options.body] 서버로 보낼 본문 데이터 (JSON 화 되어 전송됨)
 * @param {AbortSignal} [options.signal] 요청 취소를 위한 AbortController 시그널
 * @param {Object} [options.headers={}] 추가 혹은 오버라이드 할 커스텀 헤더 객체
 * @param {boolean} [options.isMultipart=false] true 일 경우 `Content-Type: application/json` 강제 주입 해제 (파일 업로드 등)
 * @returns {Promise<{response: Response, result: any}>} HTTP 응답 메타 정보와 파싱된 JSON 객체를 담은 Promise
 */
export async function requestJson(url, {
  method = "GET",
  body,
  signal,
  headers = {},
  isMultipart = false
} = {}) {
  const mergedHeaders = {
    Accept: "application/json",
    "X-CSRF-Token": getCsrfToken(),
    ...headers
  }

  if (!isMultipart) {
    mergedHeaders["Content-Type"] = mergedHeaders["Content-Type"] || "application/json"
  }

  const response = await fetch(url, {
    method,
    headers: mergedHeaders,
    body: body == null ? undefined : (isMultipart ? body : JSON.stringify(body)),
    signal
  })

  const result = await response.json()
  return { response, result }
}

/**
 * 단순히 JSON 데이터(주로 옵션 목록 등)를 GET으로 읽어들일 때 사용하는 가벼운 Fetch 래퍼 함수입니다.
 * 응답이 200번대 밖으로 떨어지면(ok === false), 명시적으로 Error 객체를 Throw 합니다.
 *
 * @param {string} url 쿼리할 리소스 URL 경로
 * @param {Object} [options] Fetch 환경 설정
 * @param {AbortSignal} [options.signal] 요청 타임아웃/취소 연동을 위한 시그널
 * @returns {Promise<any>} 성공적으로 파싱된 JSON Payload 리턴
 * @throws {Error} HTTP 응답 코드가 정상이 아닐 시 발생
 */
export async function fetchJson(url, { signal } = {}) {
  const response = await fetch(url, {
    headers: { Accept: "application/json" },
    signal
  })

  if (!response.ok) {
    throw new Error(`HTTP ${response.status}`)
  }

  return response.json()
}

