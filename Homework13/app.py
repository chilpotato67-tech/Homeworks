from flask import Flask, request, jsonify
import csv
import os

app = Flask(__name__)

CSV_FILE = 'students.csv'
FIELDNAMES = ['id', 'first_name', 'last_name', 'age']
VALID_FIELDS = {'first_name', 'last_name', 'age'}

# ---------- HELPERS ----------

def read_students():
    if not os.path.exists(CSV_FILE):
        return []
    with open(CSV_FILE, 'r', newline='') as file:
        reader = csv.DictReader(file)
        return list(reader)

def write_students(students):
    with open(CSV_FILE, 'w', newline='') as file:
        writer = csv.DictWriter(file, fieldnames=FIELDNAMES)
        writer.writeheader()
        writer.writerows(students)

def find_student_by_id(students, student_id):
    for index, student in enumerate(students):
        if student['id'] == str(student_id):
            return index, student
    return None, None

def get_next_id(students):
    if not students:
        return 1
    return max(int(student['id']) for student in students) + 1

def validate_fields(data, required_fields=None):
    if not data:
        return False, 'No fields provided'

    if not set(data.keys()).issubset(VALID_FIELDS):
        return False, 'Invalid fields provided'

    if required_fields and not required_fields.issubset(data.keys()):
        return False, 'Missing required fields'

    return True, None

# ---------- GET ----------

@app.route('/students', methods=['GET'])
def get_all_students():
    return jsonify(read_students()), 200

@app.route('/students/<int:student_id>', methods=['GET'])
def get_student_by_id(student_id):
    students = read_students()
    _, student = find_student_by_id(students, student_id)
    if not student:
        return jsonify({'error': 'Student not found'}), 404
    return jsonify(student), 200

@app.route('/students/lastname/<last_name>', methods=['GET'])
def get_students_by_last_name(last_name):
    students = read_students()
    result = [
        s for s in students
        if s['last_name'].lower() == last_name.lower()
    ]
    if not result:
        return jsonify({'error': 'No students found'}), 404
    return jsonify(result), 200

# ---------- POST ----------

@app.route('/students', methods=['POST'])
def create_student():
    data = request.get_json()
    valid, error = validate_fields(data, VALID_FIELDS)
    if not valid:
        return jsonify({'error': error}), 400

    students = read_students()
    new_student = {
        'id': str(get_next_id(students)),
        'first_name': data['first_name'],
        'last_name': data['last_name'],
        'age': str(data['age'])
    }

    students.append(new_student)
    write_students(students)
    return jsonify(new_student), 201

# ---------- PUT ----------

@app.route('/students/<int:student_id>', methods=['PUT'])
def update_student(student_id):
    data = request.get_json()
    valid, error = validate_fields(data, VALID_FIELDS)
    if not valid:
        return jsonify({'error': error}), 400

    students = read_students()
    index, student = find_student_by_id(students, student_id)
    if not student:
        return jsonify({'error': 'Student not found'}), 404

    students[index].update({
        'first_name': data['first_name'],
        'last_name': data['last_name'],
        'age': str(data['age'])
    })

    write_students(students)
    return jsonify(students[index]), 200

# ---------- PATCH ----------

@app.route('/students/<int:student_id>', methods=['PATCH'])
def patch_student_age(student_id):
    data = request.get_json()
    if not data or 'age' not in data:
        return jsonify({'error': 'Only field age is allowed'}), 400

    students = read_students()
    index, student = find_student_by_id(students, student_id)
    if not student:
        return jsonify({'error': 'Student not found'}), 404

    students[index]['age'] = str(data['age'])
    write_students(students)
    return jsonify(students[index]), 200

# ---------- DELETE ----------

@app.route('/students/<int:student_id>', methods=['DELETE'])
def delete_student(student_id):
    students = read_students()
    index, student = find_student_by_id(students, student_id)
    if not student:
        return jsonify({'error': 'Student not found'}), 404

    students.pop(index)
    write_students(students)
    return jsonify({'message': f'Student {student_id} deleted successfully'}), 200

# ---------- RUN ----------

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000, debug=True)