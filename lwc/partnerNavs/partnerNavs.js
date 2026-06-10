import { LightningElement, wire, track } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import getCurrentUserRole from '@salesforce/apex/PartnerDashboardController.getCurrentUserRole';
import getCurrentUserName from '@salesforce/apex/PartnerDashboardController.getCurrentUserName';
import getPendingApprovals from '@salesforce/apex/PartnerBookingController.getPendingApprovals';

export default class PartnerNavs extends NavigationMixin(LightningElement) {
    @track currentPage  = '';
    @track showDropdown = false;
    @track showMobile   = false;
    @track userRole     = '';
    @track userName     = '';
    @track pendingCount = 0;

    get isManager()   { return this.userRole === 'Manager'; }
    get hasPending()  { return this.pendingCount > 0; }
    get userInitial() { return this.userName ? this.userName.charAt(0).toUpperCase() : 'U'; }

    get siteBase() {
        const m = window.location.pathname.match(/^\/([^\/]+)/);
        return window.location.origin + '/' + (m ? m[1] : 'partnerportal');
    }

    get sitePrefix() {
        const m = window.location.pathname.match(/^\/([^\/]+)/);
        return m ? m[1] : 'partnerportal';
    }

    nav(page) {
        window.location.href = `${this.siteBase}/${page}`;
        this.showMobile   = false;
        this.showDropdown = false;
    }

    @wire(CurrentPageReference)
    setPage() {
        const parts = window.location.pathname.split('/').filter(p => p);
        this.currentPage = parts.length > 1 ? parts[1] : '';
    }

    @wire(getCurrentUserRole)
    wiredRole({ data }) { if (data) this.userRole = data; }

    @wire(getCurrentUserName)
    wiredName({ data }) { if (data) this.userName = data; }

    @wire(getPendingApprovals)
    wiredPending({ data }) {
        if (data && this.isManager) this.pendingCount = data.length;
    }

    lc(p) { return this.currentPage === p ? 'nav-link active' : 'nav-link'; }
    get dashClass()      { return this.lc('dashboard'); }
    get leadsClass()     { return this.lc('leads'); }
    get tdClass()        { return this.lc('test-drives'); }
    get bookingsClass()  { return this.lc('bookings'); }
    get approvalsClass() { return this.lc('approvals'); }
    get paymentsClass()  { return this.lc('payments'); }
    get customersClass() { return this.lc('customers'); }
    get modelsClass()    { return this.lc('models'); }
    get reportsClass()   { return this.lc('reports'); }

    goDashboard()  { this.nav('dashboard'); }
    goLeads()      { this.nav('leads'); }
    goTestDrives() { this.nav('test-drives'); }
    goBookings()   { this.nav('bookings'); }
    goApprovals()  { this.nav('approvals'); }
    goPayments()   { this.nav('payments'); }
    goCustomers()  { this.nav('customers'); }
    goModels()     { this.nav('models'); }
    goReports()    { this.nav('reports'); }
    goProfile()    { this.nav('my-profile'); }

    handleLogout() {
        this.showDropdown = false;
        this.showMobile   = false;

        // Use the Community logout endpoint
        // This properly clears the session and
        // redirects to the site login page
        const loginUrl =
            'https://orgfarm-479a91b15c-dev-ed.develop.my.site.com/'
            + this.sitePrefix
            + '/login';

        // Community standard logout URL
        window.location.href =
            'https://orgfarm-479a91b15c-dev-ed.develop.my.site.com/'
            + this.sitePrefix
            + '/secur/logout.jsp?retURL='
            + encodeURIComponent(loginUrl);
    }

    toggleDropdown() { this.showDropdown = !this.showDropdown; }
    toggleMobile()   { this.showMobile   = !this.showMobile; }
}