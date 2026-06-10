import { LightningElement, wire, track } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import getCurrentUserRole from '@salesforce/apex/PartnerDashboardController.getCurrentUserRole';
import getCurrentUserName from '@salesforce/apex/PartnerDashboardController.getCurrentUserName';
import getPendingApprovals from '@salesforce/apex/PartnerBookingController.getPendingApprovals';

export default class PartnerNav extends NavigationMixin(LightningElement) {
    @track currentPage = '';
    @track showMenu = false;
    @track showMobile = false;
    @track userRole = '';
    @track userName = '';
    @track pendingCount = 0;

    get isManager() { return this.userRole === 'Manager'; }

    get userInitial() {
        return this.userName ? this.userName.charAt(0).toUpperCase() : 'U';
    }

    get siteBase() {
        const path = window.location.pathname;
        const match = path.match(/^\/([^\/]+)/);
        return window.location.origin + '/' + (match ? match[1] : 'tatadealers');
    }

    navigate(page) {
        window.location.href = `${this.siteBase}/${page}`;
        this.showMenu = false;
        this.showMobile = false;
    }

    @wire(CurrentPageReference)
    handlePageRef() {
        const parts = window.location.pathname.split('/').filter(p => p);
        this.currentPage = parts.length > 1 ? parts[1] : '';
    }

    @wire(getCurrentUserRole)
    wiredRole({ data }) { if (data) this.userRole = data; }

    @wire(getCurrentUserName)
    wiredName({ data }) { if (data) this.userName = data; }

    @wire(getPendingApprovals)
    wiredPending({ data }) {
        if (data) this.pendingCount = data.length > 0 ? data.length : 0;
    }

    linkClass(page) {
        return this.currentPage === page ? 'nav-link active' : 'nav-link';
    }

    get dashClass()       { return this.linkClass('dashboard'); }
    get leadsClass()      { return this.linkClass('leads'); }
    get testDrivesClass() { return this.linkClass('test-drives'); }
    get bookingsClass()   { return this.linkClass('bookings'); }
    get approvalsClass()  { return this.linkClass('approvals'); }
    get paymentsClass()   { return this.linkClass('payments'); }
    get customersClass()  { return this.linkClass('customers'); }
    get modelsClass()     { return this.linkClass('models'); }
    get reportsClass()    { return this.linkClass('reports'); }

    goDashboard()  { this.navigate('dashboard'); }
    goLeads()      { this.navigate('leads'); }
    goTestDrives() { this.navigate('test-drives'); }
    goBookings()   { this.navigate('bookings'); }
    goApprovals()  { this.navigate('approvals'); }
    goPayments()   { this.navigate('payments'); }
    goCustomers()  { this.navigate('customers'); }
    goModels()     { this.navigate('models'); }
    goReports()    { this.navigate('reports'); }
    goProfile()    { this.navigate('my-profile'); this.showMenu = false; }

    handleLogout() {
        const path = window.location.pathname;
        const match = path.match(/^\/([^\/]+)/);
        const prefix = match ? match[1] : 'tatadealers';
        window.location.href = `${window.location.origin}/${prefix}/secur/logout.jsp`;
    }

    toggleMenu()   { this.showMenu   = !this.showMenu; }
    toggleMobile() { this.showMobile = !this.showMobile; }
}