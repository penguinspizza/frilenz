#include <M5Stack.h>
void initWifi(void);
void beep(void);
void M5btnAction(void);
void slice_str(String input, String outputArr[], int arrSize);
//int post_py_server(String json);
int post_py_server(String json, String server);

void RFID_required_process(void);
String NTag213_get_uid(byte *buf, byte bufSize);
void NTag213_auth(void);
void NTag213_write(String str);
void NTag213_read(String str);

#include <SPI.h>
#include <MFRC522.h>
#define RST_PIN   16
#define SDA_PIN   21
MFRC522 mfrc522(SDA_PIN, RST_PIN);
MFRC522::MIFARE_Key key;
MFRC522::StatusCode status;

#include <WiFi.h>
char *ssid = "aaaaaaaaa";
char *pass = "aaaaaaaaaa";
const IPAddress ip(1aaaaaaaaaa);
const IPAddress gateway(aaaaaaaaaa);
const IPAddress subnet(aaaaaaaaaa);
const String cam = "aaaaaaaaaa";
const String php = "aaaaaaaaaa";

#include <HTTPClient.h>
#define STRING_BOUNDARY "123456789000000000000987654321"
int responseCode = 0;

#include <ArduinoJson.h>
DynamicJsonDocument jsonDoc(384);  // JSONのサイズ指定
const int rfid_num = 3;     // RFIDの数
int read_cnt = 0;           // 読み込み回数
String card_uid[rfid_num];  // RFIDのuid格納用
String prev_uid = "";       // 前読み込んだRFIDのUID

String hash[rfid_num];      // ウォレットIDのHASH格納用

int write_cnt = 0;          // 書き込み回数
bool writing = false;       // 書き込み中かどうか
String RFID_NUMBER[] =      // 書き込み順
{
    "1111111111111111",
    "2222222222222222",
    "3333333333333333"
};

int check_cnt = 0;          // 照合回数
bool reading = false;       // データの読み込み中判断
String encodedString = "";  // ASCIIから文字列に直した後の文字列
String auth_hash[3];        // 読み取ったhash
String auth_number[3];      // 読み取った書き込み順

// 書き込み用データ(16バイト + 2バイト write_data + CRC)
// CRCはデータの整合性を検証するためのチェックサム
byte buffer[18];
byte size = sizeof(buffer);
uint8_t pageAddr = 0x06;     // Ultralightは16ページあり、1ページあたり4バイト

uint8_t buff[64*512] = {0};  // カメラの画像を受け取る用の領域
int img_payload = 0;         // post用に格納する画像領域
const int shot_button = 26;  // 撮影ボタン
bool currState = false;      // 今回のボタンの状態
bool prevState = false;      // 前回のボタンの状態
bool isPost = false;         // 写真をpostするか

#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#define SERVICE_UUID           "4FAFC201-1FB5-459E-8FCC-C5C9C331914B"
#define CHARACTERISTIC_UUID_RX "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"
#define CHARACTERISTIC_UUID_TX "BEB5483E-36E1-4688-B7F5-EA07361B26A8"

BLEServer *pServer = NULL;
BLECharacteristic * pTxCharacteristic;
bool deviceConnected = false;
bool oldDeviceConnected = false;
uint8_t txValue = 0;

String recv_str = "";     // BLEで送信されてきた文字列
const int str_num = 4;    // BLEで送信されてくる文字数
String tmp[rfid_num];     // BLEで送信されてきた文字列の格納用
bool RFID_READ = false;
bool isBuy = false;

class MyServerCallbacks: public BLEServerCallbacks 
{
    void onConnect(BLEServer* pServer) 
    {
        deviceConnected = true;
    };

    void onDisconnect(BLEServer* pServer) 
    {
        deviceConnected = false;
    }
};

class MyCallbacks: public BLECharacteristicCallbacks 
{
    void onWrite(BLECharacteristic *pCharacteristic) 
    {
        std::string rxValue = pCharacteristic->getValue();
        recv_str = "";
        if (rxValue.length() > 0) 
        {
            Serial.print("Received Value: ");
            for (int i = 0; i < rxValue.length(); i++)
            {
                recv_str = recv_str + rxValue[i];
            }
            Serial.println(recv_str);
            
            if (recv_str == "buy")
            {
                // 購入されたので、RFIDへの書き込みフラグON
                isBuy = true;
                if (write_cnt == 0)
                {
                    M5.Lcd.println("write for first human");
                }
                Serial.println(recv_str);

                // ログ消去
                M5.Lcd.setCursor(0, 0);
                M5.Lcd.clear(BLACK);
            }
            else
            {
                // 読み込みフラグとハッシュがコンマ付き文字列として送られてくる
                slice_str(recv_str, tmp, str_num);

                // BLEで送られてきた文字列を分解して表示
                for(int i = 0; i < str_num; i++)
                {
                    Serial.println(tmp[i]);
                    if (i == 0)
                    {
                        if (tmp[i] == "on")
                        {
                            RFID_READ = true;
                            M5.Lcd.setCursor(0, 0);
                            M5.Lcd.clear(BLACK);
                        }
                    }
                    else
                    {
                        hash[i -1] = tmp[i];
                        Serial.println(i - 1);
                        Serial.println(hash[i -1]);
                    }
                }
            }
        }
    }
};

void setup() 
{
    M5.begin();
    M5.Power.begin();
    M5.Speaker.setVolume(1);

    M5.Lcd.setRotation(3);
    M5.Lcd.clear(BLACK);
    M5.Lcd.setTextColor(WHITE);
    M5.Lcd.setTextSize(2);
    
    pinMode(shot_button, INPUT_PULLUP);

    Serial.begin(115200);
    while (!Serial);
    
    SPI.begin();
    mfrc522.PCD_Init();

    mfrc522.PCD_DumpVersionToSerial();
    Serial.println(F("Scan PICC to see UID, SAK, type, and data blocks..."));
    
    // Create the BLE Device
    BLEDevice::init("Fri+Lenz");
    // Create the BLE Server
    pServer = BLEDevice::createServer();
    pServer->setCallbacks(new MyServerCallbacks());
  
    // Create the BLE Service
    BLEService *pService = pServer->createService(SERVICE_UUID);
  
    // Create a BLE Characteristic
    pTxCharacteristic = pService->createCharacteristic(
                      CHARACTERISTIC_UUID_TX,
                      BLECharacteristic::PROPERTY_NOTIFY
                    );
                        
    pTxCharacteristic->addDescriptor(new BLE2902());
  
    BLECharacteristic * pRxCharacteristic = pService->createCharacteristic(
                         CHARACTERISTIC_UUID_RX,
                        BLECharacteristic::PROPERTY_WRITE
                      );
  
    pRxCharacteristic->setCallbacks(new MyCallbacks());
  
    // Start the service
    pService->start();
  
    // Start advertising
    pServer->getAdvertising()->start();
    Serial.println("Waiting a client connection to notify...");

    initWifi();
}

void loop() 
{
    M5.update();

    if (deviceConnected) 
    {
//        pTxCharacteristic->setValue(&txValue, 1);
//        pTxCharacteristic->notify();
//        txValue++;
//        delay(10); // bluetooth stack will go into congestion, if too many packets are sent
    }

    // 読み込みフラグがONのとき
    if (RFID_READ && !isBuy)
    {
        RFID_required_process();  // 読み込み前に必要な処理
        String read_uid = NTag213_get_uid(mfrc522.uid.uidByte, mfrc522.uid.size);   // RFIDのUID取得
        
        // 取得したUIDが前回取得したUIDと違ったら
        if (read_uid != prev_uid)
        {
            card_uid[read_cnt] = read_uid;   // UID保存
            M5.Lcd.print("Read:");  
            M5.Lcd.println(card_uid[read_cnt]);
            read_cnt++;
            Serial.println(read_uid);
        }
        prev_uid = read_uid;  // UID更新
        
        // RFIDを3枚読み込み終わったら
        if (read_cnt >= rfid_num)
        {
            RFID_READ = false;
            prev_uid = "";
            
            String json;
            // JSONオブジェクトを作成
            JsonArray jsonArray = jsonDoc.createNestedArray("0");
            for (int i = 0; i < read_cnt; i++)
            {
                JsonObject obj = jsonArray.createNestedObject();
                obj["id"] = card_uid[i];
            }    
            serializeJsonPretty(jsonDoc, Serial); // JSONデータを整形してシリアルモニタに表示
            serializeJson(jsonDoc, json);         // JSON ドキュメントを文字列にシリアライズ

            const String rfid = "rfid";
            int res = post_py_server(json, rfid);
            if (res == 200)
            {
                // 読み込み完了フラグ送信
                String msg = "ReadOff";
                pTxCharacteristic->setValue(msg.c_str());
                pTxCharacteristic->notify();
            }
            M5.Lcd.println("read complete");
        }
    }

    if (isBuy && !RFID_READ)
    {
        RFID_required_process();
        String read_uid = NTag213_get_uid(mfrc522.uid.uidByte, mfrc522.uid.size);   // RFIDのUID取得
        if (read_uid != prev_uid)
        {
            NTag213_auth();
            NTag213_write(read_uid);
            if (write_cnt >= 3)
            {
                isBuy = false;
                prev_uid = "";
                M5.Lcd.setCursor(0, 0);
                M5.Lcd.clear(BLACK);
                                
                String json;
                // JSONオブジェクトを作成
                JsonArray jsonArray = jsonDoc.createNestedArray("0");
                for (int i = 0; i < write_cnt; i++)
                {
                    JsonObject obj = jsonArray.createNestedObject();
                    obj["id"] = card_uid[i];
                    obj["hash"] = hash[i];
                    obj["num"] = RFID_NUMBER[i];
                    
                    Serial.println(card_uid[i]);
                    Serial.println(hash[i]);
                    Serial.println(RFID_NUMBER[i]);
                }    
                serializeJsonPretty(jsonDoc, Serial); // JSONデータを整形してシリアルモニタに表示
                serializeJson(jsonDoc, json);         // JSON ドキュメントを文字列にシリアライズ

                const String auth = "auth";
                int res = post_py_server(json, auth);
                if (res == 200)
                {
                    // 書き込み完了フラグ送信
                    String msg = "WriteOff";
                    pTxCharacteristic->setValue(msg.c_str());
                    pTxCharacteristic->notify();
                }
                M5.Lcd.println("read complete");
            }
        }
    }

    // 読み込みと書き込みが終わったら写真撮影とRFIDの読み込みを行う
    if (write_cnt >= 3 && read_cnt >= 3)
    {
        if (digitalRead(shot_button) == LOW)
        {
            currState = true;
        }
        else
        {
            currState = false;
        }

        // ボタンを押したら
        if (currState != prevState && currState)
        {
            Serial.println("push");
            if (currState)
            {
                String serverName = "http://" + cam; // カメラのIPアドレス

                HTTPClient http;
                http.begin(serverName);
        
                int httpCode = http.GET();          
                if (httpCode > 0) 
                { 
                    int len = http.getSize();
                    Serial.printf("[HTTP] size: %d\n", len);
                    if (len > 0) 
                    {
                        // 順次データを取得
                        WiFiClient * stream = http.getStreamPtr();
                        uint8_t* p = buff;
                        int l = len;
    
                        // 初期化
                        img_payload = 0;
                        while (http.connected() && (l > 0 || len == -1))  // 未読み込みの文字がなくなるまでデータの読み出しを繰り返す
                        {
                            // 読み取り可能なデータ数を返す
                            size_t size = stream->available();
                            if (size) 
                            {   
                                int s = ((size > sizeof(buff)) ? sizeof(buff) : size);
                                
                                // データの読み取り
                                int c = stream->readBytes(p, s);
                                p += c;
                                img_payload += c;
                                if (l > 0) 
                                {
                                    l -= c;
                                }
                            }
                        }
                        M5.Lcd.drawJpg(buff,sizeof(buff));
                    }
                }
                else 
                {
                    Serial.println(httpCode);
                }
                http.end();
            }
        }
        prevState = currState;
    
        M5btnAction();
        if (isPost)
        {
            String serverName = "http://" + php;

            HTTPClient http;
            http.begin(serverName);
      
            // HTTPRequestHeaderとアップロードするファイルの記述の境界を表している
            String stConType = "multipart/form-data; boundary=";
            stConType += STRING_BOUNDARY;
            http.addHeader("Content-Type", stConType);
      
            String stMHead ="--";
            stMHead += STRING_BOUNDARY;
            stMHead += "\r\n";
            stMHead += "Content-Disposition: form-data; name=\"uploadfile\"; filename=\"./caputre.jpg\" \r\n";  // POSTでフォームデータを送信するときに設定
            stMHead += "Content-Type: image/jpeg \r\n";                                                         // サーバにどのような種類のデータを送るのか
            stMHead += "\r\n";
            uint32_t iNumMHead = stMHead.length();
      
            String stMTail = "\r\n--";
            stMTail += STRING_BOUNDARY;
            stMTail += "--\r\n\r\n";
            uint32_t iNumMTail = stMTail.length();
    
            uint8_t* buf = buff;
            size_t len = img_payload;
      
            uint32_t iNumTotalLen = iNumMHead + iNumMTail + len;
            uint8_t *uiB = (uint8_t *)malloc(sizeof(uint8_t)*iNumTotalLen);
    
            for (int uilp=0; uilp < iNumMHead; uilp++) uiB[0+uilp] = stMHead[uilp];
            for (int uilp=0; uilp < len;       uilp++) uiB[iNumMHead + uilp] = buf[uilp];
            for (int uilp=0; uilp < iNumMTail; uilp++) uiB[iNumMHead + len + uilp] = stMTail[uilp];
            
            int32_t httpResponseCode = (int32_t)http.POST(uiB,iNumTotalLen);
            Serial.println(httpResponseCode);
            http.end();
            
            free(uiB);
    
            isPost = false;
        }

        RFID_required_process();
        String read_uid = NTag213_get_uid(mfrc522.uid.uidByte, mfrc522.uid.size);
        Serial.print("read_uid:");Serial.println(read_uid);
        if (read_uid != prev_uid)
        {
//            NTag213_auth();
            NTag213_read(read_uid);
    
            if (check_cnt >= 3)
            {
                M5.Lcd.println("read completed");
                
                String json;            
                JsonArray jsonArray = jsonDoc.createNestedArray("0");
                for (int i = 0; i < check_cnt; i++)
                {
                    JsonObject obj = jsonArray.createNestedObject();
                    obj["id"] = read_uid;
                    obj["hash"] = auth_hash[i];
                    obj["num"] = auth_number[i];

                    Serial.println(card_uid[i]);
                    Serial.println(hash[i]);
                    Serial.println(RFID_NUMBER[i]);
                }
                serializeJsonPretty(jsonDoc, Serial);
                serializeJson(jsonDoc, json);

                const String auth = "auth";
                int res = post_py_server(json, auth);
//                int res = post_py_server(json);
                if (res == 200)
                {
                    // 書き込み完了フラグ送信
                    String msg = "Check";
                    pTxCharacteristic->setValue(msg.c_str());
                    pTxCharacteristic->notify();
                }
            }
        }
    }
    
    // disconnecting
    if (!deviceConnected && oldDeviceConnected) 
    {
        delay(500); // give the bluetooth stack the chance to get things ready
        pServer->startAdvertising(); // restart advertising
        Serial.println("start advertising");
        oldDeviceConnected = deviceConnected;
    }
    
    // connecting
    if (deviceConnected && !oldDeviceConnected) 
    {
        // do stuff here on connecting
        oldDeviceConnected = deviceConnected;
    }
}
