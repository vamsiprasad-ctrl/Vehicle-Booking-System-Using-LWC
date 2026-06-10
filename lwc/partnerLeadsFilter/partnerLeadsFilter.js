import { LightningElement, track } from 'lwc';

export default class PartnerLeadsFilter extends LightningElement {
    @track active = 'all';

    btnClass(f) { return this.active === f ? 'filter-btn active' : 'filter-btn'; }
    get allClass()       { return this.btnClass('all'); }
    get newClass()       { return this.btnClass('New'); }
    get contactedClass() { return this.btnClass('Contacted'); }
    get qualifiedClass() { return this.btnClass('Qualified'); }
    get lostClass()      { return this.btnClass('Lost'); }

    handleFilter(event) {
        this.active = event.currentTarget.dataset.filter;
        this.dispatchEvent(new CustomEvent('filterchange', {
            detail: { filter: this.active }
        }));
    }
}