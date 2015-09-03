# elasticsearch-hands-on

## キッカケ

Elasticsearch に興味はあるけど，今まで試したことがなかったというメンバーが結構いた．

Docker ハンズオンのときと同じく，教えられるほど詳しくはないけど，Elasticsearch の基礎の部分をハンズオン形式で教えるための教材を書いている．

Elasticsearch 最高！と思えるキッカケ作りの場になれば良いなと思っている．

## 目的

実際に Elasticsearch にデータを投入して，クエリを投げながら理解を深める．

## ゴール

2時間で試せる内容として，今回のゴールを以下のように定める．

* Elasticsearch のデータ構造を理解すること
* マッピングを理解すること
* クラスタの状態などを確認できるようになること
* データを投入できること
* 自分の考えた通りのクエリを投げられること

## 環境構築

### インストールする

* brew
* Docker

今回は brew を使う．バージョンは `1.7.1` とする．

```
➜  ~  brew install elasticsearch
➜  ~  elasticsearch -v
Version: 1.7.1, Build: b88f43f/2015-07-29T09:54:16Z, JVM: 1.8.0_20
```

### 主要なプラグインをインストールする

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

プラグインの詳細はドキュメントを見る．

* https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-plugins.html
