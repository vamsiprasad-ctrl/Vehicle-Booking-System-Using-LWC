import { LightningElement, wire, track } from 'lwc';
import getDashboardStats from '@salesforce/apex/PartnerDashboardController.getDashboardStats';

export default class PartnerReportsPage extends LightningElement {
    @track stats = {};

    get monthlyRevenueFmt() {
        return new Intl.NumberFormat('en-IN').format(this.stats.monthlyRevenue || 0);
    }

    @wire(getDashboardStats)
    wiredStats({ data }) { if (data) this.stats = data; }
}