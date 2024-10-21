App link: http://my-frontend-bucket-unique-123456.s3-website.eu-central-1.amazonaws.com/
# 3-Tier Architecture with AWS (S3, API Gateway, Lambda, DynamoDB)

This project demonstrates a simple 3-tier architecture using AWS services. It includes a frontend hosted on S3, a backend API built using Lambda and API Gateway, and a DynamoDB table for data storage.

## Architecture Overview

1. **Frontend (Presentation Layer)**: A static website hosted in an S3 bucket. The website interacts with the backend API via JavaScript (using Fetch API).
2. **Backend (Application Layer)**: A serverless backend powered by AWS Lambda and exposed via API Gateway. The backend is responsible for processing HTTP GET and POST requests.
3. **Database (Data Layer)**: A DynamoDB table is used to store and retrieve messages submitted by users through the frontend.
