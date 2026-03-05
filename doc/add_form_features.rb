require 'json'
require 'securerandom'

file_path = 'd:/myProject/smgWms/doc/ui_architecture.excalidraw'
data = JSON.parse(File.read(file_path))

# Shift resource_form elements down by 180 to make space for search_form note
data['elements'].each do |el|
  if el['y'] >= 900
    el['y'] += 180
  end
end

def create_note_text(x, y, text, color = "#e2e8f0")
  {
    "type" => "text",
    "id" => "note_#{SecureRandom.hex(4)}",
    "x" => x,
    "y" => y,
    "width" => 600,
    "height" => 100,
    "text" => text,
    "originalText" => text,
    "fontSize" => 16,
    "fontFamily" => 3,
    "textAlign" => "left",
    "verticalAlign" => "top",
    "strokeColor" => color,
    "backgroundColor" => "transparent",
    "fillStyle" => "solid",
    "strokeWidth" => 1,
    "strokeStyle" => "solid",
    "roughness" => 0,
    "opacity" => 100,
    "angle" => 0,
    "seed" => rand(1000..99999),
    "version" => 1,
    "versionNonce" => rand(1000..99999),
    "isDeleted" => false,
    "groupIds" => [],
    "boundElements" => [],
    "link" => nil,
    "locked" => false,
    "containerId" => nil,
    "lineHeight" => 1.5,
    "updated" => (Time.now.to_f * 1000).to_i,
    "autoResize" => true
  }
end

search_features = <<~TEXT
[ search_form 주요 기능 및 특징 ]
• 24-Column CSS Grid 적용: 해상도에 따라 동적인 필드 배치를 지원하는 반응형 검색 영역
• 상태 간소화 및 접기/펼치기: 사용자의 이전 검색창 상태(축소/확장) 유지 및 Toggle 지원
• 빠른 검색: 입력 필드에서 Enter 키 입력 시 별도 버튼 클릭 없이 자동 검색 트리거
• 파라미터 빌드: 모든 폼 필드 값을 순회하며 q[필드명] 형태의 JSON 쿼리 파라미터 자동 생성
TEXT

resource_features = <<~TEXT
[ resource_form 주요 기능 및 특징 ]
• 프론트엔드 유효성 검증: 필수값(required), 정규식(pattern), 선택값(enum) 등 실시간 검증
• 의존성 필드 동적 제어: 체크박스/Toggle 등 선택값 변경 시 연관 하위/상위 필드의 활성 상태 전환
• 특수 UI 컴포넌트 통합: Flatpickr(달력), TomSelect(검색가능 Select), Toggle Switch(.rf-switch) 연동
• 피드백 및 모달 제어: 실패 시 에러 폼 포커스 지정, 서버 저장 성공 시 Toast 알림과 함께 모달 닫힘
TEXT

# Add search_form note at y: 910
data['elements'] << create_note_text(140, 910, search_features.strip, "#bae6fd")

# Add resource_form note at y: 1270
data['elements'] << create_note_text(140, 1270, resource_features.strip, "#bae6fd")

File.write(file_path, JSON.pretty_generate(data))
