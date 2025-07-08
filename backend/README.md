curl -X POST http://13.235.245.253:5000/api/employees \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Charlie Brown",
    "email": "charlie.brown@example.com",
    "department": "Finance"
}'
curl "http://13.235.245.253:5000/api/employees?search=charlie"
