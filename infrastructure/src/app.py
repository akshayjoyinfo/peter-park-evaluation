import json
import base64
import boto3

textract = boto3.client("textract")
rekognition = boto3.client("rekognition")


def extract_text_by_textract(base64_string):
    image_bytes = base64.b64decode(base64_string)
    response = textract.detect_document_text(Document={"Bytes": image_bytes})

    # Extract text from the response
    # Extract text blocks and their confidence
    text_detections = []
    for item in response.get('Blocks', []):
        if item.get('BlockType') == 'LINE' and 'Text' in item:
            detected_text = item['Text']
            confidence = item.get('Confidence', 'N/A')
            text_detections.append({
                'DetectedText': detected_text,
                'Confidence': confidence
            })
    
    return text_detections


def extract_text_by_rekognition(base64_image):
    # Decode the base64 string to get the raw image bytes
    image_bytes = base64.b64decode(base64_image)

    # Call Rekognition to detect text in the image (pass raw bytes)
    response = rekognition.detect_text(
        Image={'Bytes': image_bytes}
    )

    # Extract text detections and their confidence
    text_detections = []
    for detection in response.get('TextDetections', []):
        detected_text = detection['DetectedText']
        confidence = detection.get('Confidence', 'N/A')
        text_detections.append({
            'DetectedText': detected_text,
            'Confidence': confidence
        })
    
    return text_detections


def lambda_handler(event, context):
    try:
        body = json.loads(event["body"])
        base64_string = body["image"]  # if you want to test lambda along then remove body just take image from event itself

        # Extract text using both Textract and Rekognition
        extracted_text_textract = extract_text_by_textract(base64_string)
        extracted_text_rekognition = extract_text_by_rekognition(base64_string)

        # Combine the results in a dictionary and return as JSON response
        response_body = {
            "TextractResults": extracted_text_textract,
            "RekognitionResults": extracted_text_rekognition
        }

        return {
            "statusCode": 200,
            "body": json.dumps(response_body),
        }

    except Exception as e:
        print(e)
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)}),
        }
