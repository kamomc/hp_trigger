# hp_trigger
ヘルスプラネット対応 TANITA 社製体組成計の IFTTT トリガー

## トリガー一覧
| トリガー名 | タイミング | value1 | value2 | value3 |
| --- | --- | --- | --- | --- |
| hp_update | 体重測定時 | 体重値 | 前回計測からの差分 | - |
| hp_rise | 体重増加時 | 体重値 | 前回計測からの差分 | - |
| hp_drop | 体重減少時 | 体重値 | 前回計測からの差分 | - |
| hp_stay | 体重減少時 | 体重値 | - | - |

# 使い方
## 事前準備
1. [Health Planet](https://www.healthplanet.jp/) にログインして Clieint ID と Client Secret を取得する。
2. [IFTTT](ifttt.com/) の Maker Channel を作成し、keyを取得する。

## 設定方法
### 1. hp_trigger.rb に Health Planet の Client ID と Client Secret, Maker Channel Key を設定
```
XHP::CLIENT_SECRET = '＊＊＊ここに貼り付け***' # Health Planet の Client ID
XHP::CLIENT_ID = '＊＊＊ここに貼り付け***' # Health Planet の Client Secret
MAKER_CHANNEL_KEY = '＊＊＊ここに貼り付け***' # IFTTT Maker Channel の Key
```

### 2. hp_trigger.rb を実行して、認証用URLを取得
```
$ ruby -v
ruby 2.3.3p222 (2016-11-21 revision 56859) [x86_64-linux]
$ bundle install
$ ruby hp_trigger_.rb 
"アクセストークンが無効です。以下のURLにアクセスしてリクエストコードを設定して下さい。"
"https://www.healthplanet.jp/oauth/auth?client_id=***********&redirect_uri=https://www.healthplanet.jp/success.html&scope=innerscan,sphygmomanometer,pedometer,smug&response_type=code"
```
ここで出力されたURLにWebブラウザに入力して認証を行う。

### 3. hp_trigger.rb にコードを設定
```
XHP_CODE = '＊＊＊ここに貼り付け***'
```

### 4. hp_trigger.rb を実行
```
$ bundle exec clockworkd -c hp_trigger.rb start --log
```
