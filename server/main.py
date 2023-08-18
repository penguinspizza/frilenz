charset = 'utf-8'

import subprocess
import smtplib, ssl
from email.mime.text import MIMEText
from bottle import route, run, get, post, request
import hashlib
import pickle

# rfids = []
# rfids = ["01234567891234", "12345678912340", "23456789123401"]
# receivedDataFromDev = None
# receivedDataFromDev = [
#     {'rfid': '11111111111111', 'wadhash': 'xxxxxxxxxxxxxxxx'},
#     {'rfid': '22222222222222', 'wadhash': 'yyyyyyyyyyyyyyyy'},
#     {'rfid': '33333333333333', 'wadhash': 'zzzzzzzzzzzzzzzz'}
# ]

def main():
    run(host="0.0.0.0", port=2222)

# デバイスからRFIDの受け取り(NFT作成時)
@post("/rfid")
def route():
    # application/jsonが指定されているとき、dictを返す
    data = request.json
    print(data)
    rfids = []
    for i in range(len(data['0'])):
        rfids.append(data['0'][i]['id'].replace(' ', ''))
    
    # テスト用
    # rfids = []
    # rfids = ["x8xxxxxxxxxxxx", "y8yyyyyyyyyyyy", "z8zzzzzzzzzzzz"]
    # print(rfids)

    with open('rfids.pkl', 'wb') as file:
        pickle.dump(rfids, file)

# アプリからフォームデータの受け取り(NFT作成時)
@post("/")
def route():
    # application/jsonが指定されているとき、dictを返す
    mails = request.json.get('Mail')
    names = request.json.get('Name')
    wads = request.json.get('WAdress')
    rfid_hashs = []
    print(request.json)
    # print("global:", rfids)
    with open('rfids.pkl', 'rb') as file:
        rfids = pickle.load(file)
    print("file:", rfids)

    for i in range(len(wads)):
        rfid_hashs.append(hashlib.sha256(rfids[i].encode()).hexdigest()[:16])
    print("created hash")

    # 全ての人に購入リンクを送る
    for i in range(len(wads)):
        receiveDataAndSendMail(names[i], wads[i], mails[i], rfid_hashs[i])
    print("sended link")

    # NFTが全て購入されたかを判定する関数
    while (True):
        isOwnerCorrectList = []
        for i in range(len(wads)):
            isOwnerCorrectList.append(isOwnerCorrect(rfid_hashs[i], wads[i]))
        if (all(isOwnerCorrectList)):
            break

    print("while end")

    # フォルダのハッシュ値を作成してPHPに送る
    combinedRfid = ''.join(rfids)
    combinedRfid_hash = hashlib.sha256(combinedRfid.encode()).hexdigest()
    print(combinedRfid_hash)
    res = subprocess.run(["php", "fromPy.php", combinedRfid_hash], capture_output=True, text=True)
    print(res.stdout)
    _res = subprocess.run(["php", "recvJpg.php", combinedRfid_hash], capture_output=True, text=True)
    print(_res)



    toBCtFlag = "buy"
    return '%s' % toBCtFlag

# デバイスからRFIDとウォレットアドレスのハッシュ値と順番をもらう(照合時)
@post("/auth")
def route():
    # application/jsonが指定されているとき、dictを返す
    # データ例: {'0': [{'id': ' 04 B7 08 0A 6B 67 84', 'hash': '\x00b1556dea32e9d0cd', 'num': '\x001111111111111111'}, {'id': ' 04 23 93 72 6D 67 80', 'hash': '\x00b1556dea32e9d0cd', 'num': '\x001111111111111111'}, {'id': ' 04 B7 08 0A 6B 67 84', 'hash': '\x00b1556dea32e9d0cd', 'num': '\x001111111111111111'}]}
    data = request.json
    print(data)
    receivedDataFromDev = None

    # 本番用
    sorted_data = sorted(data['0'], key=lambda x: int(x['num'][-1:]))
    receivedDataFromDev = [{'rfid': d['id'].replace(' ', ''), 'wadhash': d['hash'][1:]} for d in sorted_data]
    print(receivedDataFromDev)

    # テスト用
    # receivedDataFromDev[0]['rfid'] = 'xxxxxxxxxxxxxx'
    # receivedDataFromDev[1]['rfid'] = 'yyyyyyyyyyyyyy'
    # receivedDataFromDev[2]['rfid'] = 'zzzzzzzzzzzzzz'
    # receivedDataFromDev = [
    #     {'rfid': 'x8xxxxxxxxxxxx', 'wadhash': hashlib.sha256('0xA7396B1CDFC4A2e6caBAa14Bb1C209A61e5d06Cf'.encode()).hexdigest()[:16]},
    #     {'rfid': 'y8yyyyyyyyyyyy', 'wadhash': hashlib.sha256('0xA7396B1CDFC4A2e6caBAa14Bb1C209A61e5d06Cf'.encode()).hexdigest()[:16]},
    #     {'rfid': 'z8zzzzzzzzzzzz', 'wadhash': hashlib.sha256('0xA7396B1CDFC4A2e6caBAa14Bb1C209A61e5d06Cf'.encode()).hexdigest()[:16]}
    # ]

    print(receivedDataFromDev)

    with open('receivedDataFromDev.pkl', 'wb') as file:
        pickle.dump(receivedDataFromDev, file)

    toBCtFlag = "auth"
    return '%s' % toBCtFlag

# NFT上を参照して照合し、一致していればハッシュ値を渡す(照合時)
@post("/hash")
def route():
    # application/jsonが指定されているとき、dictを返す
    print(request.json)

    # 参照して判定してハッシュ返す
    isOwnerRightfulList = []

    with open('receivedDataFromDev.pkl', 'rb') as file:
        receivedDataFromDev = pickle.load(file)

    for e in receivedDataFromDev:
        print(e['rfid'], e['wadhash'])

        rfid_hash = hashlib.sha256(e['rfid'].encode()).hexdigest()[:16]
        wad = getOwnerByMetadata(rfid_hash)
        wadhash = hashlib.sha256(wad.encode()).hexdigest()[:16]
        # wadhash = e['wadhash'] # テスト用

        if (e['wadhash'] == wadhash):
            isOwnerRightfulList.append(True)
        else:
            isOwnerRightfulList.append(False)

    if (all(isOwnerRightfulList)):
        combinedRfid = ''.join(item['rfid'] for item in receivedDataFromDev)
        combinedRfid_hash = hashlib.sha256(combinedRfid.encode()).hexdigest()
        print(combinedRfid_hash)
        return '%s' % combinedRfid_hash
    else:
        toBCtFlag = "Error"
        print(toBCtFlag)
        return '%s' % toBCtFlag 

# NFTを作成し、購入リンクメールを送信する関数
# 引数: 名前, ウォレットアドレス, 送信先メールアドレス
# 戻り値: 無し
def receiveDataAndSendMail(name, walletAddress, email_address, rfid_hash):
    nfts_name = f"{name}\'s keyholder"
    description = f"This is the NFT of {name}\'s keyholder."
    buyLink = createBuyLink(nfts_name, description, rfid_hash, walletAddress)
    send_email(name, email_address, buyLink)

# NFTの所有者を判定する関数
# 引数: RFIDのハッシュ値, ウォレットアドレス
# 戻り値: 所有者が合っていた場合 true, 所有者が異なる場合 false
def isOwnerCorrect(rfid_hash, walletAddress):
    owner = getOwnerByMetadata(rfid_hash)
    if (owner == walletAddress):
        return True
    else:
        return False

# NFTの作成から購入リンクの作成までを行う関数
# 引数: NFTの名前, NFTの説明, RFIDのハッシュ値(16文字), ウォレットアドレス
# 戻り値: 購入リンク
def createBuyLink(name, description, rfid_hash, walletAddress):
    res = subprocess.run(["node", "index.js", "createBuyLink", name, description, rfid_hash, walletAddress], capture_output=True, text=True)
    # if (res.returncode == 0):
    #     return res.stdout
    # else:
    #     return None
    return res.stdout

# 特定のRFIDハッシュ値の所有者のウォレットアドレスを返す関数
# 引数: RFIDハッシュ値(16文字)
# 戻り値: 所有者のウォレットアドレス
def getOwnerByMetadata(rfid_hash):
    res = subprocess.run(["node", "index.js", "getOwnerByMetadata", rfid_hash], capture_output=True, text=True)
    if (res.returncode == 0):
        return res.stdout
    else:
        return None

# メールを送信する関数
# 引数: 名前, 送信先メールアドレス, 購入リンク
# 戻り値: 無し
def send_email(name, email_address, link):

    # メールの送信先
    mail_to = email_address

    # メールの送信元のGmail設定
    mail_from = "chicks.hackathon@gmail.com"
    app_password = "pqbiaeghyxyfwbca"

    # メールデータ(MIME)の作成
    subject = "キーホルダーのNFT購入リンクの送付"
    body = f"{name} 様\n\nこんにちは！\nchicks.hackathon公式です。\n\n以下のリンクからキーホルダーのNFTを購入してください。\n\n{link}"

    msg = MIMEText(body, "plain", charset)

    msg["Subject"] = subject
    msg["To"] = mail_to
    msg["From"] = mail_from

    # GmailにSSL接続
    server = smtplib.SMTP_SSL("smtp.gmail.com", 465, context=ssl.create_default_context())
    server.login(mail_from, app_password)

    # メールの送信
    server.send_message(msg)

if __name__ == "__main__":
    main()