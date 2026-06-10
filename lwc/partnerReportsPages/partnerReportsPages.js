import { LightningElement, wire, track } from 'lwc';
import getDashboardStats from '@salesforce/apex/PartnerDashboardController.getDashboardStats';

export default class PartnerReportsPages extends LightningElement {
    @track stats = {};
    get monthlyRevFmt() { return new Intl.NumberFormat('en-IN').format(this.stats.monthlyRevenue || 0); }
    @wire(getDashboardStats) wiredStats({ data }) { if (data) this.stats = data; }
}