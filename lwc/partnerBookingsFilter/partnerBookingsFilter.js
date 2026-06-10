import { LightningElement, track } from 'lwc';

export default class PartnerBookingsFilter extends LightningElement {
    @track active = 'all';
    btn(f) { return this.active === f ? 'filter-btn active' : 'filter-btn'; }
    get allClass()       { return this.btn('all'); }
    get pendingClass()   { return this.btn('Pending'); }
    get approvedClass()  { return this.btn('Approved'); }
    get deliveredClass() { return this.btn('Delivered'); }
    get cancelledClass() { return this.btn('Cancelled'); }

    handleFilter(e) {
        this.active = e.currentTarget.dataset.filter;
        this.dispatchEvent(new CustomEvent('filterchange', { detail: { filter: this.active } }));
    }
}