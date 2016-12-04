require 'xhp'
require 'clockwork'
include Clockwork

XHP::CLIENT_SECRET = '' # Health Planet の Client ID
XHP::CLIENT_ID = '' # Health Planet の Client Secret
MAKER_CHANNEL_KEY = '' # IFTTT Maker Channel の Key

xhp = XHP::Client.new

p '以下のURLにアクセスしてリクエストコードを入力して下さい。'
p xhp.get_auth_url

code = gets
token = xhp.token(code)

prev_date = 0
prev_weight = 0

# 1分毎に体組成計データの更新を確認する
every(1.minutes, 'check') do
  # 最新の体組成計データを取得
  data = xhp.innerscan(token, '6021')['data'][0]
  if data['date'] == prev_date then
    break
  end

  # 体重値と前回計測値との差分を計算
  weight = data['keydata']
  diff = weight.to_f - prev_weight.to_f

  # 各トリガーイベントを発砲
  if prev_weight != 0 then
    trigger_updated(weight, diff)
    if diff > 0 then
      trigger_rises_above(weight, diff)
    elsif diff < 0 then
      trigger_drops_below(weight, diff)
    else
      trigger_stay(weight)
    end
  end

  prev_weight = weight
  prev_date = data['date']
end

# 体重更新トリガーを発動
def trigger_updated(weight, diff)
  sign = diff > 0 ? "+" : diff < 0 ? "-" : "+-"
  trigger_event('hp_update',
                format("%.2f", weight),
                sign + format("%.2f", diff.abs.to_s))
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
