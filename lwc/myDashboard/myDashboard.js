import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getMyDashboardKPIs from '@salesforce/apex/BookingController.getMyDashboardKPIs';
import getMyBookings from '@salesforce/apex/BookingController.getMyBookings';
import getMyTestDrives from '@salesforce/apex/BookingController.getMyTestDrives';
import getMyContact from '@salesforce/apex/BookingController.getMyContact';

const STATUS_CLASSES = {
    'Pending':        'status-badge pending',
    'Under Approval': 'status-badge approval',
    'Approved':       'status-badge approved',
    'Delivered':      'status-badge delivered',
    'Cancelled':      'status-badge cancelled',
    'Requested':      'status-badge pending',
    'Confirmed':      'status-badge approved',
    'Completed':      'status-badge delivered'
};

export default class MyDashboard extends LightningElement {
    _wiredKPIsResult;
    _wiredBookingsResult;
    _wiredTDsResult;
    @track kpis = { totalBookings: 0, approvedBookings: 0, totalTestDrives: 0, pendingPayments: 0 };
    @track recentBookings = [];
    @track recentTestDrives = [];
    @track loadingBookings = true;
    @track loadingTestDrives = true;
    @track userName = 'Customer';

    get siteBase() {
        const path = window.location.pathname;
        const match = path.match(/^\/([^\/]+)/);
        const prefix = match ? match[1] : 'tatasite';
        return window.location.origin + '/' + prefix;
    }

    navigate(page) { window.location.href = `${this.siteBase}/${page}`; }

    get noBookings()   { return !this.loadingBookings   && this.recentBookings.length   === 0; }
    get noTestDrives() { return !this.loadingTestDrives && this.recentTestDrives.length === 0; }

    @wire(getMyContact)
    wiredContact({ data, error }) {
        if (data) this.userName = data.FirstName || 'Customer';
        if (error) console.error('Contact error:', error);
    }

    @wire(getMyDashboardKPIs)
    wiredKPIs(result) {
        this._wiredKPIsResult = result;
        if (result.data) this.kpis = result.data;
        if (result.error) console.error('KPI error:', result.error);
    }

    @wire(getMyBookings)
    wiredBookings(result) {
        this._wiredBookingsResult = result;
        this.loadingBookings = false;
        if (result.data) {
            const data = result.data;
            this.recentBookings = data.slice(0, 3).map(b => ({
                ...b,
                statusClass: STATUS_CLASSES[b.Status__c] || 'status-badge',
                modelName:   b.Model__r   ? b.Model__r.Name   : '—',
                variantName: b.Variant__r ? b.Variant__r.Name : '—'
            }));
        }
        if (result.error) console.error('Bookings error:', result.error);
    }

    @wire(getMyTestDrives)
    wiredTestDrives(result) {
        this._wiredTDsResult = result;
        this.loadingTestDrives = false;
        if (result.data) {
            const data = result.data;
            this.recentTestDrives = data.slice(0, 3).map(td => ({
                ...td,
                statusClass: STATUS_CLASSES[td.Status__c] || 'status-badge',
                modelName:   td.Model__r   ? td.Model__r.Name   : '—',
                variantName: td.Variant__r ? td.Variant__r.Name : '—'
            }));
        }
        if (result.error) console.error('Test drives error:', result.error);
    }

    goTestDrive()  { this.navigate('book-test-drive'); }
    goBookings()   { this.navigate('my-bookings'); }
    goTestDrives() { this.navigate('my-test-drives'); }
    goProfile()    { this.navigate('my-profile'); }
    goModels()     { this.navigate('models'); }
}