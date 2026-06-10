import { LightningElement, wire, track } from 'lwc';
import getLeads           from '@salesforce/apex/LeadManagementController.getLeads';
import getSalesExecutives from '@salesforce/apex/LeadManagementController.getSalesExecutives';
import updateLeadStatus   from '@salesforce/apex/LeadManagementController.updateLeadStatus';
import assignLead         from '@salesforce/apex/LeadManagementController.assignLead';
import convertLead        from '@salesforce/apex/LeadManagementController.convertLead';
import getCurrentUserRole from '@salesforce/apex/PartnerDashboardController.getCurrentUserRole';

const SC = {
    'New':       'badge blue',
    'Contacted': 'badge amber',
    'Qualified': 'badge purple',
    'Lost':      'badge red'
};

const ORDER = ['New','Contacted','Qualified','Converted'];

function tlClass(status, stage) {
    if (status === 'Lost') return 'tl-step inactive';
    const si = ORDER.indexOf(status);
    const ti = ORDER.indexOf(stage);
    if (ti < si)   return 'tl-step done';
    if (ti === si) return 'tl-step active';
    return 'tl-step inactive';
}

function enrich(l) {
    return {
        ...l,
        initial:     (l.FirstName || 'L').charAt(0).toUpperCase(),
        firstName:   l.FirstName  || '',
        lastName:    l.LastName   || '',
        phone:       l.Phone      || '—',
        email:       l.Email      || '—',
        city:        l.City       || '—',
        modelName:   l.Preferred_Model__r
            ? l.Preferred_Model__r.Name   : '—',
        variantName: l.Preferred_Variant__r
            ? l.Preferred_Variant__r.Name : '—',
        ownerName:   l.Owner ? l.Owner.Name : '—',
        createdDate: l.CreatedDate
            ? new Date(l.CreatedDate)
                .toLocaleDateString('en-IN') : '—',
        sc:  SC[l.Status] || 'badge',
        t1:  tlClass(l.Status, 'New'),
        t2:  tlClass(l.Status, 'Contacted'),
        t3:  tlClass(l.Status, 'Qualified'),
        t4:  tlClass(l.Status, 'Converted')
    };
}

export default class PartnerLeadsPages extends LightningElement {

    @track leads          = [];
    @track loading        = true;
    @track activeFilter   = 'all';
    @track selectedLead   = null;
    @track executives     = [];
    @track selectedStatus = '';
    @track selectedExecId = '';
    @track successMsg     = '';
    @track errorMsg       = '';
    @track converting     = false;
    userRole              = '';

    // ── Getters ─────────────────────────────────────
    get isManager() { return this.userRole === 'Manager'; }
    get empty()     { return !this.loading && this.leads.length === 0; }
    get leadCount() { return this.leads.length + ' lead(s)'; }
    get canConvert() {
        return this.selectedLead
            && this.selectedLead.Status === 'Qualified'
            && !this.selectedLead.IsConverted;
    }
    get convertLabel() {
        return this.converting
            ? 'Converting...' : 'Convert to Booking';
    }

    // Site base URL for navigation
    get siteBase() {
        const m = window.location.pathname.match(/^\/([^\/]+)/);
        return window.location.origin + '/'
            + (m ? m[1] : 'partnerportal');
    }

    // Filter button classes
    btn(f) {
        return this.activeFilter === f ? 'fb active' : 'fb';
    }
    get allClass()       { return this.btn('all'); }
    get newClass()       { return this.btn('New'); }
    get contactedClass() { return this.btn('Contacted'); }
    get qualifiedClass() { return this.btn('Qualified'); }
    get lostClass()      { return this.btn('Lost'); }

    // ── Wire ────────────────────────────────────────
    @wire(getCurrentUserRole)
    wiredRole({ data }) {
        if (data) this.userRole = data;
    }

    @wire(getSalesExecutives)
    wiredExecs({ data }) {
        if (data) this.executives = data;
    }

    // ── Lifecycle ───────────────────────────────────
    connectedCallback() {
        this.loadLeads();
    }

    // ── Load Leads ───────────────────────────────────
    // Apex handles filtering:
    // Sales Executive → sees only their own leads
    // Manager → sees all leads
    loadLeads() {
        this.loading = true;
        getLeads({ statusFilter: this.activeFilter })
            .then(data => {
                this.leads   = data.map(enrich);
                this.loading = false;
                // Refresh selected lead if panel open
                if (this.selectedLead) {
                    const updated = this.leads.find(
                        l => l.Id === this.selectedLead.Id
                    );
                    this.selectedLead = updated || null;
                }
            })
            .catch(err => {
                console.error('getLeads error:', err);
                this.loading = false;
            });
    }

    // ── Filter ──────────────────────────────────────
    filter(e) {
        this.activeFilter = e.currentTarget.dataset.f;
        this.selectedLead = null;
        this.loadLeads();
    }

    // ── Select Lead ─────────────────────────────────
    selectLead(e) {
        const id = e.currentTarget.dataset.id;
        this.selectedLead   = this.leads.find(l => l.Id === id);
        this.successMsg     = '';
        this.errorMsg       = '';
        this.selectedStatus = '';
        this.selectedExecId = '';
    }

    closeDetail() { this.selectedLead = null; }

    // ── Input Handlers ───────────────────────────────
    handleStatus(e) { this.selectedStatus = e.target.value; }
    handleExec(e)   { this.selectedExecId = e.target.value; }

    // ── Update Lead Status ───────────────────────────
    updateStatus() {
        if (!this.selectedStatus) return;
        this.successMsg = '';
        this.errorMsg   = '';

        updateLeadStatus({
            leadId:    this.selectedLead.Id,
            newStatus: this.selectedStatus
        })
        .then(() => {
            this.successMsg = '✅ Status updated to '
                + this.selectedStatus + '!';
            this.selectedStatus = '';
            this.loadLeads();
        })
        .catch(err => {
            this.errorMsg = err.body
                ? err.body.message : 'Update failed';
        });
    }

    // ── Assign Lead to Executive ─────────────────────
    assignLead() {
        if (!this.selectedExecId) return;
        this.successMsg = '';
        this.errorMsg   = '';

        assignLead({
            leadId:     this.selectedLead.Id,
            newOwnerId: this.selectedExecId
        })
        .then(() => {
            this.successMsg = '✅ Lead assigned successfully!';
            this.selectedExecId = '';
            this.loadLeads();
        })
        .catch(err => {
            this.errorMsg = err.body
                ? err.body.message : 'Assign failed';
        });
    }

    // ── Convert Lead to Booking ──────────────────────
    // 1. Converts Lead → Contact + Account + Opportunity
    // 2. Creates Booking async via @future
    // 3. Creates Community User async via Queueable
    // 4. Redirects to Bookings page after 3 seconds
    convertLead() {
        this.successMsg  = '';
        this.errorMsg    = '';
        this.converting  = true;

        convertLead({ leadId: this.selectedLead.Id })
        .then(() => {
            this.converting   = false;
            this.successMsg   =
                '🎉 Lead converted successfully! ' +
                'Booking is being created... ' +
                'Redirecting to Bookings in 3 seconds.';
            this.selectedLead = null;

            // Reload leads — converted lead disappears
            // because getLeads filters IsConverted = false
            this.loadLeads();

            // Booking created via @future — takes 1-2 seconds
            // Wait 3 seconds then go to bookings page
            // By then booking is ready to show
            setTimeout(() => {
                window.location.href =
                    this.siteBase + '/bookings';
            }, 3000);
        })
        .catch(err => {
            this.converting = false;
            this.errorMsg   = err.body
                ? err.body.message : 'Conversion failed';
        });
    }
}