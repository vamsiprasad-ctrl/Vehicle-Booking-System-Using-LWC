import { LightningElement, api } from 'lwc';

export default class PartnerKpiCards extends LightningElement {
    @api stats = {};
    @api isManager = false;

    get cards() {
        const s = this.stats || {};
        const fmt = n => new Intl.NumberFormat('en-IN').format(n || 0);
        const cards = [
            {
                id: 'leads',
                icon: '👥',
                iconClass: 'kpi-icon blue',
                label: 'Total Leads',
                value: s.totalLeads || 0,
                sub: `${s.newLeads || 0} new`
            },
            {
                id: 'testdrives',
                icon: '🚗',
                iconClass: 'kpi-icon purple',
                label: 'Test Drives',
                value: s.totalTestDrives || 0,
                sub: `${s.scheduledTestDrives || 0} confirmed`
            },
            {
                id: 'bookings',
                icon: '📋',
                iconClass: 'kpi-icon green',
                label: 'Bookings',
                value: s.totalBookings || 0,
                sub: `${s.approvedBookings || 0} approved`
            },
            {
                id: 'delivered',
                icon: '✅',
                iconClass: 'kpi-icon teal',
                label: 'Delivered',
                value: s.deliveredBookings || 0,
                sub: null
            }
        ];

        if (this.isManager) {
            cards.push({
                id: 'pending',
                icon: '⏳',
                iconClass: 'kpi-icon amber',
                label: 'Pending Approvals',
                value: s.pendingApprovals || 0,
                sub: null
            });
            cards.push({
                id: 'revenue',
                icon: '💰',
                iconClass: 'kpi-icon orange',
                label: 'Revenue This Month',
                value: '₹' + fmt(s.monthlyRevenue),
                sub: null
            });
        }

        return cards;
    }
}