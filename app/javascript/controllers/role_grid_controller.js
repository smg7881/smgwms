/**
 * role_grid_controller.js
 * 
 * [공통] BaseGridController 상속체로서 "권한(Role) 그룹 마스터" 단일 그리드의 CRUD 특수설정을 명세합니다.
 */
import BaseGridController from "controllers/base_grid_controller"

export default class extends BaseGridController {
  // 매니저 구축
  configureManager() {
    return {
      pkFields: ["role_cd"],   // 고유 식별자 키는 role_cd (권한 식별코드)
      fields: {
        role_cd: "trim",       // 코드는 띄어쓰기 정도만 트림 
        role_nm: "trim",       // 이름 트림
        description: "trim",   // 설명 트림
        use_yn: "trimUpperDefault:Y" // 사용여부 대문자 Y/N 클렌징 및 디폴트
      },
      // 신규 등록버튼 클릭 시 떨어지는 가상 행 데이터
      defaultRow: { role_cd: "", role_nm: "", description: "", use_yn: "Y" },
      blankCheckFields: ["role_cd", "role_nm"], // 필수값 검사 대상
      comparableFields: ["role_nm", "description", "use_yn"], // 수정 상태 판별할 때 대조할 값
      firstEditCol: "role_cd",
      pkLabels: { role_cd: "역할코드" }
    }
  }

  get saveMessage() {
    return "역할 데이터가 저장되었습니다."
  }
}
