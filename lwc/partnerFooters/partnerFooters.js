import { LightningElement } from 'lwc';
export default class PartnerFooters extends LightningElement {
    get year() { return new Date().getFullYear(); }
    get siteBase() {
        const m = window.location.pathname.match(/^\/([^\/]+)/);
        return window.location.origin + '/' + (m ? m[1] : 'tatadealers');
    }
    nav(p) { window.location.href = `${this.siteBase}/${p}`; }
    goDashboard()  { this.nav('dashboard'); }
    goLeads()      { this.nav('leads'); }
    goTestDrives() { this.nav('test-drives'); }
    goBookings()   { this.nav('bookings'); }
    goCustomers()  { this.nav('customers'); }
}