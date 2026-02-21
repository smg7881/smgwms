/**
 * application.js
 * 
 * Stimulus 애플리케이션의 초기화 및 기본 설정을 담당하는 파일입니다.
 * 이 파일에서 생성된 application 객체는 index.js 등에서 컨트롤러를 등록할 때 사용됩니다.
 */
import { Application } from "@hotwired/stimulus"

// 기본 Stimulus 애플리케이션 인스턴스를 시작합니다.
const application = Application.start()

// 디버그 모드 설정. true로 설정 시 콘솔에 Stimulus 내부 동작 로그가 출력됩니다. (개발 시 유용)
application.debug = false

// 브라우저의 전역 window 객체에 Stimulus 컨텍스트를 주입하여, 
// 디버깅 목적으로 브라우저 콘솔에서 컨트롤러 인스턴스에 접근할 수 있게 합니다.
window.Stimulus = application

// 다른 파일에서 import하여 사용할 수 있도록 application 인스턴스를 export 합니다.
export { application }
