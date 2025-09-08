set -e
legacy=false
current=true
plotonly=false
if [ "$#" = "1" ]; then
    case "$1" in
        legacy)
            legacy=true
            current=false
            ;;
        all)
            legacy=true     
            ;;
        plot)
            current=false
            plotonly=true
            ;;
        *)
            ;;
    esac
fi
cd /app/languages
if [ "$legacy" = "true" ]; then
    for benchtype in loops fibonacci levenshtein;do
        cd "$benchtype"
        echo "$benchtype"
        ../compile-legacy.sh
        ../run-legacy.sh |sed '/^$/d'|sed '2,${/^command,mean,stddev,median,user,system,min,max$/d}'| tee run_legacy_result.csv
        cd ..
    done
fi
if [ "$current" = "true" ]; then
    ./compile.sh
    ./run.sh
    cp -p /tmp/languages-benchmark/*.csv .
fi
cd "../languages-simpleplot"
if [ ! -d "env" ]; then
    uv venv env
    . env/bin/activate
    uv pip install pandas plotly
else
    . env/bin/activate
fi
if [ "$current" = "true" -o "$plotonly" = "true" ]; then
    python plot_current.py
fi
if [ "$legacy" = "true" -o "$plotonly" = "true" ]; then
    python plot_legacy.py
fi
deactivate
cd ..
