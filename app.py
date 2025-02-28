from flask import Flask, request, jsonify
from google import genai
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

client = genai.Client(api_key="AIzaSyDT01P2_I_fOHKDChWT1naS_MybdwM_e4I")

@app.route("/generate_travel_plan", methods=["POST"])
def generate_travel_plan():
    data = request.json
    preferences = data.get("preferences", {})

    departure = preferences.get("departure", "Unknown")
    destination = preferences.get("destination", "Unknown")
    budget = preferences.get("budget", "Not specified")
    activities = preferences.get("activities", "Not specified")

    prompt = f"""Create a detailed travel plan from {departure} to {destination} with a budget of {budget}.
    Preferred activities: {activities}.
    
    Return response in EXACTLY this JSON format:
    {{
        "trip_name": "string",
        "budget": number,
        "origin_coordinates": {{"latitude": number, "longitude": number}},
        "destination": "string",
        "theme": "string",
        "duration": "string",
        "day_itinerary": [
            {{
                "day": number,
                "title": "string",
                "description": "string",
                "activities": ["string"],
                "estimated_cost": number
            }}
        ]
    }}
    ONLY return the JSON, no Markdown or extra text."""


    try:
        response = client.models.generate_content(
            model="gemini-2.0-flash",
            contents=prompt
        )
        return jsonify({
            "plan": response.text,
            "departure": departure,
            "destination": destination
        })
    except Exception as e:
        return jsonify({"error": f"Failed to generate plan: {str(e)}"}), 500

if __name__ == "__main__":
    app.run(debug=True)
