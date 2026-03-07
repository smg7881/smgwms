import ClientGridController from "controllers/std/client_grid_controller"

export default class extends ClientGridController {
  masterConfig() {
    const config = super.masterConfig()

    return {
      ...config,
      saveMessage: "고객거래처 데이터가 저장되었습니다.",
      pendingEntityLabel: "마스터 고객거래처",
      key: {
        ...config.key,
        entityLabel: "고객거래처",
        emptyMessage: "고객거래처를 먼저 선택하세요."
      }
    }
  }

  detailGrids() {
    return super.detailGrids().map((detail) => {
      if (detail.role === "contacts") {
        return {
          ...detail,
          entityLabel: "고객거래처",
          selectionMessage: "고객거래처를 먼저 선택해주세요.",
          saveMessage: "고객거래처 담당자 데이터가 저장되었습니다."
        }
      }

      if (detail.role === "workplaces") {
        return {
          ...detail,
          entityLabel: "고객거래처",
          selectionMessage: "고객거래처를 먼저 선택해주세요.",
          saveMessage: "고객거래처 작업장 데이터가 저장되었습니다."
        }
      }

      return detail
    })
  }

  masterManagerConfig() {
    const config = super.masterManagerConfig()
    const validationRules = config.validationRules || {}
    const fieldLabels = validationRules.fieldLabels || {}
    const pkLabels = config.pkLabels || {}

    return {
      ...config,
      pkLabels: {
        ...pkLabels,
        bzac_cd: "고객거래처코드"
      },
      validationRules: {
        ...validationRules,
        fieldLabels: {
          ...fieldLabels,
          bzac_nm: "고객거래처명",
          bzac_sctn_grp_cd: "고객거래처구분그룹",
          bzac_sctn_cd: "고객거래처구분",
          bzac_kind_cd: "고객거래처종류"
        }
      }
    }
  }
}
