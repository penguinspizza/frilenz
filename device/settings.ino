void initWifi()
{
// WiFi stuff (no timeout setting for WiFi)
#ifdef ESP_PLATFORM
    WiFi.disconnect(true, true); // disable wifi, erase ap info
    delay(1000);
    //WiFi.mode(WIFI_STA);
    WiFi.mode(WIFI_AP);
#endif
    WiFi.begin(ssid, pass);
    WiFi.config(ip, gateway, subnet);
    while (WiFi.status() != WL_CONNECTED) { Serial.print("."); delay(500); }
    Serial.print("WiFi connected, IP = "); Serial.println(WiFi.localIP());
    M5.Lcd.print("WiFi connected"); M5.Lcd.println(WiFi.localIP());
}

void slice_str(String input, String outputArr[], int arrSize) 
{
    int index = 0;      // 配列のインデックスを初期化
    int startPos = 0;   // 分割の開始位置を初期化
    int commaPos;       // カンマの位置を格納する変数

    // カンマで分割しながらトークンを格納
    while ((commaPos = input.indexOf(",", startPos)) != -1 && index < arrSize) 
    {
        // カンマまでの文字列を抽出してトークンとして格納
        outputArr[index] = input.substring(startPos, commaPos);
        startPos = commaPos + 1;    // 次の開始位置を設定
        index++;                    // 配列のインデックスをインクリメント
    }

    // 最後のトークンを格納
    if (index < arrSize) 
    {
        outputArr[index] = input.substring(startPos);
    }
}

int post_py_server(String json, String server)
{
    String serverName = "aaaaaaaaa" + server;
    HTTPClient http;
    http.begin(serverName);
    
    http.addHeader("Content-Type", "application/json");
    responseCode = http.POST(json);
    Serial.println(responseCode);
//    if (responseCode == 200)
//    {
//        M5.Lcd.println("RFID data send");
//    }
//    else
//    {
//        M5.Lcd.print("RFID data send error");Serial.println(responseCode);
//    }
    
    String body = http.getString();
    Serial.println(body);
    
    http.end();
    return responseCode;
}

// 押したかどうか分かりにくいから音を鳴らす
void beep(void)
{
    M5.Speaker.beep();
    delay(50);        
    M5.Speaker.mute();
}

void M5btnAction(void)
{
    if (M5.BtnA.wasPressed()) 
    { 
        beep();
        if (!isPost)
        {
            isPost = true; 
        }
    }
    
    if (M5.BtnB.wasPressed()) 
    { 
        beep();
    }
        
    if (M5.BtnC.wasPressed()) 
    { 
        beep();
    }
}

// バイト配列を16進数の文字列に変換
void byteArrayToHexString(byte *buffer, byte bufferSize) 
{
    for (byte i = 0; i < bufferSize-2; i++) 
    {          
        encodedString.concat(String(buffer[i] < 0x10 ? " 0" : " "));
        encodedString.concat(String(buffer[i], HEX));
    }
    encodedString += " ";   // 最後までdecodeするために空白挿入
    Serial.println(encodedString);
}

// エンコードされた文字列をデコードする関数
String decode(String encoded) 
{
    String decoded = "";
  
    // エンコードされた文字列が残っている間ループ
    while (encoded.length() > 0) 
    {      
        // スペースの位置を検索
        int spaceIndex = encoded.indexOf(" ");
        if (spaceIndex != -1) 
        {
            String hexByte = encoded.substring(0, spaceIndex);  // スペースまでの部分を取得
            encoded = encoded.substring(spaceIndex + 1);        // スペース以降の部分を新しいエンコード文字列として更新
  
            // strtol 文字列をlong型の数値に変換する関数
            // NULL文字以外の16進数文字を10進数に変換してアスキーコードに対応させる
            // NULL文字以外の場合のみ処理
            if (hexByte != "00") 
            {
                int decimalValue = strtol(hexByte.c_str(), NULL, 16);   // 16進数文字列を10進数に変換
                char decodedChar = (char)decimalValue;                  // 10進数値をアスキーコードに変換
                decoded += decodedChar;                                 // デコードされた文字を結果文字列に追加
            }
        }
        else 
        {
            break;
        }
    }
    return decoded;
}
