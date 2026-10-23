# _data/timeline.yml 을 읽어 _includes/diagrams/timeline.svg 를 만든다.
# 실행: ruby tools/build_timeline.rb
#
# Liquid 로 SVG 좌표를 계산하는 대신 Ruby 로 한 번 생성해 커밋한다 —
# 데이터가 바뀌는 건 한 달에 한 번이고, 빌드 때마다 계산할 이유가 없다.

require "yaml"

ROOT = File.expand_path("..", __dir__)
DATA = YAML.safe_load_file(File.join(ROOT, "_data/timeline.yml"))

# 본문 폭이 650px 안팎이라 viewBox 1000 → 0.65배로 그려진다. 글자는 그걸 감안해 크게.
W      = 1000
MONTHS = 96                       # 2019-01 .. 2026-12
MW     = W.to_f / MONTHS
Y_AXIS, Y_SEG, Y_WORK, Y_EDU, Y_PERS = 24, 46, 104, 182, 262

def idx(ym)  = ((ym[0, 4].to_i - 2019) * 12) + ym[5, 2].to_i - 1
def x(ym)    = (idx(ym) * MW).round(1)
def x_end(ym) = ((idx(ym) + 1) * MW).round(1)
def esc(s)   = s.to_s.gsub("&", "&amp;").gsub("<", "&lt;").gsub('"', "&quot;")

out = []
out << %(<!-- tools/build_timeline.rb 가 _data/timeline.yml 에서 생성. 손으로 고치지 말 것. -->)
out << %(<div class="dg-wrap">)
out << %(<svg class="dg tl" viewBox="0 0 #{W} 340" role="img" aria-label="#{esc DATA["thesis"]} — 재직·교육 레인과 개인 프로젝트 레인을 같은 시간축에 놓은 타임라인.">)

# 연도 축
(2019..2026).each do |y|
  xx = x("#{y}-01")
  out << %(<line class="dg-rule" x1="#{xx}" y1="#{Y_AXIS + 6}" x2="#{xx}" y2="#{Y_PERS + 60}"/>)
  out << %(<text class="dg-axis" x="#{xx + 4}" y="#{Y_AXIS}">#{y}</text>)
end

# 구간 띠
DATA["segments"].each do |s|
  x0, x1 = x(s["from"]), x_end(s["to"])
  out << %(<rect class="tl-seg" x="#{x0}" y="#{Y_SEG}" width="#{(x1 - x0).round(1)}" height="30" rx="4"/>)
  out << %(<text class="tl-segtext" x="#{((x0 + x1) / 2).round(1)}" y="#{Y_SEG + 21}" text-anchor="middle">#{esc s["name"]}</text>)
end

# 레인 이름
out << %(<text class="dg-eyebrow" x="0" y="#{Y_WORK - 8}">재직 · 교육</text>)
out << %(<text class="dg-eyebrow" x="0" y="#{Y_PERS - 22}">개인 프로젝트</text>)

# 재직 막대
DATA["work"].each do |w|
  x0, x1 = x(w["from"]), x_end(w["to"])
  out << %(<a href="#{esc w["href"]}">)
  out << %(<rect class="tl-work" x="#{x0}" y="#{Y_WORK}" width="#{(x1 - x0).round(1)}" height="28" rx="3"/>)
  out << %(<text class="tl-label" x="#{x0}" y="#{Y_WORK + 48}">#{esc w["name"]}</text>)
  out << %(</a>)
end

# 교육 (월 미확인 → 연도 가운데에 마름모)
DATA["education"].each do |e|
  cx = x("#{e["year"]}-07")
  out << %(<path class="tl-edu" d="M#{cx} #{Y_EDU - 8} l8 8 l-8 8 l-8 -8 z"/>)
  out << %(<text class="tl-label tl-label--muted" x="#{cx + 14}" y="#{Y_EDU + 6}">#{esc e["name"]} #{e["year"]}</text>)
end

# 개인 프로젝트: 교육과 같은 마름모. 2026년에 몰려 있어 이름을 쓰면 겹친다 —
# 번호만 찍고 이름은 페이지의 목록이 맡는다. 가로로 가까운 표식은 아래 행으로 내린다.
rows = []                          # rows[r] = 그 행에 찍힌 cx 목록
DATA["artifacts"].each_with_index do |a, i|
  cx = (x(a["month"]) + MW / 2).round(1)
  r  = (0..).find { |k| (rows[k] ||= []).none? { |px| (px - cx).abs < 26 } }
  rows[r] << cx
  cy = Y_PERS + 28 * r
  out << %(<a href="#{esc a["href"]}">) if a["href"]
  out << %(<path class="tl-mark" d="M#{cx} #{cy - 12} l12 12 l-12 12 l-12 -12 z"><title>#{esc a["name"]}</title></path>)
  out << %(<text class="tl-dotnum" x="#{cx}" y="#{cy + 5}" text-anchor="middle">#{i + 1}</text>)
  out << %(</a>) if a["href"]
end

out << %(</svg>)
out << %(</div>)

path = File.join(ROOT, "_includes/diagrams/timeline.svg")
File.write(path, out.join("\n") + "\n", encoding: "UTF-8")
puts "wrote #{path} (#{out.size} lines)"
