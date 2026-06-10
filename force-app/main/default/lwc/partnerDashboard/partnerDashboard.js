import { LightningElement, wire, track } from 'lwc';
import getDashboardStats from '@salesforce/apex/PartnerDashboardController.getDashboardStats';
import getCurrentUserRole from '@salesforce/apex/PartnerDashboardController.getCurrentUserRole';
import getCurrentUserName from '@salesforce/apex/PartnerDashboardController.getCurrentUserName';
import getPendingApprovals from '@salesforce/apex/PartnerBookingController.getPendingApprovals';

export default class PartnerDashboard extends LightningElement {
    @track stats = {};
    @track loading = true;
    @track userRole = '';
    @track userName = '';
    @track pendingCount = 0;

    get isManager() { return this.userRole === 'Manager'; }
    get roleLabel()  { return this.isManager ? 'team' : 'personal'; }

    get showApprovalAlert() {
        return this.isManager && this.pendingCount > 0;
    }

    get siteBase() {
        const path = window.location.pathname;
        const match = path.match(/^\/([^\/]+)/);
        return window.location.origin + '/' + (match ? match[1] : 'tatadealers');
    }

    navigate(page) { window.location.href = `${this.siteBase}/${page}`; }

    @wire(getCurrentUserRole)
    wiredRole({ data }) { if (data) this.userRole = data; }

    @wire(getCurrentUserName)
    wiredName({ data }) { if (data) this.userName = data.split(' ')[0]; }

    @wire(getDashboardStats)
    wiredStats({ data, error }) {
        this.loading = false;
        if (data) this.stats = data;
        if (error) console.error('Stats error:', error);
    }

    @wire(getPendingApprovals)
    wiredPending({ data }) {
        if (data) this.pendingCount = data.length;
    }

    goLeads()     { this.navigate('leads'); }
    goApprovals() { this.navigate('approvals'); }
}