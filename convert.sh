MNAME=$1
MOD=`tr [a-z] [A-Z] <<<"$MNAME"`
sed   's/<\([a-zA-Z][a-zA-Z]*\)>/<'$MNAME'\1>/g' | \
sed 's/<\/\([a-zA-Z][a-zA-Z]*\)>/<\/'$MNAME'\1>/g' | \
sed 's/{MOD}/'$MOD'/g' | \
sed 's/{mod}/'$MNAME'/g'
