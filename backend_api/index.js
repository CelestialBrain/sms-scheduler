const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const axios = require('axios');
require('dotenv').config();

const app = express();
const port = process.env.PORT || 3000;

app.use(cors());
app.use(bodyParser.json());

// --- eSIM API Integration (Airalo Example) ---
const AIRALO_API_BASE_URL = 'https://api.airalo.com/v2';

app.post('/api/esim/packages', async (req, res) => {
  const { countryCode } = req.body;
  if (!countryCode) {
    return res.status(400).json({ error: 'Country code is required' });
  }

  try {
    const response = await axios.get(`${AIRALO_API_BASE_URL}/packages?country=${countryCode}`, {
      headers: {
        'Authorization': `Bearer ${process.env.AIRALO_API_KEY}`,
      },
    });
    res.json(response.data);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch eSIM packages', details: error.message });
  }
});

app.post('/api/esim/purchase', async (req, res) => {
  const { packageId, email } = req.body;
  if (!packageId || !email) {
    return res.status(400).json({ error: 'Package ID and email are required' });
  }

  try {
    const response = await axios.post(`${AIRALO_API_BASE_URL}/purchase`, {
      package_id: packageId,
      email: email,
    }, {
      headers: {
        'Authorization': `Bearer ${process.env.AIRALO_API_KEY}`,
        'Content-Type': 'application/json',
      },
    });
    res.json(response.data);
  } catch (error) {
    res.status(500).json({ error: 'Failed to purchase eSIM', details: error.message });
  }
});

// --- Load API Integration (Generic Example) ---
const LOAD_API_BASE_URL = 'https://api.loadprovider.com';

app.post('/api/load/purchase', async (req, res) => {
  const { productCode, mobileNumber } = req.body;
  if (!productCode || !mobileNumber) {
    return res.status(400).json({ error: 'Product code and mobile number are required' });
  }

  const rrn = `${process.env.LOAD_COMPANY_PREFIX}${Date.now()}`;

  try {
    const response = await axios.post(`${LOAD_API_BASE_URL}/sell`, {
      uid: process.env.LOAD_API_UID,
      password: process.env.LOAD_API_PASSWORD,
      pcode: productCode,
      to: mobileNumber,
      rrn: rrn,
    }, {
      headers: {
        'Content-Type': 'application/json',
      },
    });
    res.json(response.data);
  } catch (error) {
    res.status(500).json({ error: 'Failed to purchase load', details: error.message });
  }
});

app.listen(port, () => {
  console.log(`Server is running on port ${port}`);
});
