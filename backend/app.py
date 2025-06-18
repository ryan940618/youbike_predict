from flask import Flask, request, jsonify
from flask_cors import CORS
import os
import json
from datetime import datetime
from analyzer import Analyzer

app = Flask(__name__)
CORS(app)

DATASET_FOLDER = 'dataset'
os.makedirs(DATASET_FOLDER, exist_ok=True)
analyzer = Analyzer()

with app.app_context():
    def load_dataset():
        for fname in os.listdir(DATASET_FOLDER):
            if fname.endswith('.json'):
                try:
                    with open(os.path.join(DATASET_FOLDER, fname), "r", encoding="utf-8") as f:
                        analyzer.load_from_file(f)
                except Exception as e:
                    print(f"Failed to parse {fname}: {e}")
    load_dataset()

@app.route('/upload', methods=['POST'])
def upload():
    try:
        raw_body = request.get_data(as_text=True)

        timestamp = datetime.now().isoformat()
        filename = f'data_{timestamp.replace(":", "-")}.json'
        path = os.path.join(DATASET_FOLDER, filename)

        with open(path, 'w', encoding='utf-8', newline='') as f:
            f.write(raw_body)

        with open(path, 'r', encoding='utf-8') as f:
            analyzer.load_from_file(f)

        return jsonify({"status": "ok", "saved": filename}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 400

@app.route('/data/<ts>', methods=['GET'])
def get_data(ts):
    try:
        dt = datetime.fromisoformat(ts)
        result = analyzer.get_snapshot_by_timestamp(dt)
        return jsonify(result)
    except Exception as e:
        return jsonify({"error": str(e)}), 400

@app.route('/range', methods=['GET'])
def range_query():
    try:
        start = datetime.fromisoformat(request.args['start'])
        end = datetime.fromisoformat(request.args['end'])
        station_no = request.args.get('station_id')

        logs = analyzer.get_logs_in_range(station_no, start, end)
        return jsonify(analyzer.format_logs_as_json(logs))
    except Exception as e:
        return jsonify({"error": str(e)}), 400

@app.route('/api/hourly_avg/<station_id>', methods=['GET'])
def hourly_avg(station_id):
    try:
        avg = analyzer.get_hourly_avg(station_id)
        return jsonify(avg)
    except Exception as e:
        return jsonify({"error": str(e)}), 400

@app.route('/api/hourly_delta/<station_id>', methods=['GET'])
def hourly_delta(station_id):
    try:
        delta = analyzer.get_hourly_avg_delta(station_id)
        return jsonify(delta)
    except Exception as e:
        return jsonify({"error": str(e)}), 400

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True, use_reloader=False)
