# 101 Labeler

101 Labeler is an Android app that detects objects in images using a custom YOLO model.

## Features

- Take photos with your phone camera
- Crop images
- Detect objects using AI
- Display detected objects with labels
- Show the sum of detected numeric labels

## Technology

Backend:
- Python with FastAPI and YOLO

Frontend:
- Flutter

## Setup

1. Install required Python packages in server/requirements.txt
```bash
pip install -r server/requirements.txt
```

2. Place your YOLO model file (`best.pt`) in the same folder as the Python script.

3. Set up your API key in the Python script.

4. Run the server:
I used the free version of ngrok for local testing. If you also use ngrok, make sure to update the URL in the Flutter code. I attempted to deploy the backend to Vercel's free tier, but it wasn't suitable for running inference, so the deployment failed.

5. Run the app:
## How to Use

1. Open the app on your Android phone.
2. Allow camera access.
3. Take a photo of an object.
4. Crop the image if needed.
5. The app will process the image and show results.

Note: Only tested on Android. Wanted to implement it in IOS but I dont have access to MacOS environment :/