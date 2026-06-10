import { LightningElement, wire, track } from 'lwc';
import isCurrentUserManager
    from '@salesforce/apex/DashboardController.isCurrentUserManager';
import getMyLeads
    from '@salesforce/apex/DashboardController.getMyLeads';
import getMyTestDrives
    from '@salesforce/apex/DashboardController.getMyTestDrives';
import getPendingApprovals
    from '@salesforce/apex/DashboardController.getPendingApprovals';
import getDashboardKPIs
    from '@salesforce/apex/DashboardController.getDashboardKPIs';

const STATUS_CLS = {
    'New':         'status-badge status-blue',
    'Contacted':   'status-badge status-blue',
    'Qualified':   'status-badge status-green',
    'Converted':   'status-badge status-purple',
    'Unqualified': 'status-badge status-gray',
};

export default class PartnerTeamPage extends LightningElement {
    @track isLoading  = true;
    @track isManager  = false;
    @track members    = [];
    @track allLeads   = [];
    @track noMembers  = false;
    @track teamKpis   = {
        totalLeads: 0,
        totalTestDrives: 0,
        totalBookings: 0,
        pendingApprovals: 0
    };

    connectedCallback() {
        isCurrentUserManager()
            .then(result => {
                this.isManager = result;
                if (result) this.loadTeamData();
                else         this.isLoading = false;
            })
            .catch(() => { this.isLoading = false; });
    }

    loadTeamData() {
        this.isLoading = true;
        Promise.all([
            getMyLeads(),
            getMyTestDrives(),
            getPendingApprovals(),
            getDashboardKPIs()
        ])
        .then(([leads, tds, approvals, kpis]) => {
            // Build team KPIs
            this.teamKpis = {
                totalLeads:       (leads     || []).length,
                totalTestDrives:  (tds       || []).length,
                totalBookings:    (approvals || []).length,
                pendingApprovals: kpis
                    ? (kpis.pendingApprovals || 0) : 0
            };

            // Annotate leads
            this.allLeads = (leads || []).map(l => ({
                ...l,
                firstInitial: l.FirstName
                    ? l.FirstName.charAt(0).toUpperCase() : '?',
                statusCls: STATUS_CLS[l.Status]
                    || 'status-badge status-gray'
            }));

            // Build member map from lead owners
            const memberMap = {};
            (leads || []).forEach(l => {
                if (!l.OwnerId) return;
                const ownerId = l.OwnerId;
                if (!memberMap[ownerId]) {
                    memberMap[ownerId] = {
                        id:           ownerId,
                        name:         l.Owner ? l.Owner.Name : 'Unknown',
                        email:        l.Owner ? l.Owner.Email : '',
                        initial:      l.Owner && l.Owner.Name
                            ? l.Owner.Name.charAt(0).toUpperCase() : '?',
                        leadCount:    0,
                        tdCount:      0,
                        bookingCount: 0
                    };
                }
                memberMap[ownerId].leadCount++;
            });

            // Count test drives per owner
            (tds || []).forEach(td => {
                if (td.OwnerId && memberMap[td.OwnerId]) {
                    memberMap[td.OwnerId].tdCount++;
                }
            });

            // Count bookings per owner
            (approvals || []).forEach(b => {
                if (b.OwnerId && memberMap[b.OwnerId]) {
                    memberMap[b.OwnerId].bookingCount++;
                }
            });

            this.members  = Object.values(memberMap);
            this.noMembers = this.members.length === 0;
        })
        .catch(err => {
            console.error('loadTeamData error:', err);
            this.noMembers = true;
        })
        .finally(() => { this.isLoading = false; });
    }

    handleEmail(event) {
        const email = event.currentTarget.dataset.email;
        if (email) window.open('mailto:' + email);
    }
}