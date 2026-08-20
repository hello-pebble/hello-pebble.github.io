# 이력서·경력기술서·포트폴리오에 흩어진 사실이 어긋나는지 검사한다.
# 실행: ruby tools/check_facts.rb
#
# 문서를 한 곳에서 생성하도록 바꾸는 대신 검사만 둔 이유 —
# 중복되는 것은 대부분 산문이라 템플릿으로 뽑을 수 없고, 실제로 어긋나는 것은
# 기간과 개수뿐이다. 그 둘만 검사하면 드리프트는 잡힌다.

ROOT = File.expand_path("..", __dir__)
def read(path) = File.read(File.join(ROOT, path), encoding: "UTF-8")

errors = []

# 1. 재직 기간은 이력서와 경력기술서에 같은 문자열로 나와야 한다.
RESUME = read("resume/resume.md")
CAREER = read("resume/career-description.md")

# 표는 연 단위로 요약하고(월 단위 공백이 표에 드러나지 않게), 정확한 월은 상세 항목에 남긴다.
{
  "사람과숲"   => "2022 ~ 2025",
  "에이아이넷" => "2020 ~ 2021",
  "엘에프아이티" => "2019 ~ 2020",
}.each do |company, period|
  # 경력기술서 표는 기간에 `~` 앞뒤 공백이 없는 형식도 쓴다
  variants = [period, period.delete(" ")]
  [["resume.md", RESUME], ["career-description.md", CAREER]].each do |name, body|
    next if variants.any? { |v| body.include?(v) }
    errors << "#{name}: #{company} 재직 기간 '#{period}' 이 없다 (다른 문서와 어긋남)"
  end
end

# 2. 포트폴리오 섹션의 표시 개수와 실제 카드 수가 같아야 한다.
INDEX = read("portfolio/index.md")
INDEX.split(/<section /).each do |section|
  next unless (label = section[/<h2 id="([^"]+)"/, 1])
  next unless (declared = section[/portfolio-count">(\d+) projects/, 1])
  actual = section.scan(/class="portfolio-card"/).size
  next if declared.to_i == actual
  errors << "portfolio/index.md: #{label} 섹션이 #{declared}개라고 적혀 있으나 카드는 #{actual}개다"
end

# 3. 제출본이 아닌 원고는 빌드에서 제외돼 있어야 한다.
DRAFT = "resume/career-description-variants.md"
unless read("_config.yml").include?(DRAFT)
  errors << "_config.yml: #{DRAFT} 가 exclude 에 없다 — 공개 URL이 생성된다"
end
if Dir.exist?(File.join(ROOT, "_site")) &&
   !Dir.glob(File.join(ROOT, "_site/resume/career-description-variants.*")).empty?
  errors << "_site: 제외 설정 후 재빌드가 필요하다 (초안이 아직 남아 있다)"
end

if errors.empty?
  puts "OK — 기간·개수·초안 노출 이상 없음"
else
  errors.each { |e| puts "FAIL  #{e}" }
  exit 1
end
