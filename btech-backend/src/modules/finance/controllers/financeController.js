const Transaction = require('../models/Transaction');
const Wallet = require('../models/Wallet');
const mongoose = require('mongoose');
const intasendService = require('../services/IntasendService');

exports.getWallet = async (req, res) => {
  try {
    // Auth middleware attaches req.user._id or req.user.id
    const userId = req.user._id || req.user.id; 
    let wallet = await Wallet.findOne({ user: userId });
    if (!wallet) {
      wallet = await Wallet.create({ user: userId });
    }
    const transactions = await Transaction.find({ user: userId }).sort({ createdAt: -1 }).limit(10);
    res.json({
      balance: wallet.balance,
      transactions: transactions
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

exports.deposit = async (req, res) => {
  const { amount, phone, email } = req.body;
  
  if (!amount) {
      return res.status(400).json({ message: 'Amount is required' });
  }

  const userId = req.user._id || req.user.id;
  const contactEmail = email || req.user.email || 'customer@example.com'; 
  const contactPhone = phone || req.user.phone || '254700000000';

  const idempotencyKey = req.headers['idempotency-key'] || `DEP-${Date.now()}`;

  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    const existingTxn = await Transaction.findOne({ reference: idempotencyKey }).session(session);
    if (existingTxn) {
      await session.abortTransaction();
      return res.status(409).json({ message: 'Duplicate transaction detected', transaction: existingTxn });
    }

    const transaction = await Transaction.create([{
      user: userId,
      type: 'DEPOSIT',
      amount: amount,
      method: 'INTASEND', 
      status: 'PENDING',
      reference: idempotencyKey, 
      metadata: { phone: contactPhone, email: contactEmail }
    }], { session: session });

    await session.commitTransaction();

    try {
        const checkoutResponse = await intasendService.initiateCheckout(
            amount, 
            'KES', 
            contactEmail, 
            contactPhone, 
            idempotencyKey 
        );
        
        await Transaction.findByIdAndUpdate(transaction[0]._id, {
            $set: { 
                'metadata.invoiceId': checkoutResponse.id,
                'metadata.checkoutUrl': checkoutResponse.url 
            }
        });

        res.json({ 
            message: 'Checkout initiated successfully', 
            transactionId: transaction[0]._id,
            url: checkoutResponse.url,
            invoiceId: checkoutResponse.id
        });

    } catch (isError) {
        await Transaction.findByIdAndUpdate(transaction[0]._id, { status: 'FAILED', metadata: { error: isError.message } });
        res.status(502).json({ message: 'IntaSend Initiation failed', error: isError.message });
    }

  } catch (error) {
    if (session.inTransaction()) {
        await session.abortTransaction();
    }
    res.status(500).json({ message: 'Deposit failed', error: error.message });
  } finally {
    session.endSession();
  }
};

exports.handleIntasendWebhook = async (req, res) => {
    try {
        const payload = req.body;
        const { invoice_id, state, api_ref, failed_reason, failed_message } = payload;
        
        console.log(`IntaSend Webhook: ${invoice_id} [${state}]`);

        if (!invoice_id) {
            return res.status(400).json({ message: 'Invalid Payload' });
        }

        const transaction = await Transaction.findOne({ 
             $or: [
                 { 'metadata.invoiceId': invoice_id },
                 { reference: api_ref } 
             ]
        });

        if (!transaction) {
            console.warn(`Transaction not found for Invoice: ${invoice_id}`);
            return res.status(200).json({ message: 'Transaction not found, ignored.' }); 
        }

        if (transaction.status === 'COMPLETED') {
             return res.status(200).json({ message: 'Already COMPLETED' });
        }

        if (state === 'COMPLETE') {
            const session = await mongoose.startSession();
            session.startTransaction();
            try {
                transaction.status = 'COMPLETED';
                transaction.metadata.webhookData = payload;
                await transaction.save({ session });

                await Wallet.findOneAndUpdate(
                    { user: transaction.user },
                    { $inc: { balance: transaction.amount } },
                    { session, upsert: true }
                );

                await session.commitTransaction();
                console.log(`Payment Confirmed: ${invoice_id}`);
            } catch (err) {
                await session.abortTransaction();
                console.error('Error processing webhook transaction', err);
            } finally {
                session.endSession();
            }
        } else if (state === 'FAILED') {
            transaction.status = 'FAILED';
            transaction.metadata.webhookData = payload;
            transaction.metadata.failureReason = failed_reason || failed_message;
            await transaction.save();
            console.log(`Payment Failed: ${invoice_id}`);
        } else {
            transaction.metadata.webhookData = payload;
            await transaction.save();
        }

        res.json({ status: 'OK' });

    } catch (error) {
        console.error('Webhook Error', error);
        res.status(500).json({ message: 'Error' });
    }
};
