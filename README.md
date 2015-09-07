# elasticsearch-hands-on

## 1. キッカケ

Elasticsearch に興味はあるけど，今まで試したことがなかったというメンバーが結構いた．

Docker ハンズオンのときと同じく，教えられるほど詳しくはないけど，Elasticsearch の基礎の部分をハンズオン形式で教えるための教材を書いている．

Elasticsearch 最高！と思えるキッカケ作りの場になれば良いなと思っている．

## 2. 目的

実際に Elasticsearch にデータを投入して，クエリを投げながら理解を深める．

## 3. ゴール

2時間で試せる内容として，今回のゴールを以下のように定める．

* Elasticsearch のデータ構造を理解すること
* マッピングを理解すること
* クラスタの状態などを確認できるようになること
* データを投入できること
* 自分の考えた通りのクエリを投げられること

## 4. 環境構築

### 4-1. インストールする

* brew
* Docker

今回は brew を使う．バージョンは `1.7.1` とする．

```
➜  ~  brew install elasticsearch
➜  ~  elasticsearch -v
Version: 1.7.1, Build: b88f43f/2015-07-29T09:54:16Z, JVM: 1.8.0_20
```

### 4-2. HTTP で送る最大サイズを 200MB に拡大する

（環境によってディレクトリが違うかもしれないけど）

`/usr/local/Cellar/elasticsearch/1.7.1/config/elasticsearch.yml` に定義されている `http.max_content_length` を修正する．今回 Bulk API で投入するデータ量が 100MB 以上になるのでこの設定が必要になる．

* Before

```
#http.max_content_length: 100mb
```

* After

```
http.max_content_length: 200mb
```

設定の詳細はドキュメントを見る．

* [HTTP](https://www.elastic.co/guide/en/elasticsearch/reference/master/modules-http.html)

### 4-3. 主要なプラグインをインストールする

Elasticsearch のインストールと同時に `plugin` コマンドが使えるようになっている．

```
➜  ~  which plugin
/usr/local/bin/plugin
```

今回は3個のプラグインをインストールする．

```
➜  ~  plugin --install mobz/elasticsearch-head
➜  ~  plugin --install polyfractal/elasticsearch-inquisitor
➜  ~  plugin --install elasticsearch/elasticsearch-analysis-kuromoji/2.7.0
```

正常にインストールされたことを確認する．

```
➜  ~  plugin -l
Installed plugins:
    - analysis-kuromoji
    - head
    - inquisitor
```

プラグインの詳細はドキュメントを見る．

* [Plugins](https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-plugins.html)

### 4-4. 起動してみる

簡単に起動できる．

```
➜  ~  elasticsearch
（中略）
[INFO ][node                     ] [Hellion] starting ...
（中略）
```

JSON が返ってくればちゃんと起動できている．

```
➜  ~  curl http://localhost:9200
```

（豆知識として）

Elasticsearch のノード名はデフォルトで Marvel のキャラクター名がランダムで選ばれる．皆さんのノード名は何のキャラクターでした？

* [Elasticsearch のノード名と Marvel のキャラクター一覧を比較してみた - kakakakakku blog](http://kakakakakku.hatenablog.com/entry/2015/08/29/163518)

## 5. Elasticsearch のデータ構造

使う前に Elasticsearch のデータ構造を頭に入れておく．

Elasticsearch のデータ構造を RDBMS で表現するとっていう書き方をよく見るが，本質的には違うものなので，言わないでおく．

（口頭で説明する）

* クラスタ
* ノード
* インデックス
* タイプ
* ドキュメント
* フィールド

データ構造の詳細はドキュメントを見る．

* [Basic Concepts](https://www.elastic.co/guide/en/elasticsearch/reference/current/_basic_concepts.html)

## 6. はじめての Elasticsearch

ブログ記事のドキュメントを投入する．

```
➜  ~  curl -X PUT http://localhost:9200/blog/articles/1 -d '
{
  "title": "Elasticsearch Hand-On",
  "body": "Hello!",
  "tags": ["elasticsearch", "handson"]
}
'
```

ドキュメントを抽出する．

```
➜  ~  curl http://localhost:9200/blog/articles/1
```

次から実践的に Elasticsearch を使っていく．

## 7. Elasticsearch でレストランを検索する

### 7-1. データを落としてくる

* [livedoor/datasets](https://github.com/livedoor/datasets)

Livedoor 様が提供してるレストランデータを活用するので，まず任意のディレクトリにデータを落としてくる．

`.tar.gz` を展開すると複数のファイルが含まれているが，今回は `restaurants.csv` だけを使う．約20万以上のレストランが含まれている．

```
➜  github  git clone git@github.com:livedoor/datasets.git
➜  github  cd datasets
➜  datasets git:(master) ✗ tar xvf ldgourmet.tar.gz
➜  datasets git:(master) ✗ ls -al restaurants.csv
➜  datasets git:(master) ✗ wc -l restaurants.csv
  214263 restaurants.csv
```

### 7-2. データをコンバートする

（ディレクトリ構造は各自違うので細かいところは任せる）

ハンズオンリポジトリの `scripts` ディレクトリに用意しておいた Ruby スクリプトを `datasets` ディレクトリにコピーして実行する．

結果として `bulk_restaurants.json` が生成されていれば正常にコンバートできている．

```
➜  datasets git:(master) ✗ cp -p ${GITHUB_DIR}/elasticsearch-hands-on/scripts/convert_bulk_data.rb .
➜  datasets git:(master) ✗ ruby convert_bulk_data.rb
（数分で実行完了になるはず）
➜  datasets git:(master) ✗ ls -al bulk_restaurants.json
```

### 7-3. インデックスを作成する

コンバートしたデータを投入する前にインデックスを作成する．

ハンズオンリポジトリの `mappgins` ディレクトリに用意しておいたマッピング定義をベースにインデックスを作成する．

```
➜  elasticsearch-hands-on git:(master) ✗ curl -X POST http://localhost:9200/gourmet -d @mappings/restaurants.json
{"acknowledged":true}%
```

念のためマッピングを確認しておく．

```
➜  elasticsearch-hands-on git:(master) ✗ curl http://localhost:9200/gourmet/restaurants/_mapping\?pretty
```

### 7-4. Bulk API を使ってデータを投入する

```
➜  datasets git:(master) ✗ curl -X POST http://localhost:9200/_bulk --data-binary @bulk_restaurants.json
（数分で実行完了になるはず）
```

cat count API でドキュメント数を確認する．

```
➜  ~  curl http://localhost:9200/_cat/count/gourmet\?v
epoch      timestamp count
1441417478 10:44:38  214236
```

Bulk API と cat APIs の詳細はドキュメントを見る．

* [Bulk API](https://www.elastic.co/guide/en/elasticsearch/reference/master/docs-bulk.html)
* [cat APIs](https://www.elastic.co/guide/en/elasticsearch/reference/master/cat.html)

### 7-5. 検索する

### 7-5-1. elasticsearch-inquisitor

基本的に curl を使った手順に統一して書いていますが，既にインストール済の elasticsearch-inquisitor を使うこともできます．その場合は以下の URL にアクセスするだけで使えます．

>http://localhost:9200/_plugin/inquisitor/#/

### 7-5-2. Match All Query

まず，インデックスから条件なしで検索してみる．デフォルトで10件抽出される．

```
➜  ~  curl http://localhost:9200/gourmet/restaurants/_search\?pretty -d '
{
  "query": {
    "match_all": {}
  }
}
'
```

* [Match All Query](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-match-all-query.html)

### 7-5-3. Match Query

次に，店名に "焼肉" と含まれているレストランを検索してみる．

```
➜  ~  curl http://localhost:9200/gourmet/restaurants/_search\?pretty -d '
{
  "query": {
    "match": { "name": "焼肉" }
  }
}
'
```

さらにバイキング形式の焼肉を検索してみる．

ただし，これだと焼肉以外のバイキングも検索されてしまうはず．

```
➜  ~  curl http://localhost:9200/gourmet/restaurants/_search\?pretty -d '
{
  "query": {
    "match": { "name": "焼肉 バイキング" }
  }
}
'
```

デフォルトだと OR 検索になるので，今度は明示的に AND 検索をしてみる．

```
➜  ~  curl http://localhost:9200/gourmet/restaurants/_search\?pretty -d '
{
  "query": {
    "match": {
      "name": {
        "query": "焼肉 バイキング",
        "operator": "and"
      }
    }
  }
}
'
```

* [Match Query](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-match-query.html)

### 7-5-4. Multi Match Query

今のままだと東京以外も検索されてしまう．渋谷に限定してみる．

これだと `name` と `address` の両方にキーワードが含まれている場合だけ該当してしまうので限定し過ぎている．

```
➜  ~  curl http://localhost:9200/gourmet/restaurants/_search\?pretty -d '
{
  "query": {
    "multi_match": {
      "fields": ["name", "address"],
      "query": "焼肉 渋谷",
      "operator": "and"
    }
  }
}
'
```

* [Multi Match Query](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-multi-match-query.html)

### 7-5-5. Match Query & _all field

そこで `_all` フィールドに対して検索をしてみる．

`_all` は Elasticsearch が自動的に生成した全フィールドの値を含んだ仮想的なフィールドで検索対象にできる．

```
➜  ~  curl http://localhost:9200/gourmet/restaurants/_search\?pretty -d '
{
  "query": {
    "match": {
      "_all": {
        "query": "焼肉 渋谷",
        "operator": "and"
      }
    }
  }
}
'
```

### 7-5-6. Match Query & Sorting

今度はアクセス回数の多い順にソートして人気のレストランを検索する．

```
➜  ~  curl http://localhost:9200/gourmet/restaurants/_search\?pretty -d '
{
  "query": {
    "match": {
      "name": "焼肉"
    }
  },
  "sort": [
    {
      "access_count": "desc"
    }
  ]
}
'
```

### 7-5-7. More Like This Query

More Like This Query を使うとレコメンデーションのように類似するドキュメントを検索することができる．

詳細は割愛するが，ドキュメントの中にある重要語を抽出して，その重要語を同じく持つドキュメントを近似するような実装になっている．

重要語の判定は TF-IDF など，昔から NLP の分野で使われている手法が実装されているはず（推測だけど）．

今回はマークシティ勤務なら絶対1回は買ったことがあるであろう「和幸 (id: 363297)」をベースに類似店舗を出してみる．

```
➜  ~  curl http://localhost:9200/gourmet/restaurants/363297\?pretty
```

More Like This Query を投げる．

```
➜  ~  curl http://localhost:9200/gourmet/restaurants/_search\?pretty -d '
{
  "query": {
    "more_like_this": {
      "fields": ["name", "address", "description"],
      "ids": ["363297"],
      "min_term_freq": 1,
      "min_doc_freq": 10,
      "minimum_should_match": "70%"
    }
  }
}
'
```

データセットの `description` にあまり文書が書かれてないため，驚くような結果が出ないはず．

さらに今回はあえて `address` も対象に含めてしまっているため，単純に「道玄坂」関連のレストランが出てくる可能性がある．

* [More Like This Query](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-mlt-query.html)

### 7-5-8. Term Filter

ここで始めて Filter を使ってみる．

例としてカテゴリ一覧から以下のカテゴリコードをサンプリングした．

```
➜  datasets git:(master) ✗ egrep '320|326' categories.csv
320,"豚骨ラーメン","とんこつらーめん",800,0,
326,"博多ラーメン","はかたらーめん",800,0,
```

カテゴリコードに該当するレストランをアクセス回数の多い順にソートして検索する．

```
➜  ~  curl http://localhost:9200/gourmet/restaurants/_search\?pretty -d '
{
  "filter": {
    "term": {
      "category_id1": ["320", "326"]
    }
  },
  "sort": [
    {
      "access_count": "desc"
    }
  ]
}
`
```

* [Term Filter](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-term-filter.html)

## 8. Query と Filter

今までは全て Query を使ってきたけど，Elasticsearch では Query と Filter で大きく意味が違う．

Query はスコアリングに影響する検索のために使うもので，全部検索や関連度に応じて抽出するようなクエリで利用する．

それと比較して Filter はスコアリングに影響せず，シンプルに条件に合致するかだけで抽出するようなクエリで利用する．またキャッシュすることもでき，検索結果は Query と比較すると非常に高速になる．

また Query と Filter は併用することもできるため，うまくチューニングをしていく必要がある．

* [Queries](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-queries.html)
* [Filters](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-filters.html)

## 9. ハイライトを実現する

検索サービスだと当たり前に実装されているハイライトを試してみる．

今まで投げてきたクエリに `highlight` セクションを追加するだけで実現できる．

```
➜  ~  curl http://localhost:9200/gourmet/restaurants/_search\?pretty -d '
{
  "query": {
    "match": {
      "name": {
        "query": "焼肉 バイキング",
        "operator": "and"
      }
    }
  },
  "highlight": {
    "fields" : {
      "name": {}
    }
  }
}
'
```

## 10. 日本語処理に関して

最後に日本語処理に関して簡単に説明する．

日本語は英語と異なり単語間の区切り文字がないため，以下のような手法で文字列を分割していく必要がある．

* N-Gram
* 形態素解析

（トークナイザーとアナライザーの説明は口頭でする）

### 10-1. N-Gram

シンプルに指定された文字数で分割して転置インデックスを構成する手法のこと．

今回のマッピング設定では 2-Gram と 3-Gram の設定をしている．

```
➜  ~  curl -s http://localhost:9200/gourmet/_analyze\?tokenizer\=ngram_tokenizer\&pretty -d '東京都渋谷区で勤務しています' | grep '"token"'
    "token" : "東京",
    "token" : "東京都",
    "token" : "京都",
    "token" : "京都渋",
    "token" : "都渋",
    "token" : "都渋谷",
    "token" : "渋谷",
    "token" : "渋谷区",
    "token" : "谷区",
    "token" : "谷区で",
    "token" : "区で",
    "token" : "区で勤",
    "token" : "で勤",
    "token" : "で勤務",
    "token" : "勤務",
    "token" : "勤務し",
    "token" : "務し",
    "token" : "務して",
    "token" : "して",
    "token" : "してい",
    "token" : "てい",
    "token" : "ていま",
    "token" : "いま",
    "token" : "います",
    "token" : "ます",
```

### 10-2. 形態素解析

形態素解析では kuromoji を使っている．N-Gram で抽出された非実用的なフレーズが無くなるが，未知語などには弱かったりもする．

```
➜  ~  curl -s http://localhost:9200/gourmet/_analyze\?tokenizer\=kuromoji\&pretty -d '東京都渋谷区で勤務しています' | grep '"token"'
    "token" : "東京",
    "token" : "都",
    "token" : "渋谷",
    "token" : "区",
    "token" : "で",
    "token" : "勤務",
    "token" : "し",
    "token" : "て",
    "token" : "い",
    "token" : "ます",
```

さらに `kuromoji_baseform` を使うことで表記揺れの統一も意識せずインデックスすることができる．

```
➜  ~  curl -s http://localhost:9200/gourmet/_analyze\?analyzer\=kuromoji_analyzer\&pretty -d '飲み飲む飲もう' | grep '"token"'
    "token" : "飲む",
    "token" : "飲む",
    "token" : "飲む",
    "token" : "う",
```

実際にはもっと細かな設定をすることができる．

N-Gram も形態素解析も一長一短があり，用途に応じて組み合わせて使うことがベストプラクティスなのかなと思う．

## 11. 最後にグループワークをする

各自でクエリを考えてみて，明日のランチに行くお店を探してみましょう．

テーマは「ハンズオンの打ち上げランチ」で！

各自のクエリが出揃ったら発表する．

せっかくなら `open_lunch` フィールドを使うと良いかも？

## 12. コントリビュート

Elasticsearch のドキュメントを読んでいるとたまに気になるポイントが見つかったりする．

コードの修正ができなくても，ドキュメントの修正ならできる．僕も少し修正してみたことがある．

* [Pull Requests · elastic/elasticsearch](https://github.com/elastic/elasticsearch/pulls?utf8=%E2%9C%93&q=author%3AKakakakakku)

Enjoy Elasticsearch!
