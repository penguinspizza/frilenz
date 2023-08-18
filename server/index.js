import { config } from "dotenv";
import { ThirdwebSDK } from "@thirdweb-dev/sdk";
import { readFileSync } from "fs";
import { Astar } from "@thirdweb-dev/chains";

// チェーンを設定
// const chain = "mumbai";
const chain = "Astar";


// NFT Collectionのコントラクトアドレス
// munbai
// const contractAddress_nfcol = "0x450F4f65027b5F5826A25c05d3391D7B4c2DF209";

// Astar
const contractAddress_nfcol = "0xA1d1e0565bd418843B783dBAA7AB9Aa41A617784";

// Marketplaceのコントラクトアドレス
// munbai
// const contractAddress_mkp = "0x797a982dAAD09408f1A95D37AadBd881d639Cfd6";

// Astar
const contractAddress_mkp = "0x1d274F7058a419E96245f979d72cFcBc3e103f4b";

// !!!!!!!!!!購入リンクテンプレートの切り替えは下の方にある!!!!!!!!!!

config();


// コマンドライン引数の仕様
// 1つ目: 実行する関数の種類の指定("createBuyLink" または "getOwnerByMetadata")

// ====1つ目が"createBuyLink"の時====
// 2つ目: 作成するNFTの名前
// 3つ目: 作成するNFTの説明
// 4つ目: 登録するRFIDのハッシュ値(16文字)
// 5つ目: 購入を許可するウォレットアドレス

// ====1つ目が"getOwnerByMetadata"の時====
// 2つ目: RFIDハッシュ値(16文字)


// コマンドの標準出力の仕様
// ====1つ目が"createBuyLink"の時====
// 購入リンク

// ====1つ目が"getOwnerByMetadata"の時====
// 所有者のウォレットアドレス


const args = process.argv.slice(2);

// sdkオブジェクト生成
const sdk = ThirdwebSDK.fromPrivateKey(
  process.env.PRIVATE_KEY,
  chain,
  {
    secretKey: process.env.SECRET_KEY,
  }
);

// NFT Collectionのコントラクトオブジェクト生成
const contract_nfcol = await sdk.getContract(contractAddress_nfcol);

// Marketplaceのコントラクトオブジェクト生成
const contract_mkp = await sdk.getContract(contractAddress_mkp);

// メイン関数
const main = async () => {
  if (args[0] === "createBuyLink") {
    const res = await createBuyLink(args[1], args[2], args[3], args[4]);
    process.stdout.write(res);
  } else if (args[0] === "getOwnerByMetadata") {
    const res = await getOwnerByMetadata(args[1]);
    process.stdout.write(res);
  } else {
    process.stdout.write("argvError");
  }
};

// ミントする関数
// 引数: 名前, 説明, RFIDのハッシュ値(16文字)
// 戻り値: NFT CollectionコントラクトでのトークンID(10進数文字列)
const mint = async (name, description, rfid_hash) => {
  // Custom metadata of the NFT, note that you can fully customize this metadata with other properties.
  const metadata = {
    name: name,
    description: description,
    image: "https://pbs.twimg.com/media/F30TJ1HaYAAEfwc?format=jpg&name=900x900",
    external_url: "https://pbs.twimg.com/media/F30TJ1HaYAAEfwc?format=jpg&name=900x900",
    background_color: "FFF",
    attributes: [
      {
        trait_type: 'rfid_hash',
        value: rfid_hash
      }
    ],
    customImage: "https://pbs.twimg.com/media/F30TJ1HaYAAEfwc?format=jpg&name=900x900"
    // ... Any other metadata you want to include
  };

  const txResult = await contract_nfcol.erc721.mint(metadata);

  return parseInt(txResult.id._hex, 16).toString();
}

// マーケットに登録する関数
// 引数: NFT CollectionコントラクトでのトークンID(10進数文字列)
// 戻り値: MarketplaceコントラクトでのトークンID(10進数文字列)
const directListing = async (nftcolsId) => {
  const txResult = await contract_mkp.directListings.createListing({
    assetContractAddress: contractAddress_nfcol, // Required - smart contract address of NFT to sell
    // assetContractAddress: "0xA1d1e0565bd418843B783dBAA7AB9Aa41A617784", // Required - smart contract address of NFT to sell
    tokenId: nftcolsId, // Required - token ID of the NFT to sell
    pricePerToken: "0.0000000000001", // Required - price of each token in the listing
    // currencyContractAddress: "{{currency_contract_address}}", // Optional - smart contract address of the currency to use for the listing
    isReservedListing: true, // Optional - whether or not the listing is reserved (only specific wallet addresses can buy)
    quantity: "1", // Optional - number of tokens to sell (1 for ERC721 NFTs)
    startTimestamp: new Date(), // Optional - when the listing should start (default is now)
    endTimestamp: new Date(new Date().getTime() + 7 * 24 * 60 * 60 * 1000), // Optional - when the listing should end (default is 7 days from now)
  });

  return parseInt(txResult.id._hex, 16).toString();
}

// 特定のリスト内アイテムに対して特定のウォレットアドレスでのみ購入できるように設定する関数
// 引数: MarketplaceコントラクトでのトークンID(10進数文字列), ウォレットアドレス
const approveBuyer = async (mkpsId, walletAddress) => {
  const txResult = await contract_mkp.directListings.approveBuyerForReservedListing(
    mkpsId, // マーケットプレイス内でのトークンID（NFT CollectionのトークンIDでは無い）
    walletAddress, // ウォレットアドレス
  );
}

// NFTの作成から購入リンクの作成までを行う関数
// 引数: NFTの名前, NFTの説明, RFIDのハッシュ値(16文字), ウォレットアドレス
// 戻り値: 購入リンク
const createBuyLink = async (name, description, rfid_hash, walletAddress) => {
  const nftcolsId = await mint(name, description, rfid_hash);
  const mkpsId = await directListing(nftcolsId);
  await approveBuyer(mkpsId, walletAddress);

  // munbai
  // const buyLink = `https://embed.ipfscdn.io/ipfs/bafybeigtqeyfmqkfbdu7ubjlwhtqkdqckvee7waks4uwhmzdfvpfaqzdwm/marketplace-v3.html?contract=0x797a982dAAD09408f1A95D37AadBd881d639Cfd6&chain=%7B%22name%22%3A%22Mumbai%22%2C%22chain%22%3A%22Polygon%22%2C%22rpc%22%3A%5B%22https%3A%2F%2Fmumbai.rpc.thirdweb.com%2F%24%7BTHIRDWEB_API_KEY%7D%22%5D%2C%22nativeCurrency%22%3A%7B%22name%22%3A%22MATIC%22%2C%22symbol%22%3A%22MATIC%22%2C%22decimals%22%3A18%7D%2C%22shortName%22%3A%22maticmum%22%2C%22chainId%22%3A80001%2C%22testnet%22%3Atrue%2C%22slug%22%3A%22mumbai%22%2C%22icon%22%3A%7B%22url%22%3A%22ipfs%3A%2F%2FQmcxZHpyJa8T4i63xqjPYrZ6tKrt55tZJpbXcjSDKuKaf9%2Fpolygon%2F512.png%22%2C%22height%22%3A512%2C%22width%22%3A512%2C%22format%22%3A%22png%22%7D%7D&clientId=b00e9aab52873d293d83ad17f93fc0ec&directListingId=${mkpsId}&primaryColor=purple`;

  // Astar
  const buyLink = `https://embed.ipfscdn.io/ipfs/bafybeigtqeyfmqkfbdu7ubjlwhtqkdqckvee7waks4uwhmzdfvpfaqzdwm/marketplace-v3.html?contract=0x1d274F7058a419E96245f979d72cFcBc3e103f4b&chain=%7B%22name%22%3A%22Astar%22%2C%22chain%22%3A%22ASTR%22%2C%22rpc%22%3A%5B%22https%3A%2F%2Fastar.rpc.thirdweb.com%2F%24%7BTHIRDWEB_API_KEY%7D%22%5D%2C%22nativeCurrency%22%3A%7B%22name%22%3A%22Astar%22%2C%22symbol%22%3A%22ASTR%22%2C%22decimals%22%3A18%7D%2C%22shortName%22%3A%22astr%22%2C%22chainId%22%3A592%2C%22testnet%22%3Afalse%2C%22slug%22%3A%22astar%22%2C%22icon%22%3A%7B%22url%22%3A%22ipfs%3A%2F%2FQmdvmx3p6gXBCLUMU1qivscaTNkT6h3URdhUTZCHLwKudg%22%2C%22width%22%3A1000%2C%22height%22%3A1000%2C%22format%22%3A%22png%22%7D%7D&clientId=b00e9aab52873d293d83ad17f93fc0ec&directListingId=${mkpsId}&primaryColor=purple`;
  return buyLink;
}


// 特定のRFIDハッシュ値の所有者のウォレットアドレスを返す関数
// 引数: RFIDハッシュ値(16文字)
// 戻り値: 所有者のウォレットアドレス
const getOwnerByMetadata = async (rfid_hash) => {
  const count = 100;
  let n = 0;
  
  while (true) {
    try {
      const queryParams = {
        // The number of NFTs to return
        count: count, // Default is 100
        // The index to start from
        start: n, // Default is 0
      };
      
      const nfts = await contract_nfcol.erc721.getAll(queryParams);
  
      for (let i = 0; i < nfts.length; i++) {
        try {
          if (nfts[i].metadata.attributes[0].value === rfid_hash) {
            return nfts[i].owner
          }
        } catch (TypeError) {
          ;
        }
      }
  
      n = n + count;
    } catch (RangeError) {
      break;
    }
  }
}

main();
