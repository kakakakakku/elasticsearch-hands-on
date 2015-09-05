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

`/usr/local/Cellar/elasticsearch/1.7.1/config/elasticsearch.yml` に定義されている `http.max_content_length` を修正する．

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

簡単に起動する！

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

豆知識だけど，Elasticsearch のノード名は，デフォルトで Marvel のキャラクター名がランダムで選ばれる．

皆さんのノード名は何のキャラクターでした？

* [Elasticsearch のノード名と Marvel のキャラクター一覧を比較してみた - kakakakakku blog](http://kakakakakku.hatenablog.com/entry/2015/08/29/163518)

## 5. Elasticsearch のデータ構造

使う前に Elasticsearch のデータ構造を頭に入れておきましょう．

Elasticsearch のデータ構造を RDBMS で表現すると...っていう書き方をよく見るけど，あえて言わないでおく．

* クラスタ
* ノード
* インデックス
* タイプ
* フィールド

## 6. はじめての Elasticsearch

まずは適当なデータを投入してみましょう．

WIP...

## 7. Elasticsearch でレストランを検索しよう

### 7-1. データを落としてくる

* [livedoor/datasets](https://github.com/livedoor/datasets)

Livedoor 様が提供してるレストランデータを活用するので， まず任意のディレクトリにデータを落としてくる．

`.tar.gz` を展開すると複数のファイルが出てくるけど，今回は `restaurants.csv` だけを使う．約20万以上のレストランが含まれている．

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

### 7-5. 簡単な検索をしてみよう

まず，インデックスから条件なしで検索してみましょう．デフォルトで10件抽出されます．

```
➜  ~  curl http://localhost:9200/gourmet/restaurants/_search\?pretty -d '
{
  "query": {
    "match_all": {}
  }
}
'
```

次に，店名に "焼肉" と含まれているレストランを検索してみましょう．

```
➜  ~  curl http://localhost:9200/gourmet/restaurants/_search\?pretty -d '
{
  "query": {
    "match": { "name": "焼肉" }
  }
}
'
```

焼肉と言えば，店名に "亭" が付いてるイメージありますよね？（個人差？）

`match` クエリを使って検索ボックスを使うイメージで検索してみましょう．

```
➜  ~  curl http://localhost:9200/gourmet/restaurants/_search\?pretty -d '
{
  "query": {
    "match": { "name": "焼肉 亭" }
  }
}
'
```

デフォルトだと OR 検索になるので，今度は明示的に AND 検索をしてみましょう．

```
➜  ~  curl http://localhost:9200/gourmet/restaurants/_search\?pretty -d '
{
  "query": {
    "match": {
      "name": {
        "query": "焼肉 亭 叙々苑",
        "operator": "and"
      }
    }
  }
}
```

今のままだと東京以外も検索されてしまいます．渋谷に限定してみましょう．

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
