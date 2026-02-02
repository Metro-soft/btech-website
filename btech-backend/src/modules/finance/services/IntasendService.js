const axios = require('axios');

class IntasendService {
  constructor() {
    this.publishableKey = process.env.INTASEND_PUBLISHABLE_KEY;
    this.secretKey = process.env.INTASEND_SECRET_KEY;
    this.isSandbox = process.env.INTASEND_ENV === 'sandbox'; // Updated check
    
    this.baseUrl = this.isSandbox 
      ? 'https://sandbox.intasend.com/api/v1' 
      : 'https://payment.intasend.com/api/v1';
  }

  async initiateCheckout(amount, currency = 'KES', email, phone, apiRef = 'API Request') {
    try {
      const payload = {
        public_key: this.publishableKey,
        amount: amount,
        currency: currency,
        email: email,
        phone_number: phone,
        api_ref: apiRef,
        redirect_url: `${process.env.APP_URL || 'https://btech-website.com'}/payment-complete`, 
      };

      const response = await axios.post(`${this.baseUrl}/checkout/`, payload);
      return response.data;
    } catch (error) {
      console.error('IntaSend Checkout Error:', error.response ? error.response.data : error.message);
      throw new Error(error.response?.data?.errors?.[0]?.detail || 'Failed to initiate IntaSend checkout');
    }
  }

  async verifyTransaction(invoiceId) {
    try {
      const response = await axios.post(`${this.baseUrl}/checkout/status/`, {
        public_key: this.publishableKey,
        invoice_id: invoiceId
      });
      return response.data;
    } catch (error) {
       console.error('IntaSend Verification Error:', error.response ? error.response.data : error.message);
       throw error;
    }
  }
}

module.exports = new IntasendService();
