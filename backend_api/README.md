# SchedulerSMS Backend API

A secure backend API for handling eSIM and load purchases for the Flutter SchedulerSMS package.

## Features

- **eSIM Integration**: Purchase and manage eSIMs via Airalo API
- **Load Purchases**: Buy prepaid load for Philippine networks
- **Secure**: API keys and credentials are stored server-side
- **RESTful**: Simple REST API endpoints

## Setup

### 1. Install Dependencies

```bash
npm install
```

### 2. Configure Environment Variables

Copy `.env.example` to `.env` and fill in your credentials:

```bash
cp .env.example .env
```

Edit `.env`:

```
PORT=3000
AIRALO_API_KEY=your_airalo_api_key
LOAD_API_UID=your_load_uid
LOAD_API_PASSWORD=your_load_password
LOAD_COMPANY_PREFIX=ABC
```

### 3. Start the Server

**Development:**
```bash
npm run dev
```

**Production:**
```bash
npm start
```

## API Endpoints

### eSIM Endpoints

#### Get Available Packages

```http
POST /api/esim/packages
Content-Type: application/json

{
  "countryCode": "PH"
}
```

**Response:**
```json
{
  "packages": [
    {
      "id": "ph-1gb-7days",
      "name": "Philippines 1GB - 7 Days",
      "country_code": "PH",
      "country_name": "Philippines",
      "price": 4.50,
      "currency": "USD",
      "data_amount": 1024,
      "validity_days": 7
    }
  ]
}
```

#### Purchase eSIM

```http
POST /api/esim/purchase
Content-Type: application/json

{
  "packageId": "ph-1gb-7days",
  "email": "user@example.com"
}
```

**Response:**
```json
{
  "order_id": "ORD123456",
  "package_id": "ph-1gb-7days",
  "status": "completed",
  "qr_code": "data:image/png;base64,...",
  "activation_code": "LPA:1$...",
  "iccid": "8901234567890123456"
}
```

### Load Endpoints

#### Purchase Load

```http
POST /api/load/purchase
Content-Type: application/json

{
  "productCode": "SMART100",
  "mobileNumber": "09171234567"
}
```

**Response:**
```json
{
  "status": "success",
  "message": "Load purchased successfully",
  "transaction_id": "TXN123456",
  "rrn": "ABC1234567890",
  "timestamp": "2024-11-06T12:00:00Z"
}
```

## Deployment

### Deploy to Heroku

1. Create a Heroku app:
```bash
heroku create your-app-name
```

2. Set environment variables:
```bash
heroku config:set AIRALO_API_KEY=your_key
heroku config:set LOAD_API_UID=your_uid
heroku config:set LOAD_API_PASSWORD=your_password
heroku config:set LOAD_COMPANY_PREFIX=ABC
```

3. Deploy:
```bash
git push heroku main
```

### Deploy to AWS/DigitalOcean

1. Set up a Node.js server
2. Clone the repository
3. Install dependencies: `npm install`
4. Configure environment variables
5. Use PM2 to run the server: `pm2 start index.js`

## Security Considerations

- **HTTPS**: Always use HTTPS in production
- **Authentication**: Add authentication middleware to protect endpoints
- **Rate Limiting**: Implement rate limiting to prevent abuse
- **Input Validation**: Validate all user inputs
- **API Keys**: Never expose API keys in client-side code

## Error Handling

All endpoints return appropriate HTTP status codes:

- `200`: Success
- `400`: Bad Request (missing or invalid parameters)
- `500`: Internal Server Error

Error response format:
```json
{
  "error": "Error message",
  "details": "Additional details"
}
```

## License

MIT License
