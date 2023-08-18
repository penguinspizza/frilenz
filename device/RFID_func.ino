// 読み込み前に必要な処理
void RFID_required_process()
{
    // カードの確認（新しいカードが無ければ終了し、loop関数を繰り返す）
    if (!mfrc522.PICC_IsNewCardPresent()) 
    {
        return;
    }
  
    // カードのデータ読み込み（読み取れなければ終了し、loop関数を繰り返す）
    if (!mfrc522.PICC_ReadCardSerial()) 
    {
        return;
    }
}

// RFIDのUID取得
String NTag213_get_uid(byte *buf, byte bufSize)
{
    String str = "";
    for (byte i = 0; i < bufSize; i++) 
    {
       // 値が16未満の場合" 0"を追加し、違えばスペースを挿入して整列
       str.concat(String(buf[i] < 0x10 ? " 0" : " "));
       str.concat(String(buf[i], HEX));
    }
    str.toUpperCase();    // 小文字を大文字にする

    return str;
    
//    // 取得したUIDが前回取得したUIDと違ったら
//    if (str != prev_uid)
//    {
//        card_uid[read_cnt] = str;   // UID保存
//        M5.Lcd.print("Read:");  
//        M5.Lcd.println(card_uid[read_cnt]);
//        read_cnt++;
//        Serial.println(str);
//    }
//    prev_uid = str;  // UID更新
//    
//    // RFIDを3枚読み込み終わったら
//    if (read_cnt >= RFID_num)
//    {        
//        String json;
//        // JSONオブジェクトを作成
//        JsonArray jsonArray = jsonDoc.createNestedArray("0");
//        for (int i = 0; i < read_cnt; i++)
//        {
//            JsonObject obj = jsonArray.createNestedObject();
//            obj["id"] = card_uid[i];
//        }    
//        serializeJsonPretty(jsonDoc, Serial); // JSONデータを整形してシリアルモニタに表示
//        serializeJson(jsonDoc, json);         // JSON ドキュメントを文字列にシリアライズ
//        
//        post_py_server(json);
//        M5.Lcd.println("read complete");
//
//        read_cnt = 0;
//    }
}

void NTag213_auth()
{
    byte PSWBuff[] = {0xFF, 0xFF, 0xFF, 0xFF};  //32 bit password
    byte pACK[] = {0, 0};                       //16 bit PassWord ACK returned by the NFCtag
    
    // 認証開始
    status = mfrc522.PCD_NTAG216_AUTH(&PSWBuff[0], pACK);
    if(MFRC522::STATUS_OK !=status)
    {
         Serial.print(F("Authentication failed: "));
         return;
    }
    Serial.println(F("Authentication OK "));
}

void NTag213_write(String curr_uid)
{
    // 2回(hash, 書き込み順)書き込み
    for (int j = 0; j < 2; j++)
    {   
        if (j == 0)
        {
            pageAddr = 0x06;
            String str = hash[write_cnt];
            const char* hash = str.c_str();
            memcpy(buffer, hash, 16); 
        }
        else
        {
            pageAddr = 0x0A;
            String str = RFID_NUMBER[write_cnt];
            const char* number = str.c_str();
            memcpy(buffer, number, 16); 
        }
        
        for (int i = 0; i < 4; i++) 
        {
            // データ書き込み
            status = (MFRC522::StatusCode) mfrc522.MIFARE_Ultralight_Write(pageAddr+i, &buffer[i*4], 4);
            if (status != MFRC522::STATUS_OK) 
            {
                Serial.print(F("MIFARE_Ultralight_Write() failed: "));
                Serial.println(mfrc522.GetStatusCodeName(status));
                return;
            }
            else
            {
                writing = true;
            }
        }
        Serial.println(F("MIFARE_Ultralight_Write() OK ")); Serial.println();

        if (writing)
        {
            if (j == 0)
            {
                M5.Lcd.print("Writing ID...");
            }
            else
            {
                M5.Lcd.print("Writing Number...");
            }          
        }

        // 書き込んだデータ読み込み
        status = (MFRC522::StatusCode) mfrc522.MIFARE_Read(pageAddr, buffer, &size);
        if (status != MFRC522::STATUS_OK) 
        {
            Serial.print(F("MIFARE_Read() failed: "));
            Serial.println(mfrc522.GetStatusCodeName(status));
            mfrc522.PCD_Init();
            return;
        }
        else
        {
            M5.Lcd.println("sucess");

            // 最後まで書き込めたら
            if (j == 1)
            {
                writing = false;
                if (write_cnt == 0)
                {
                    M5.Lcd.println("write for first human");
                }
                else if (write_cnt == 1)
                {
                    M5.Lcd.println("write for second human");
                }
                else
                {
                    M5.Lcd.println("write for third human");
                }
                M5.Lcd.println();
                write_cnt++;
                prev_uid = curr_uid;  // 書き込みが成功したときのみ更新
            }        
        }

        // Dump a byte array to Serial
        Serial.print(F("Readed data: "));
        for (byte i = 0; i < 16; i++) 
        {
            Serial.write(buffer[i]);
        }
        Serial.println();
    }
}

void NTag213_read(String curr_uid)
{
    // 2回(hash, 書き込み順)読み込み
    for (int j = 0; j < 2; j++)
    {
        if (j == 0)
        {
            pageAddr = 0x06;
            if (!reading)
            {
                if (check_cnt == 0)
                {
                    M5.Lcd.println("read first human...");
                }
                else if (check_cnt == 1)
                {
                    M5.Lcd.println("read second human...");
                }
                else
                {
                    M5.Lcd.println("read third human...");
                }
            }
        }
        else
        {
            pageAddr = 0x0A;
        }

        // データ読み込み
        Serial.println(F("Reading data ... "));
        status = (MFRC522::StatusCode) mfrc522.MIFARE_Read(pageAddr, buffer, &size);
        if (status != MFRC522::STATUS_OK) 
        {
            Serial.print(F("MIFARE_Read() failed: "));
            Serial.println(mfrc522.GetStatusCodeName(status));
            mfrc522.PCD_Init();
            reading = true;
            return;
        }
        else
        {            
            String encodedString = "";
            byteArrayToHexString(buffer, size);
        
            // hash値(16進数文字列)が10進数の数値に対応するアスキーコード表現に変換されてるので元に戻す
            String decodedString = decode(encodedString);
            Serial.println(decodedString);
            
            if (j == 0)
            {
                auth_hash[check_cnt] = decodedString;
            }
            else
            {
                auth_number[check_cnt] = decodedString;
            }

            // 最後まで書き込めたら
            if (j == 1)
            {
                M5.Lcd.println("readed data");
                check_cnt++;
                prev_uid = curr_uid;  // 書き込みが成功したときのみ更新
                reading = false;
            }
        }
    }
}
