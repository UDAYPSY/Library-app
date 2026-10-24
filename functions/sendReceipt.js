const functions = require('firebase-functions');
const admin = require('firebase-admin');

/**
 * Task 3.4 — Email Receipt on Payment (SendGrid Trigger)
 * Automatically triggers on new payment records in /libraries/{libraryId}/payments/{paymentId}
 */
exports.sendPaymentReceiptEmail = functions.firestore
  .document('libraries/{libraryId}/payments/{paymentId}')
  .onCreate(async (snap, context) => {
    const payment = snap.data();
    const studentEmail = payment.student_email;

    if (!studentEmail || !studentEmail.includes('@')) {
      console.log('No valid student email provided for payment receipt.');
      return null;
    }

    const apiKey = process.env.SENDGRID_API_KEY;
    if (!apiKey) {
      console.log('SENDGRID_API_KEY environment variable not configured.');
      return null;
    }

    const sgMail = require('@sendgrid/mail');
    sgMail.setApiKey(apiKey);

    const msg = {
      to: studentEmail,
      from: 'manageyourlib@gmail.com',
      subject: `Payment Receipt — ₹${payment.amount} (TrackMyLibrary)`,
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 24px; border: 1px solid #e2e8f0; border-radius: 12px;">
          <h2 style="color: #0f766e; margin-top: 0;">Payment Received!</h2>
          <p>Dear <strong>${payment.student_name || 'Student'}</strong>,</p>
          <p>Thank you for your payment. Your library seat renewal details are below:</p>
          <table style="width: 100%; border-collapse: collapse; margin: 16px 0;">
            <tr style="border-bottom: 1px solid #eee;"><td style="padding: 8px 0; color: #64748b;">Amount Paid:</td><td style="padding: 8px 0; font-weight: bold; color: #0f172a;">₹${payment.amount}</td></tr>
            <tr style="border-bottom: 1px solid #eee;"><td style="padding: 8px 0; color: #64748b;">Payment Mode:</td><td style="padding: 8px 0; font-weight: bold;">${payment.payment_mode || 'Cash/UPI'}</td></tr>
            <tr style="border-bottom: 1px solid #eee;"><td style="padding: 8px 0; color: #64748b;">Shift:</td><td style="padding: 8px 0;">${payment.shift || 'General'}</td></tr>
            <tr style="border-bottom: 1px solid #eee;"><td style="padding: 8px 0; color: #64748b;">Valid Until:</td><td style="padding: 8px 0; font-weight: bold; color: #16a34a;">${payment.valid_until || 'N/A'}</td></tr>
          </table>
          <p style="font-size: 12px; color: #94a3b8; margin-top: 24px;">TrackMyLibrary Digital Management • Helpline: +91 9457464850</p>
        </div>
      `,
    };

    try {
      await sgMail.send(msg);
      console.log(`Receipt sent to ${studentEmail} for payment ${context.params.paymentId}`);
    } catch (error) {
      console.error('Error sending receipt email:', error);
    }
    return null;
  });
