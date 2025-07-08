# routes.py

from flask import Blueprint, request, jsonify
from models import db, Employee

bp = Blueprint("routes", __name__)

# 🔍 Search employees by name or department
@bp.route("/employees", methods=["GET"])
def get_employees():
    search = request.args.get("search", "")
    results = Employee.query.filter(
        (Employee.name.ilike(f"%{search}%")) |
        (Employee.department.ilike(f"%{search}%"))
    ).all()
    return jsonify([
        {
            "id": e.id,
            "name": e.name,
            "email": e.email,
            "department": e.department
        } for e in results
    ])

# 📄 Get single employee by ID
@bp.route("/employees/<int:id>", methods=["GET"])
def get_employee(id):
    emp = Employee.query.get_or_404(id)
    return jsonify({
        "id": emp.id,
        "name": emp.name,
        "email": emp.email,
        "department": emp.department
    })

# 🆕 Create a new employee
@bp.route("/employees", methods=["POST"])
def create_employee():
    data = request.get_json()

    if not data or not all(key in data for key in ("name", "email", "department")):
        return jsonify({"error": "Missing required fields"}), 400

    # Optional: Check for duplicate email
    if Employee.query.filter_by(email=data["email"]).first():
        return jsonify({"error": "Email already exists"}), 400

    new_emp = Employee(
        name=data["name"],
        email=data["email"],
        department=data["department"]
    )
    db.session.add(new_emp)
    db.session.commit()

    return jsonify({"message": "Employee created", "id": new_emp.id}), 201

# ✏️ Update employee by ID
@bp.route("/employees/<int:id>", methods=["PUT"])
def update_employee(id):
    emp = Employee.query.get_or_404(id)
    data = request.get_json()

    if not data:
        return jsonify({"error": "No data provided"}), 400

    emp.name = data.get("name", emp.name)
    emp.email = data.get("email", emp.email)
    emp.department = data.get("department", emp.department)

    db.session.commit()
    return jsonify({"message": "Employee updated successfully"})


@bp.route("/employees/<int:id>", methods=["DELETE"])
def delete_employee(id):
    emp = Employee.query.get_or_404(id)
    db.session.delete(emp)
    db.session.commit()
    return jsonify({"message": "Employee deleted successfully"})
