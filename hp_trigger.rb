require 'xhp'
require 'clockwork'
include Clockwork

XHP::CLIENT_ID = '' # Health Planet の Client Secret
XHP::CLIENT_SECRET = '' # Health Planet の Client ID
MAKER_CHANNEL_KEY = '' # IFTTT Maker Channel の Key
XHP_CODE = ''

xhp = XHP::Client.new
begin
  token = xhp.token(XHP_CODE)
rescue
  p 'Health Planet の Client ID と Secret が正しく設定されていません。'
  exit(1)
end

if !token.access_token then
  p 'アクセストークンが無効です。以下のURLにアクセスしてリクエストコードを設定して下さい。'
  p xhp.get_auth_url
  exit(1)
end

prev_date = 0
prev_weight = 0

# 1分毎に体組成計データの更新を確認する
every(1.minutes, 'check') do
  # 最新の体組成計データを取得
  data = xhp.innerscan(token, '6021')['data']
  first_data = data[0]
  if first_data['date'] == prev_date then
    break
  end

  # 体重値と前回計測値との差分を計算
  weight = first_data['keydata']
  diff = weight.to_f - prev_weight.to_f

  # 各トリガーイベントを発砲
  if prev_weight != 0 then
    trigger_updated(weight, diff, get_graph_url(data))
    if diff > 0 then
      trigger_rises_above(weight, diff)
    elsif diff < 0 then
      trigger_drops_below(weight, diff)
    else
      trigger_stay(weight)
    end
  end

  prev_weight = weight
  prev_date = first_data['date']
end

# 体重更新トリガーを発動
def trigger_updated(weight, diff, graph_url)
  sign = diff > 0 ? "+" : diff < 0 ? "-" : "+-"
  trigger_event('hp_update',
                format("%.2f", weight),
                sign + format("%.2f", diff.abs.to_s),
                graph_url)
end

# 体重増加トリガーを発動
def trigger_rises_above(weight, diff)
  trigger_event('hp_rise', 
                format("%.2f", weight),
                format("%.2f", diff.abs))
end

# 体重減少トリガーを発動
def trigger_drops_below(weight, diff)
  trigger_event('hp_drop',
                format("%.2f", weight),
                format("%.2f", diff.abs))
end

# 体重変化なしトリガーを発動
def trigger_stay(weight)
  trigger_event('hp_stay', weight)
end

# Maker Channel Endpoint を叩く
def trigger_event(name, v1 = nil, v2 = nil, v3 = nil)
    Net::HTTP.post_form(URI.parse("https://maker.ifttt.com/trigger/#{name}/with/key/#{MAKER_CHANNEL_KEY}"), {
                       'value1' => v1,
                       'value2' => v2,
                       'value3' => v3})
end

def get_graph_url(data)
  values = ''
  prev = 0
  data.reverse_each do |d|
    w = d['keydata'].to_f
    if prev == 0 then
      prev = w
    else
      values << ','
    end
    values << format("%.2f", (w - prev) * 10 + 50)
    prev = w
  end
  "http://chart.apis.google.com/chart?chg=0,10,1,5&chs=650x200&chd=t:#{values}&cht=lc"
end
