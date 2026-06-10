import { LightningElement, api, track } from 'lwc';
import { createRecord } from 'lightning/uiRecordApi';
import PAYMENT_OBJECT
    from '@salesforce/schema/Payment__c';
import BOOKING_FIELD
    from '@salesforce/schema/Payment__c.Booking__c';
import AMOUNT_FIELD
    from '@salesforce/schema/Payment__c.Payment_Amount__c';
import DATE_FIELD
    from '@salesforce/schema/Payment__c.Payment_Date__c';
import METHOD_FIELD
    from '@salesforce/schema/Payment__c.Payment_Method__c';
import STATUS_FIELD
    from '@salesforce/schema/Payment__c.Status__c';

export default class PaymentEntry extends LightningElement {
    @api bookingId;
    @track success      = false;
    @track isSubmitting = false;
    @track error        = '';

    formData = { amount: '', paymentDate: '', method: '' };

    methodOptions = [
        { label: 'Cash',          value: 'Cash' },
        { label: 'UPI',           value: 'UPI' },
        { label: 'Card',          value: 'Card' },
        { label: 'Loan',          value: 'Loan' },
        { label: 'Bank Transfer', value: 'Bank Transfer' }
    ];

    handleChange(event) {
        const field = event.target.dataset.field;
        this.formData[field] = event.detail.value;
        this.error = '';
    }

    async handleSubmit() {
        const { amount, paymentDate, method } = this.formData;

        if (!amount || amount <= 0) {
            this.error = 'Please enter a valid amount';
            return;
        }
        if (!paymentDate) {
            this.error = 'Please select payment date';
            return;
        }
        if (!method) {
            this.error = 'Please select payment method';
            return;
        }

        this.isSubmitting = true;

        const fields = {};
        fields[BOOKING_FIELD.fieldApiName] = this.bookingId;
        fields[AMOUNT_FIELD.fieldApiName]  = amount;
        fields[DATE_FIELD.fieldApiName]    = paymentDate;
        fields[METHOD_FIELD.fieldApiName]  = method;
        fields[STATUS_FIELD.fieldApiName]  = 'Pending';

        try {
            await createRecord({
                apiName: PAYMENT_OBJECT.objectApiName,
                fields
            });
            this.success = true;
        } catch (error) {
            this.error = error.body
                ? error.body.message
                : 'Error recording payment';
        } finally {
            this.isSubmitting = false;
        }
    }
}