require 'json'

file_path = 'doc/ui_architecture.excalidraw'
data = JSON.parse(File.read(file_path))

data['appState'] ||= {}
data['appState']['theme'] = 'dark'
data['appState']['viewBackgroundColor'] = '#1e1e1e'

scale_x = 1.4

# 다크 모드에서 가독성을 높이기 위해 진한 테두리/글씨 색상을 밝게 변경
COLOR_MAP = {
  "#1e40af" => "#93c5fd",
  "#3b82f6" => "#bfdbfe",
  "#64748b" => "#cbd5e1",
  "#c2410c" => "#fdba74",
  "#047857" => "#6ee7b7",
  "#b91c1c" => "#fca5a5",
  "#1e3a5f" => "#ffffff"
}

data['elements'].each do |el|
  el['x'] = (el['x'] * scale_x).to_i
  el['width'] = (el['width'] * scale_x).to_i

  if el['type'] == 'arrow'
    el['points'].map! { |p| [ (p[0] * scale_x).to_i, p[1] ] }
  end

  if el['strokeColor'] && COLOR_MAP[el['strokeColor']]
    el['strokeColor'] = COLOR_MAP[el['strokeColor']]
  end
end

File.write(file_path, JSON.pretty_generate(data))
