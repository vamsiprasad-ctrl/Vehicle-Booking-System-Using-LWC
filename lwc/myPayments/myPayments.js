import { LightningElement, track, wire } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import getRemainingBalance from '@salesforce/apex/PaymentController.getRemainingBalance';
import processPayment from '@salesforce/apex/PaymentController.processPayment';

const formatPrice = p => {
    if (!p) return '—';
    if (p >= 10000000) return '₹' + (p / 10000000).toFixed(2) + ' Cr';
    if (p >= 100000) return '₹' + (p / 100000).toFixed(2) + ' L';
    return '₹' + p.toLocaleString();
};

export default class MyPayments extends NavigationMixin(LightningElement) {
    @track bookingId = '';
    @track modelName = '';
    @track variantName = '';
    @track totalAmount = 0;
    @track paidAmount = 0;
    @track remainingBalance = 0;

    @track isLoading = false;
    @track isProcessing = false;
    @track paymentSuccess = false;
    @track error = '';

    @track paymentMethod = 'Credit Card';
    @track paymentAmount = 0;

    formData = {
        cardNumber: '',
        cardName: '',
        expiryDate: '',
        cvv: ''
    };

    @track errors = {};

    // ✅ Read URL parameters
    @wire(CurrentPageReference)
    handlePageRef(pageRef) {
        if (!pageRef || !pageRef.state) return;

        const bid = pageRef.state.bookingId || '';
        const amount = pageRef.state.amount || 0;
        const paid = pageRef.state.paid || 0;
        const modelName = pageRef.state.modelName || '';
        const variantName = pageRef.state.variantName || '';

        if (bid) {
            this.bookingId = bid;
            this.modelName = modelName;
            this.variantName = variantName;
            this.totalAmount = amount;
            this.paidAmount = paid;
            this.remainingBalance = (amount || 0) - (paid || 0);
            this.paymentAmount = this.remainingBalance;
            this.loadBalance();
        }
    }

    get totalFormatted() {
        return formatPrice(this.totalAmount);
    }

    get paidFormatted() {
        return formatPrice(this.paidAmount);
    }

    get remainingFormatted() {
        return formatPrice(this.remainingBalance);
    }

    get paymentAmountFormatted() {
        return formatPrice(this.paymentAmount);
    }

    get isFullPayment() {
        return this.paymentAmount >= this.remainingBalance;
    }

    get progressPercent() {
        return this.totalAmount ? Math.round((this.paidAmount / this.totalAmount) * 100) : 0;
    }

    get isCardMethod() {
        return this.paymentMethod === 'Credit Card' || this.paymentMethod === 'Debit Card';
    }

    loadBalance() {
        if (!this.bookingId) return;
        
        getRemainingBalance({ bookingId: this.bookingId })
            .then(balance => {
                this.remainingBalance = balance || 0;
                if (this.paymentAmount === 0) {
                    this.paymentAmount = this.remainingBalance;
                }
            })
            .catch(err => console.error('Error loading balance:', err));
    }

    handlePaymentMethodChange(e) {
        this.paymentMethod = e.target.value;
        this.errors = {};
    }

    handleAmountChange(e) {
        const amount = parseFloat(e.target.value) || 0;
        if (amount > this.remainingBalance) {
            this.paymentAmount = this.remainingBalance;
        } else if (amount < 0) {
            this.paymentAmount = 0;
        } else {
            this.paymentAmount = amount;
        }
    }

    handleCardInput(e) {
        this.formData[e.target.name] = e.target.value;
    }

    validateForm() {
        const e = {};
        
        if (this.paymentMethod === 'Credit Card' || this.paymentMethod === 'Debit Card') {
            if (!this.formData.cardNumber) {
                e.cardNumber = 'Card number required';
            } else if (this.formData.cardNumber.replace(/\s/g, '').length !== 16) {
                e.cardNumber = 'Invalid card number (16 digits)';
            }
            
            if (!this.formData.cardName) {
                e.cardName = 'Cardholder name required';
            }
            
            if (!this.formData.expiryDate) {
                e.expiryDate = 'Expiry date required';
            }
            
            if (!this.formData.cvv) {
                e.cvv = 'CVV required';
            } else if (!/^\d{3,4}$/.test(this.formData.cvv)) {
                e.cvv = 'Invalid CVV';
            }
        }

        if (this.paymentAmount <= 0) {
            e.amount = 'Payment amount must be greater than 0';
        }

        this.errors = e;
        return Object.keys(e).length === 0;
    }

    async handleSubmit() {
        if (!this.validateForm()) return;

        this.isProcessing = true;
        this.error = '';

        try {
            const result = await processPayment({
                bookingId: this.bookingId,
                paymentAmount: this.paymentAmount,
                paymentMethod: this.paymentMethod
            });

            this.paymentSuccess = true;
            this.paidAmount += this.paymentAmount;
            this.remainingBalance = this.remainingBalance - this.paymentAmount;

        } catch (err) {
            this.error = err.body?.message || 'Payment processing failed. Please try again.';
            console.error('Payment error:', err);
        }

        this.isProcessing = false;
    }

    handleGoBack() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: { name: 'My_Bookings__c' }
        });
    }
}