"""
AWS Lambda handler for the MoltBot application.
Runs as a container image on AWS Lambda.
"""
import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def handler(event, context):
    """Lambda function handler."""
    logger.info("Received event: %s", json.dumps(event))

    # Handle API Gateway proxy events
    http_method = event.get("httpMethod", "GET")
    path = event.get("path", "/")
    body = event.get("body")

    if path == "/health":
        return {
            "statusCode": 200,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"status": "healthy"}),
        }

    if path == "/" and http_method == "GET":
        return {
            "statusCode": 200,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({
                "message": "Welcome to MoltBot API",
                "version": "1.0.0",
            }),
        }

    if path == "/predict" and http_method == "POST":
        try:
            payload = json.loads(body) if body else {}
            result = {"prediction": "sample_output", "input": payload}
            return {
                "statusCode": 200,
                "headers": {"Content-Type": "application/json"},
                "body": json.dumps(result),
            }
        except json.JSONDecodeError:
            return {
                "statusCode": 400,
                "headers": {"Content-Type": "application/json"},
                "body": json.dumps({"error": "Invalid JSON in request body"}),
            }

    return {
        "statusCode": 404,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps({"error": "Not found"}),
    }
