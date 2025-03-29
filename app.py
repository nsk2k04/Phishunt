from flask import Flask, request, jsonify
import joblib
from sklearn.feature_extraction.text import TfidfVectorizer

app = Flask(__name__)

# Load the trained model and vectorizer
try:
    model = joblib.load('stack_final_balanced.sav')
    vectorizer = joblib.load('vectorizer.sav')
    print("Model and vectorizer loaded successfully.")
except Exception as e:
    print(f"Error loading model or vectorizer: {e}")
    model = None
    vectorizer = None

# Test route to confirm the API is running
@app.route('/test', methods=['GET'])
def test():
    print("Test endpoint accessed.")
    return jsonify({"message": "API is working!", "status": "success"}), 200

# Main classification route
@app.route('/classify', methods=['POST'])
def classify_message():
    print("Classify endpoint accessed.")
    
    # Check if model and vectorizer are loaded
    if model is None or vectorizer is None:
        print("Model or vectorizer not loaded.")
        return jsonify({
            "error": "Model or vectorizer not loaded properly",
            "status": "failure"
        }), 500

    # Get JSON data from the request
    data = request.get_json()
    print(f"Received data: {data}")
    
    # Validate input
    if not data or 'message' not in data:
        print("Invalid input: 'message' field missing.")
        return jsonify({
            "error": "Invalid input: 'message' field is required",
            "status": "failure"
        }), 400
    
    message = data['message']
    
    # Ensure message is a non-empty string
    if not isinstance(message, str) or not message.strip():
        print("Invalid input: 'message' is not a valid string.")
        return jsonify({
            "error": "Invalid input: 'message' must be a non-empty string",
            "status": "failure"
        }), 400
    
    try:
        # Transform the message using the vectorizer
        print("Transforming input...")
        transformed_input = vectorizer.transform([message])
        
        # Predict using the model
        print("Making prediction...")
        prediction = model.predict(transformed_input)
        
        # Interpret the prediction
        result = "Spam" if prediction[0] == 1 else "Legitimate (Ham)"
        print(f"Prediction result: {result}")
        
        # Return the response
        return jsonify({
            "message": message,
            "prediction": result,
            "status": "success"
        }), 200
    
    except Exception as e:
        print(f"Prediction error: {str(e)}")
        return jsonify({
            "error": f"Prediction failed: {str(e)}",
            "status": "failure"
        }), 500

if __name__ == '__main__':
    print("Starting Flask app...")
    app.run(debug=True, host='0.0.0.0', port=5000)