import React, { useState, useEffect } from 'react';
import axios from 'axios';

// const API_URL = "http://13.235.245.253:5000/api/employees";
const API_URL = (window._env_ && window._env_.REACT_APP_API_BASE_URL) || "/api/employees";

function App() {
  const [employees, setEmployees] = useState([]);
  const [query, setQuery] = useState("");
  const [formData, setFormData] = useState({ name: "", email: "", department: "" });
  const [editId, setEditId] = useState(null);

  const fetchEmployees = async (search = "") => {
    try {
      const res = await axios.get(`${API_URL}?search=${search}`);
      setEmployees(res.data);
    } catch (err) {
      console.error("Error fetching employees:", err);
    }
  };

  useEffect(() => {
    fetchEmployees();
  }, []);

  const handleSearch = () => {
    fetchEmployees(query);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      if (editId) {
        await axios.put(`${API_URL}/${editId}`, formData);
      } else {
        await axios.post(API_URL, formData);
      }
      setFormData({ name: "", email: "", department: "" });
      setEditId(null);
      fetchEmployees();
    } catch (err) {
      alert("Error saving employee. Check if email already exists.");
      console.error(err);
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm("Are you sure you want to delete this employee?")) return;
    try {
      await axios.delete(`${API_URL}/${id}`);
      fetchEmployees();
    } catch (err) {
      console.error("Error deleting employee:", err);
    }
  };

  const handleEdit = (emp) => {
    setEditId(emp.id);
    setFormData({ name: emp.name, email: emp.email, department: emp.department });
    window.scrollTo(0, 0);
  };

  return (
    <div style={{ padding: "20px", maxWidth: 600, margin: "auto" }}>
      <h2>Employee Directory</h2>

      <div style={{ display: "flex", gap: "10px", marginBottom: "20px" }}>
        <input
          type="text"
          placeholder="Search by name or department"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          style={{ flex: 1, padding: 10 }}
        />
        <button onClick={handleSearch} style={{ padding: "10px 20px" }}>
          Search
        </button>
      </div>

      <ul>
        {employees.map((emp) => (
          <li key={emp.id} style={{ marginBottom: "8px" }}>
            <b>{emp.name}</b> - {emp.department} - {emp.email}
            <div style={{ marginTop: 4 }}>
              <button onClick={() => handleEdit(emp)} style={{ marginRight: 10 }}>Edit</button>
              <button onClick={() => handleDelete(emp.id)} style={{ color: "red" }}>Delete</button>
            </div>
          </li>
        ))}
      </ul>

      <hr />

      <h3>{editId ? "Edit Employee" : "Add Employee"}</h3>
      <form onSubmit={handleSubmit}>
        <input
          type="text"
          placeholder="Name"
          required
          value={formData.name}
          onChange={(e) => setFormData({ ...formData, name: e.target.value })}
          style={{ width: "100%", padding: 8, marginBottom: 10 }}
        />
        <input
          type="email"
          placeholder="Email"
          required
          value={formData.email}
          onChange={(e) => setFormData({ ...formData, email: e.target.value })}
          style={{ width: "100%", padding: 8, marginBottom: 10 }}
        />
        <input
          type="text"
          placeholder="Department"
          required
          value={formData.department}
          onChange={(e) => setFormData({ ...formData, department: e.target.value })}
          style={{ width: "100%", padding: 8, marginBottom: 10 }}
        />
        <button type="submit" style={{ padding: 10, width: "100%" }}>
          {editId ? "Update Employee" : "Add Employee"}
        </button>
      </form>
    </div>
  );
}

export default App;
