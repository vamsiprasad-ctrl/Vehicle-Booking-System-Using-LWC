import { LightningElement, wire, track } from 'lwc';
import getDashboardKPIs
    from '@salesforce/apex/DashboardController.getDashboardKPIs';

export default class SalesDashboard extends LightningElement {
    @track kpis = {
        openLeads:            0,
        activeOpportunities:  0,
        monthlyBookings:      0,
        pendingApprovals:     0
    };

    @wire(getDashboardKPIs)
    wiredKPIs({ error, data }) {
        if (data) {
            this.kpis = data;
        } else if (error) {
            console.error('salesDashboard error:', error);
        }
    }
}