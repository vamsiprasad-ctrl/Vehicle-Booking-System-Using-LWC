import { LightningElement, api } from 'lwc';

const STATUS_CLASS = {
    'New':       'badge new',
    'Contacted': 'badge contacted',
    'Qualified': 'badge qualified',
    'Lost':      'badge lost'
};

export default class PartnerLeadsTable extends LightningElement {
    @api loading = false;

    _leads = [];
    @api
    get leads() { return this._leads; }
    set leads(val) {
        this._leads = (val || []).map(l => ({
            ...l,
            initial: l.FirstName ? l.FirstName.charAt(0).toUpperCase() : 'L',
            statusClass: STATUS_CLASS[l.Status] || 'badge',
            modelName: l.Preferred_Model__r ? l.Preferred_Model__r.Name : '—',
            createdDate: l.CreatedDate ? new Date(l.CreatedDate).toLocaleDateString('en-IN') : '—'
        }));
    }

    get empty() { return !this.loading && this._leads.length === 0; }

    selectLead(event) {
        const id = event.currentTarget.dataset.id;
        const lead = this._leads.find(l => l.Id === id);
        this.dispatchEvent(new CustomEvent('leadselect', { detail: { lead } }));
    }
}