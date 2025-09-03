以下のベンチマークをローカルPCのdocker上で動かして、HTMLのグラフで結果を生成します。

https://github.com/bddicken/languages

# 使い方

- `sh run_bench.sh`: 普通のベンチマークを実施します
- `sh run_bench.sh legacy`: 古い方のベンチマークを実施します
- `sh run_bench.sh all`: 普通のベンチマークと古い方のベンチマーク両方を実施します
- `sh run_bench.sh plot`: 測定は省略してグラフだけ再生成します

# 結果

- languages-simpleplot/current_chart.html: 普通のベンチマーク結果
- languages-simpleplot/legacy_chart.html: 古い方のベンチマーク結果

# 結果例

github workflowsで実際に普通のベンチマークと古いベンチマーク両方を動かした結果のHTMLがexamplesにあります。直接ブラウザで見たい方は以下のリンク(github pages)を辿ってください。

- [普通のベンチマーク結果](https://marudedameo2019.github.io/languages_benchmark_docker/examples/current_chart.html)
- [古い方のベンチマーク結果](https://marudedameo2019.github.io/languages_benchmark_docker/examples/legacy_chart.html)

