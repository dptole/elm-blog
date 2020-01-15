#!/bin/bash
set -ex
localdir="$(dirname "$0")"

left_zero_fill() {
  DEFAULT_LENGTH=7
  n="$1"
  [[ "$n" =~ ^[1-9][0-9]*$ ]]
  m="${BASH_REMATCH[0]}"
  if ! [ -z "$m" ]
  then
    l="$2"
    if [ -z "$l" ]
    then
      l="$DEFAULT_LENGTH"
    else
      [[ "$l" =~ ^[1-9][0-9]*$ ]]
      ll="${BASH_REMATCH[0]}"
      if [ -z "$ll" ]
      then
        l="$DEFAULT_LENGTH"
      fi
    fi
    while [ "${#n}" -lt "$l" ]
    do
      n="0$n"
    done
  fi
  echo $n
}

INDEX_HTML_FILE="$localdir/index.html"
ELM_FILE="$localdir/src/*/*.elm $localdir/src/*.elm"
ELM_JS_FILE="$localdir/elm.js"
ELM_MIN_JS_FILENAME="elm.min.js"
ELM_MIN_JS_FILE="$localdir/$ELM_MIN_JS_FILENAME"
ELM_MIN_JS_GZ_FILE="$localdir/elm.min.js.gz"
ELM_MIN_JS_BR_FILE="$localdir/elm.min.js.br"
MAIN_ELM_FILE="$localdir/src/Main.elm"
MAIN_ELM_FILENAME="$(basename $MAIN_ELM_FILE)"

tmpfile="$(mktemp)"
mv "$tmpfile" "${tmpfile}-$MAIN_ELM_FILENAME"
tmpfile="${tmpfile}-$MAIN_ELM_FILENAME"

if [ "prod" == "$2" ]
then
  sed -r 's/isProdEnv = False/isProdEnv = True/' "$MAIN_ELM_FILE" > "$tmpfile"
else # "dev"
  cat "$MAIN_ELM_FILE" > "$tmpfile"
fi

if [ "d" == "$1" ]
then
  elm make "$tmpfile" --debug --output="$ELM_JS_FILE"
else # "o"
  elm make "$tmpfile" --optimize --output="$ELM_JS_FILE"
fi

rm "$tmpfile"

uglifyjs "$ELM_JS_FILE" --compress 'pure_funcs="F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9",pure_getters,keep_fargs=false,unsafe_comps,unsafe' | uglifyjs --mangle --output="$ELM_MIN_JS_FILE"

cat <<EOF -> "$INDEX_HTML_FILE"
<!DOCTYPE HTML>
<html>
<head>
  <meta charset="UTF-8">
  <title>Main</title>
  <script src="./$ELM_MIN_JS_FILENAME"></script>
</head>
<body>
  <div id="elm"></div>
<script>
var app = Elm.Main.init({node: elm})
</script>
</body>
</html>
EOF

ELM_SIZE="$(wc -c $ELM_FILE | tail -n 1 | awk '{print$1}')"
ELM_LOC="$((1 + $(wc -l $ELM_FILE | tail -n 1 | awk '{print$1}')))"
ELM_JS_SIZE="$(cat "$ELM_JS_FILE" | wc -c)"
ELM_JS_LOC="$((1 + $(cat "$ELM_JS_FILE" | wc -l)))"
ELM_MIN_JS_SIZE="$(cat "$ELM_MIN_JS_FILE" | wc -c)"
ELM_MIN_JS_LOC="$((1 + $(cat "$ELM_MIN_JS_FILE" | wc -l)))"
ELM_MIN_JS_GZ_SIZE="$(gzip -9 -c "$ELM_MIN_JS_FILE" | wc -c)"
ELM_MIN_JS_BR_SIZE="$(node -e "a=fs.createReadStream('./elm.min.js').pipe(zlib.createBrotliCompress());b=Buffer.from('');a.on('data', bb => b = Buffer.concat([b, bb]));a.once('end', () => console.log(b.length));1")"

ELM_SIZE="$(left_zero_fill "$ELM_SIZE")"
ELM_JS_SIZE="$(left_zero_fill "$ELM_JS_SIZE")"
ELM_MIN_JS_SIZE="$(left_zero_fill "$ELM_MIN_JS_SIZE")"
ELM_MIN_JS_GZ_SIZE="$(left_zero_fill "$ELM_MIN_JS_GZ_SIZE")"
ELM_MIN_JS_BR_SIZE="$(left_zero_fill "$ELM_MIN_JS_BR_SIZE")"

echo "$ELM_SIZE bytes (LOC $ELM_LOC) | $ELM_FILE"

echo ""
echo "$ELM_JS_SIZE bytes | $ELM_JS_FILE (LOC $ELM_JS_LOC)"
echo "$ELM_MIN_JS_SIZE bytes | $ELM_MIN_JS_FILE (LOC $ELM_MIN_JS_LOC)"
echo ""
echo "COMPRESSIONS"
echo "$ELM_MIN_JS_GZ_SIZE bytes | $ELM_MIN_JS_GZ_FILE"
echo "$ELM_MIN_JS_BR_SIZE bytes | $ELM_MIN_JS_BR_FILE"
echo ""
echo "$INDEX_HTML_FILE created"

