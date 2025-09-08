import pandas as pd
import plotly.graph_objects as go
from plotly.subplots import make_subplots
from pathlib import Path

csv = list(Path('../languages/').glob('*.csv'))[-1]
print(f'[{csv}]')
df = pd.read_csv(csv, index_col=['benchmark','language'])
print(df)
benchmarks = list(df.index.get_level_values(0).unique())
benchmarks.remove('hello-world')
fig = make_subplots(rows=len(benchmarks), cols=1, subplot_titles=benchmarks)
for idx, benchtype in enumerate(benchmarks):
    df_bench = df.loc[benchtype]
    mean = df_bench['mean-ms']
    df_bench['perf'] = mean.loc['C'] * 100 / mean
    df_bench = df_bench.sort_values(by='mean-ms')
    print(df_bench)
    fig.add_trace(go.Bar(x=df_bench.index, y=df_bench['perf']), row=idx+1, col=1)
fig.update_layout(title_text="current", showlegend=False)
fig.write_html(f'current_chart.html')
