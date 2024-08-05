from fastapi import FastAPI, File, UploadFile, Depends, HTTPException, Security
from fastapi.security.api_key import APIKeyHeader
from fastapi.responses import Response
from starlette.status import HTTP_403_FORBIDDEN
import io
import cv2
import numpy as np
from ultralytics import YOLO
from ultralytics.utils.plotting import Annotator, colors

app = FastAPI()

# Load your trained model
model = YOLO('best.pt')  # Replace with the path to your trained model


# API Key setup
API_KEY = "test"  # Replace with your actual API key
API_KEY_NAME = "access_token"
api_key_header = APIKeyHeader(name=API_KEY_NAME, auto_error=False)

async def get_api_key(api_key_header: str = Security(api_key_header)):
    if api_key_header == API_KEY:
        return api_key_header   
    else:
        raise HTTPException(
            status_code=HTTP_403_FORBIDDEN, detail="yanlis kapi"
        )

@app.post("/detect/")
async def detect_objects(file: UploadFile = File(...), api_key: str = Depends(get_api_key)):
    # Read the uploaded image
    contents = await file.read()
    nparr = np.frombuffer(contents, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    
    # Perform inference
    results = model(img)
    
    detection_labels = []
    
    annotator = Annotator(img)
    
    for r in results:
        boxes = r.boxes
        for box in boxes:
            b = box.xyxy[0]
            c = box.cls
            label = model.names[int(c)]
            detection_labels.append(label)
            annotator.box_label(b, label, color=colors(c, True))
    
    # Calculate the sum of labels
    label_sum = sum([int(x) for x in detection_labels if (x != "NULL" and x != "JOK")])
    
    # Convert the image to bytes
    is_success, buffer = cv2.imencode(".png", img)
    io_buf = io.BytesIO(buffer)
    
    response = Response(content=io_buf.getvalue(), media_type="image/png")
    response.headers["X-Label-Sum"] = str(label_sum)
    
    return response

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="localhost", port=8080)
