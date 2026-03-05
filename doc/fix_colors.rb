require 'json'

file_path = 'doc/ui_architecture.excalidraw'
data = JSON.parse(File.read(file_path))

RESTORE_MAP = {
  "#93c5fd" => "#1e40af",
  "#bfdbfe" => "#3b82f6",
  "#cbd5e1" => "#64748b",
  "#fdba74" => "#c2410c",
  "#6ee7b7" => "#047857",
  "#fca5a5" => "#b91c1c",
  "#ffffff" => "#1e3a5f"
}

data['elements'].each do |el|
  if [ 'rectangle', 'ellipse', 'diamond' ].include?(el['type'])
    if RESTORE_MAP[el['strokeColor']]
      # 파란색 상자(백그라운드 #60a5fa)의 원래 테두리는 #1e3a5f 였습니다. 현재 #ffffff가 된 상태.
      # 페이로드 상자(백그라운드 #1e293b)의 원래 테두리는 #22c55e (초록) 이었는데, 컬러맵에 없어서 그대로일 것입니디.
      el['strokeColor'] = RESTORE_MAP[el['strokeColor']]
    end
  elsif el['type'] == 'text'
    if el['containerId']
      container = data['elements'].find { |e| e['id'] == el['containerId'] }
      if container
        case container['backgroundColor']
        when '#fed7aa'
          el['strokeColor'] = '#c2410c'
        when '#a7f3d0'
          el['strokeColor'] = '#047857'
        when '#60a5fa'
          el['strokeColor'] = '#ffffff'
        when '#fecaca'
          el['strokeColor'] = '#b91c1c'
        when '#1e293b'
          el['strokeColor'] = '#22c55e'
        end
      end
    end
  end
end

# Make sure all arrows are visible on dark background.
# Some arrows were #c2410c which might be hard to see, but my script changed them.
# Let's ensure the viewBackgroundColor is definitely set.
data['appState']['viewBackgroundColor'] = '#1e1e1e'
data['appState']['theme'] = 'dark'

File.write(file_path, JSON.pretty_generate(data))
