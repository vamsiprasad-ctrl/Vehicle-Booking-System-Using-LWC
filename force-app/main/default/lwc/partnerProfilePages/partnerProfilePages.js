import { LightningElement, wire, track } from 'lwc';
import getDashboardStats  from '@salesforce/apex/PartnerDashboardController.getDashboardStats';
import getCurrentUserRole from '@salesforce/apex/PartnerDashboardController.getCurrentUserRole';
import getCurrentUserName from '@salesforce/apex/PartnerDashboardController.getCurrentUserName';

export default class PartnerProfilePages extends LightningElement {
    @track stats    = {};
    @track userRole = '';
    @track userName = '';

    get isManager()      { return this.userRole === 'Manager'; }
    get initial()        { return this.userName ? this.userName.charAt(0).toUpperCase() : 'U'; }
    get conversionRate() {
        const l = this.stats.totalLeads    || 0;
        const b = this.stats.totalBookings || 0;
        return l > 0 ? Math.round((b / l) * 100) : 0;
    }

    @wire(getCurrentUserRole) wiredRole({ data }) { if (data) this.userRole = data; }
    @wire(getCurrentUserName) wiredName({ data }) { if (data) this.userName = data; }
    @wire(getDashboardStats)  wiredStats({ data }) { if (data) this.stats = data; }
}