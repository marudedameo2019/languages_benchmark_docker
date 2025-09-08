import pandas as pd
import plotly.graph_objects as go
from plotly.subplots import make_subplots

dirs = ['loops', 'fibonacci', 'levenshtein']
fig = make_subplots(rows=len(dirs), cols=1, subplot_titles=dirs)
for idx, dir in enumerate(dirs):
    df = pd.read_csv(f'../languages/{dir}/run_legacy_result.csv', index_col='command')
    mean = df['mean']
    df['perf'] = mean.loc['C'] * 100 / mean
    df = df.sort_values(by='mean')
    print(df)
    fig.add_trace(go.Bar(x=df.index, y=df['perf']), row=idx+1, col=1)
fig.update_layout(title_text="legacy", showlegend=False)
fig.write_html(f'legacy_chart.html')
