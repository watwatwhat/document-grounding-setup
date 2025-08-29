# SAP Joule Document Grounding Setup Script

このスクリプトは、SAP Jouleのドキュメントグラウンディング機能のユーザー認証設定を自動化するためのものです。macOS向けに設計されています。

## 概要

SAP Jouleのドキュメントグラウンディング機能を使用するには、以下の手順が必要です：

1. Document Groundingインスタンスの作成
2. Cloud Identity Servicesインスタンスの作成
3. 証明書ファイルの作成
4. アクセストークンの取得
5. エンドポイントのテスト

このスクリプトは、これらの手順を対話的に実行し、設定情報をプロパティファイルに保存します。

## 作成されたファイル

1. **`main.sh`** - メインのシェルスクリプト
2. **`template/joule_config.properties.template`** - 設定ファイルのテンプレート
3. **`README.md`** - 詳細な使用方法とセットアップ手順

## 前提条件

- macOS
- `curl` コマンドが利用可能
- `sed` コマンドが利用可能
- SAP BTPアカウントとJouleのサブスクリプション

## インストール

1. スクリプトファイルをダウンロードまたは作成
2. 実行権限を付与：

```bash
chmod +x main.sh
```

## 使用方法

### 基本的な使用方法

```bash
./main.sh
```

### メニューオプション

スクリプトを実行すると、以下のメニューが表示されます：

1. **Create Document Grounding Instance** - Document Groundingインスタンスの作成
2. **Create Cloud Identity Services Instance** - Cloud Identity Servicesインスタンスの作成
3. **Create Certificate Files** - 証明書ファイルの作成
4. **Get Access Token** - アクセストークンの取得
5. **Test Document Grounding Endpoints** - エンドポイントのテスト
6. **Configure WorkZone Integration** - WorkZone統合の設定
7. **Create WorkZone Pipeline** - WorkZoneパイプラインの作成
8. **Show Configuration Summary** - 設定の概要表示
9. **Load/Save Configuration** - 設定の読み込み/保存
10. **Exit** - 終了

### 設定ファイル

スクリプトは `joule_config.properties` ファイルに設定情報を保存します。このファイルは自動的に作成され、セキュリティのため600権限が設定されます。

## 詳細な手順

### 1. Document Groundingインスタンスの作成

SAP BTP Cockpitで以下の手順を実行：

1. Services > Service Marketplaceに移動
2. "document grounding"を検索してタイルを選択
3. Createを選択
4. Runtime Environmentとして"Other"を選択
5. インスタンス名を入力
6. Createを選択
7. View Instanceを選択
8. インスタンスを選択してサービスバインディングを作成
9. サービスバインディング名を入力
10. Createを選択
11. サービスバインディングURLをコピー

### 2. Cloud Identity Servicesインスタンスの作成

1. Services > Service Marketplaceに移動
2. "Cloud Identity Services"を検索してタイルを選択
3. Createを選択
4. Planとして"application"、Runtime Environmentとして"Other"を選択
5. インスタンス名を入力
6. Nextを選択
7. Parametersで以下のJSONを入力：

```json
{
  "consumed-services": [
    {
      "service-instance-name": "<doc-grounding-instance-name>"
    }
  ]
}
```

8. Createを選択
9. View Instanceを選択
10. インスタンスを選択してサービスバインディングを作成
11. サービスバインディング名を入力
12. 以下のパラメータを入力：

```json
{
  "credential-type": "X509_GENERATED",
  "validity": 365,
  "validity-type": "DAYS"
}
```

13. Createを選択
14. "clientid"と"authorization_endpoint"の値をコピー

### 3. 証明書ファイルの作成

サービスバインディングから証明書とキーの値を取得し、スクリプトでファイルを作成します。スクリプトは自動的に`\n`文字を実際の改行に変換します。

### 4. アクセストークンの取得

証明書ファイルを使用してOAuth2クライアントクレデンシャルフローでアクセストークンを取得します。

### 5. エンドポイントのテスト

取得したトークンを使用してDocument Groundingのエンドポイントをテストします。

### 6. WorkZone統合の設定

SAP Build Work ZoneとDocument Groundingの統合を設定します。以下の手順が必要です：

#### Step 1: WorkZone Admin ConsoleでのOAuth Client作成
1. Admin Console > External Integrations > OAuth Clientsに移動
2. "Add OAuth Client"をクリック
3. 名前: "Document Grounding OAuth Client"（または任意の意味のある名前）
4. Integration URL: "https://www.yoururl.com"（任意の有効なURL形式）
5. 作成後、KeyとSecretの値を記録

#### Step 2: Document Grounding機能の有効化
1. Admin Console > Feature Enablement > Featuresに移動
2. Feature Managementセクションで"Enable document grounding integration"を有効化
3. Step 1で作成したOAuth clientを選択
4. 変更を保存

#### Step 3: BTP CockpitでのDestination作成
1. Connectivity > Destinationsに移動
2. 新しいdestinationを作成（詳細はスクリプト内で表示）
3. 追加プロパティの設定

### 7. WorkZoneパイプラインの作成

SAP AI CoreのWorkZoneパイプラインを作成します。以下の情報が必要です：

- **AI Resource Group**: アカウントに割り当てられたAIリソースグループ
- **Generic Secret Name**: Step 6で設定したDestination名が自動的に使用される

パイプライン作成後、パイプラインIDが自動的に設定ファイルに保存されます。

## セキュリティに関する注意事項

- 証明書ファイルは600権限で作成され、所有者のみが読み書き可能
- 設定ファイルも600権限で作成
- 証明書とキーの値は安全に管理してください

## トラブルシューティング

### よくある問題

1. **証明書ファイルが見つからない**
   - 証明書ファイルの作成ステップを先に実行してください

2. **アクセストークンの取得に失敗**
   - 証明書ファイルが正しく作成されているか確認
   - clientidとauthorization_endpointの値が正しいか確認

3. **エンドポイントのテストに失敗**
   - アクセストークンが正しく取得されているか確認
   - サービスバインディングURLが正しいか確認

### ログの確認

スクリプトは各ステップで詳細な情報を表示します。エラーが発生した場合は、表示されるメッセージを確認してください。

## サポート

問題が発生した場合は、以下を確認してください：

1. 前提条件が満たされているか
2. SAP BTP Cockpitでの設定が正しいか
3. 入力した値が正確か

## ファイル構成

```
documentGroundingSetup/
├── main.sh          # メインスクリプト
├── joule_config.properties                    # 設定ファイル（自動生成）
├── README.md                                  # このファイル
├── template/                                  # テンプレートファイル
│   └── joule_config.properties.template       # 設定テンプレート
├── credentials/                               # 元の証明書ファイル
│   ├── cis_certificate.cer
│   └── cis_key.key
└── credentials_adjusted/                      # 調整済み証明書ファイル
    └── .gitkeep
```

## ライセンス

このスクリプトは教育目的で提供されています。本番環境で使用する前に、十分なテストを行ってください。
