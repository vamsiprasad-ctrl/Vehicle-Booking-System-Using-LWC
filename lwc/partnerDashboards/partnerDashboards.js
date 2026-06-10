import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getDashboardStats    from '@salesforce/apex/PartnerDashboardController.getDashboardStats';
import getCurrentUserRole   from '@salesforce/apex/PartnerDashboardController.getCurrentUserRole';
import getCurrentUserName   from '@salesforce/apex/PartnerDashboardController.getCurrentUserName';
import getRecentLeads       from '@salesforce/apex/PartnerDashboardController.getRecentLeads';
import getRecentTestDrives  from '@salesforce/apex/PartnerDashboardController.getRecentTestDrives';
import getRecentBookings    from '@salesforce/apex/PartnerDashboardController.getRecentBookings';
import getLeads             from '@salesforce/apex/LeadManagementController.getLeads';

const SL = { 'New':'badge blue','Contacted':'badge amber','Qualified':'badge purple','Converted':'badge teal','Lost':'badge red' };
const ST = { 'Requested':'badge amber','Confirmed':'badge blue','Completed':'badge green','Cancelled':'badge red' };
const SB = { 'Pending':'badge amber','Approved':'badge green','Delivered':'badge teal','Cancelled':'badge red' };
const fmt = n => new Intl.NumberFormat('en-IN').format(n || 0);
const fmtDT = dt => dt ? new Date(dt).toLocaleString('en-IN',{
    day:'2-digit', month:'short',
    hour:'2-digit', minute:'2-digit', hour12:true
}) : '—';

export default class PartnerDashboards extends LightningElement {
    @track stats          = {};
    @track userRole       = '';
    @track userName       = '';
    @track recentLeads    = [];
    @track recentTDs      = [];
    @track recentBookings = [];
    @track allLeads       = [];
    @track loadingLeads   = true;
    @track loadingTDs     = true;
    @track loadingBookings = true;

    _wiredStatsResult;
    _wiredLeadsResult;
    _wiredTDsResult;
    _wiredBookingsResult;

    get isManager()           { return this.userRole === 'Manager'; }
    get firstName()           { return (this.userName || '').split(' ')[0] || 'Partner'; }
    get monthlyRevFmt()       { return fmt(this.stats.monthlyRevenue); }
    get hasPendingApprovals() { return (this.stats.pendingApprovals || 0) > 0; }
    get noLeads()             { return !this.loadingLeads    && this.recentLeads.length === 0; }
    get noTDs()               { return !this.loadingTDs      && this.recentTDs.length === 0; }
    get noBookings()          { return !this.loadingBookings && this.recentBookings.length === 0; }

    get conversionRate() {
        const l = this.stats.totalLeads    || 0;
        const b = this.stats.totalBookings || 0;
        return l > 0 ? Math.round((b / l) * 100) : 0;
    }

    get contactedCount() {
        return this.allLeads.filter(l => l.Status === 'Contacted').length;
    }
    get qualifiedCount() {
        return this.allLeads.filter(l => l.Status === 'Qualified').length;
    }

    get timeOfDay() {
        const h = new Date().getHours();
        if (h < 12) return 'morning';
        if (h < 17) return 'afternoon';
        return 'evening';
    }

    get siteBase() {
        const m = window.location.pathname.match(/^\/([^\/]+)/);
        return window.location.origin + '/' + (m ? m[1] : 'partnerportal');
    }

    nav(p) { window.location.href = `${this.siteBase}/${p}`; }
    goDashboard()  { this.nav('dashboard'); }
    goLeads()      { this.nav('leads'); }
    goTestDrives() { this.nav('test-drives'); }
    goBookings()   { this.nav('bookings'); }
    goApprovals()  { this.nav('approvals'); }
    goPayments()   { this.nav('payments'); }
    goCustomers()  { this.nav('customers'); }
    goModels()     { this.nav('models'); }
    goReports()    { this.nav('reports'); }

    @wire(getCurrentUserRole) wiredRole({ data }) { if (data) this.userRole = data; }
    @wire(getCurrentUserName) wiredName({ data }) { if (data) this.userName = data; }

    @wire(getDashboardStats)
    wiredStats(result) {
        this._wiredStatsResult = result;
        if (result.data) this.stats = result.data;
        if (result.error) console.error(result.error);
    }

    @wire(getLeads, { statusFilter: 'all' })
    wiredAllLeads({ data }) { if (data) this.allLeads = data; }

    @wire(getRecentLeads)
    wiredLeads(result) {
        this._wiredLeadsResult = result;
        this.loadingLeads = false;
        if (result.data) {
            this.recentLeads = result.data.map(l => ({
                ...l,
                initial:   (l.FirstName || 'L').charAt(0).toUpperCase(),
                firstName: l.FirstName || '',
                lastName:  l.LastName  || '',
                phone:     l.Phone || '—',
                city:      l.City  || '—',
                modelName: l.Preferred_Model__r ? l.Preferred_Model__r.Name : '—',
                sc:        SL[l.Status] || 'badge'
            }));
        }
    }

    @wire(getRecentTestDrives)
    wiredTDs(result) {
        this._wiredTDsResult = result;
        this.loadingTDs = false;
        if (result.data) {
            this.recentTDs = result.data.map(td => ({
                ...td,
                customerName: td.Lead__r
                    ? (td.Lead__r.FirstName || '') + ' ' + (td.Lead__r.LastName || '')
                    : '—',
                modelName: td.Model__r ? td.Model__r.Name : '—',
                dateFmt:   fmtDT(td.Preferred_Date_Time__c),
                sc:        ST[td.Status__c] || 'badge'
            }));
        }
    }

    @wire(getRecentBookings)
    wiredBookings(result) {
        this._wiredBookingsResult = result;
        this.loadingBookings = false;
        if (result.data) {
            this.recentBookings = result.data.map(b => ({
                ...b,
                customerName: b.Contact__r
                    ? (b.Contact__r.FirstName || '') + ' ' + (b.Contact__r.LastName || '')
                    : '—',
                modelName: b.Model__r ? b.Model__r.Name : '—',
                amtFmt:    fmt(b.Total_Booking_Amount__c),
                sc:        SB[b.Status__c] || 'badge'
            }));
        }
    }
}