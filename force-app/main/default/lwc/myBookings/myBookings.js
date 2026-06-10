import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getMyBookings from '@salesforce/apex/BookingController.getMyBookings';
import getPaymentsByBooking from '@salesforce/apex/BookingController.getPaymentsByBooking';
import getBookingReceipt from '@salesforce/apex/BookingController.getBookingReceipt';
import processPayment from '@salesforce/apex/PaymentController.processPayment';

const fmt = n => n != null ? new Intl.NumberFormat('en-IN').format(n) : '0';
const pct = (paid, total) => total > 0 ? Math.min(100, Math.round((paid / total) * 100)) : 0;

const stepClass = (active, done) => {
    if (done)   return 'step done';
    if (active) return 'step active';
    return 'step';
};

const lineClass = done => done ? 'step-line done' : 'step-line';

function enrichBooking(b) {
    const status      = b.Status__c;
    const total       = b.Total_Booking_Amount__c || 0;
    const paid        = b.Total_Paid__c || 0;
    const rem         = Math.max(0, total - paid);
    const pctVal      = pct(paid, total);
    const isApproved  = status === 'Approved';
    const isDelivered = status === 'Delivered';
    const isCancelled = status === 'Cancelled';
    const canPay      = isApproved && rem > 0;
    const modelName   = b.Model__r   ? b.Model__r.Name   : '—';
    const variantName = b.Variant__r ? b.Variant__r.Name : '—';

    const step1done = ['Under Approval','Approved','Delivered'].includes(status);
    const step2done = ['Approved','Delivered'].includes(status);
    const step3done = isDelivered && paid >= total;
    const step4done = isDelivered;

    const statusMap = {
        'Pending':        'status-badge pending',
        'Under Approval': 'status-badge approval',
        'Approved':       'status-badge approved',
        'Delivered':      'status-badge delivered',
        'Cancelled':      'status-badge cancelled'
    };

    return {
        ...b,
        statusClass:            statusMap[status] || 'status-badge',
        totalAmountFormatted:   fmt(total),
        totalPaidFormatted:     fmt(paid),
        remainingFormatted:     fmt(rem),
        remainingRaw:           rem,
        paymentPercent:         pctVal,
        ppStyle:                `width: ${pctVal}%`,
        showPaymentBar:         total > 0 && !isCancelled,
        canPay,
        modelName,
        variantName,
        isDelivered,
        step1Class:             stepClass(status === 'Pending', step1done),
        step2Class:             stepClass(status === 'Under Approval', step2done),
        step3Class:             stepClass(isApproved && !isDelivered, step3done),
        step4Class:             stepClass(isDelivered, false),
        lineClass12:            lineClass(step1done),
        lineClass23:            lineClass(step2done),
        lineClass34:            lineClass(step3done),
        showPayments:           false,
        showPaymentForm:        false,
        loadingPayments:        false,
        noPayments:             false,
        hasPayments:            false,
        payments:               [],
        paymentAmount:          rem,
        paymentMethod:          '',
        paymentError:           '',
        paymentSubmitting:      false
    };
}

export default class MyBookings extends LightningElement {
    @track allBookings = [];
    _wiredBookingsResult;
    @track filteredBookings = [];
    @track loading = true;
    @track activeFilter = 'all';

    get siteBase() {
        const path = window.location.pathname;
        const match = path.match(/^\/([^\/]+)/);
        const prefix = match ? match[1] : 'tatasite';
        return window.location.origin + '/' + prefix;
    }

    navigate(page) { window.location.href = `${this.siteBase}/${page}`; }

    get isEmpty() { return !this.loading && this.filteredBookings.length === 0; }

    @wire(getMyBookings)
    wiredBookings(result) {
        this._wiredBookingsResult = result;
        this.loading = false;
        if (result.data) {
            this.allBookings = result.data.map(enrichBooking);
            this.applyFilter();
        }
        if (result.error) console.error('Bookings error:', result.error);
    }

    handleFilter(event) {
        this.activeFilter = event.target.value;
        this.applyFilter();
    }

    applyFilter() {
        this.filteredBookings = this.activeFilter === 'all'
            ? [...this.allBookings]
            : this.allBookings.filter(b => b.Status__c === this.activeFilter);
    }

    updateBooking(id, patch) {
        this.allBookings = this.allBookings.map(b =>
            b.Id === id ? { ...b, ...patch } : b
        );
        this.applyFilter();
    }

    togglePayments(event) {
        const id = event.currentTarget.dataset.id;
        const booking = this.filteredBookings.find(b => b.Id === id);
        if (!booking) return;

        if (!booking.showPayments && booking.payments.length === 0) {
            this.updateBooking(id, { showPayments: true, loadingPayments: true });
            getPaymentsByBooking({ bookingId: id })
                .then(data => {
                    const payments = data.map(p => ({
                        ...p,
                        amountFormatted: fmt(p.Payment_Amount__c),
                        statusClass: p.Status__c === 'Completed'
                            ? 'pay-status completed' : 'pay-status'
                    }));
                    this.updateBooking(id, {
                        loadingPayments: false,
                        payments,
                        hasPayments: payments.length > 0,
                        noPayments:  payments.length === 0
                    });
                })
                .catch(() => this.updateBooking(id, {
                    loadingPayments: false,
                    noPayments: true
                }));
        } else {
            this.updateBooking(id, { showPayments: !booking.showPayments });
        }
    }

    openPayment(event) {
        const id = event.currentTarget.dataset.id;
        this.updateBooking(id, { showPaymentForm: true });
    }

    cancelPayment(event) {
        const id = event.currentTarget.dataset.id;
        this.updateBooking(id, { showPaymentForm: false, paymentError: '' });
    }

    handlePaymentAmount(event) {
        const id  = event.currentTarget.dataset.id;
        const val = parseFloat(event.target.value) || 0;
        this.updateBooking(id, { paymentAmount: val });
    }

    handlePaymentMethod(event) {
        const id = event.currentTarget.dataset.id;
        this.updateBooking(id, { paymentMethod: event.target.value });
    }

    submitPayment(event) {
        const id = event.currentTarget.dataset.id;
        const b  = this.filteredBookings.find(bk => bk.Id === id);
        if (!b) return;
        if (!b.paymentMethod) {
            this.updateBooking(id, { paymentError: 'Please select a payment method' });
            return;
        }
        if (!b.paymentAmount || b.paymentAmount <= 0) {
            this.updateBooking(id, { paymentError: 'Please enter a valid amount' });
            return;
        }
        this.updateBooking(id, { paymentSubmitting: true, paymentError: '' });
        processPayment({
            bookingId:     id,
            paymentAmount: b.paymentAmount,
            paymentMethod: b.paymentMethod
        })
        .then(() => refreshApex(this._wiredBookingsResult))
        .then(() => { this.applyFilter(); })
        .catch(err => {
            this.updateBooking(id, {
                paymentSubmitting: false,
                paymentError: err.body
                    ? err.body.message
                    : 'Payment failed. Please try again.'
            });
        });
    }

    downloadReceipt(event) {
        const id = event.currentTarget.dataset.id;
        getBookingReceipt({ bookingId: id })
            .then(data => {
                const b = data.booking;
                const payments = data.payments || [];
                const customerName = b.Contact__r
                    ? (b.Contact__r.FirstName || '') + ' ' + (b.Contact__r.LastName || '')
                    : '—';
                const modelName   = b.Model__r   ? b.Model__r.Name   : '—';
                const variantName = b.Variant__r ? b.Variant__r.Name : '—';

                const html = `
                <html><head><title>Booking Receipt</title>
                <style>
                    body{font-family:Arial,sans-serif;padding:40px;color:#0f172a}
                    h1{font-size:28px;font-weight:800;margin-bottom:4px}
                    .sub{color:#64748b;margin-bottom:24px}
                    table{width:100%;border-collapse:collapse;margin-bottom:20px}
                    th,td{padding:10px 14px;text-align:left;border-bottom:1px solid #e2e8f0;font-size:14px}
                    th{background:#f8fafc;font-weight:700;color:#374151}
                    .footer{margin-top:32px;font-size:12px;color:#94a3b8;text-align:center}
                </style></head><body>
                <h1>Booking Receipt</h1>
                <p class="sub">Tata Motors Customer Portal</p>
                <table>
                    <tr><th>Booking Number</th><td>${b.Booking_Number__c}</td></tr>
                    <tr><th>Customer</th><td>${customerName}</td></tr>
                    <tr><th>Model</th><td>${modelName}</td></tr>
                    <tr><th>Variant</th><td>${variantName}</td></tr>
                    <tr><th>Booking Date</th><td>${b.Booking_Date__c}</td></tr>
                    <tr><th>Expected Delivery</th><td>${b.Expected_Delivery_Date__c}</td></tr>
                    <tr><th>Total Amount</th><td>₹${new Intl.NumberFormat('en-IN').format(b.Total_Booking_Amount__c)}</td></tr>
                    <tr><th>Total Paid</th><td>₹${new Intl.NumberFormat('en-IN').format(b.Total_Paid__c || 0)}</td></tr>
                    <tr><th>Status</th><td>${b.Status__c}</td></tr>
                </table>
                <h3>Payment History</h3>
                <table>
                    <tr><th>Date</th><th>Method</th><th>Amount</th><th>Status</th></tr>
                    ${payments.map(p => `
                    <tr>
                        <td>${p.Payment_Date__c}</td>
                        <td>${p.Payment_Method__c}</td>
                        <td>₹${new Intl.NumberFormat('en-IN').format(p.Payment_Amount__c)}</td>
                        <td>${p.Status__c}</td>
                    </tr>`).join('')}
                </table>
                <p class="footer">Generated by Tata Motors Customer Portal — ${new Date().toLocaleDateString('en-IN')}</p>
                </body></html>`;

                const w = window.open('', '_blank');
                w.document.write(html);
                w.document.close();
                w.print();
            })
            .catch(err => console.error('Receipt error:', err));
    }

    goDashboard() { this.navigate('my-dashboard'); }
    goModels()    { this.navigate('models'); }
}