import { LightningElement } from 'lwc';

export default class PartnerFooter extends LightningElement {
    get currentYear() { return new Date().getFullYear(); }

    get siteBase() {
        const path = window.location.pathname;
        const match = path.match(/^\/([^\/]+)/);
        return window.location.origin + '/' + (match ? match[1] : 'tatadealers');
    }

    navigate(page) { window.location.href = `${this.siteBase}/${page}`; }

    goDashboard()  { this.navigate('dashboard'); }
    goLeads()      { this.navigate('leads'); }
    goTestDrives() { this.navigate('test-drives'); }
    goBookings()   { this.navigate('bookings'); }
    goCustomers()  { this.navigate('customers'); }
}