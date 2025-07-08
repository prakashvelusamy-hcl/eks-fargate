# config.py

import os
import boto3
import json

def get_secret(secret_name, region_name="ap-south-1"):
    client = boto3.client("secretsmanager", region_name=region_name)
    response = client.get_secret_value(SecretId=secret_name)
    return json.loads(response['SecretString'])

# Main RDS credentials secret (managed by RDS, can't be edited)
rds_secret = get_secret(os.getenv("RDS_SECRET_NAME", "rds!db-71168077-35cc-4ad7-97fe-b2b67b9696ae"))

# Additional custom secret with host and dbname
app_secret = get_secret(os.getenv("APP_SECRET_NAME", "my-db-host-secret"))

DB_USERNAME = rds_secret["username"]
DB_PASSWORD = rds_secret["password"]
DB_HOST = app_secret["host"]
DB_NAME = app_secret["dbname"]

SQLALCHEMY_DATABASE_URI = f"mysql+pymysql://{DB_USERNAME}:{DB_PASSWORD}@{DB_HOST}/{DB_NAME}"
SQLALCHEMY_TRACK_MODIFICATIONS = False


