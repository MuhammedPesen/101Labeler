curl -X POST "https://3cb7-176-234-216-222.ngrok-free.app/detect/" \
     -H "accept: application/json" \
     -H "Content-Type: multipart/form-data" \
     -H "access_token: test" \
     -F "file=@img_0.png" \
     -o labeled_img_0.png \
     -D headers.txt

echo $(grep "x-label-sum" headers.txt | cut -d' ' -f2)
