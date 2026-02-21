/**
 * workplace_grid_controller.js
 * 
 * [공통] BaseGridController 상속체로서 "사업장/작업장(Workplace) 마스터" 관리를 위한 단일 그리드 로직을 제어합니다.
 * 단순 조회 및 공통 저장 처리에 필요한 CRUD 설정(Manager Configuration)만 주입합니다.
 */
import BaseGridController from "controllers/base_grid_controller"

export default class extends BaseGridController {
  configureManager() {
    return {
      pkFields: ["workpl_cd"], // 기본 고유 키
      fields: {
        // 백엔드 요청 전 데이터 정제(Cleansing) 방식 
        workpl_cd: "trimUpper", // 공백 차단, 영문 무조건 대문자 (Workplace Code)
        workpl_nm: "trim",      // 공백 제거
        workpl_type: "trimUpper",
        nation_cd: "trimUpper",
        zip_cd: "trim",
        addr: "trim",
        addr_dtl: "trim",
        tel_no: "trim",
        use_yn: "trimUpperDefault:Y" // 사용여부, 값 없으면 Y
      },
      // 신규 추가 누를때 떨어지는 디폴트 포맷
      defaultRow: {
        workpl_cd: "", workpl_nm: "", workpl_type: "", nation_cd: "",
        zip_cd: "", addr: "", addr_dtl: "", tel_no: "", use_yn: "Y"
      },
      // 작성안하고 저장버튼 누르면 Validation 에러 뱉을 대상 컬럼명
      blankCheckFields: ["workpl_cd", "workpl_nm"],

      // 저장버튼 클릭 전 데이터 변경점을 감지하기 위한 비교군
      comparableFields: ["workpl_nm", "workpl_type", "nation_cd", "zip_cd", "addr", "addr_dtl", "tel_no", "use_yn"],
      firstEditCol: "workpl_cd",
      pkLabels: { workpl_cd: "작업장코드" } // 중복 등 에러 통보 시 조합 노출명
    }
  }

  get saveMessage() {
    return "작업장 데이터가 저장되었습니다."
  }
}
