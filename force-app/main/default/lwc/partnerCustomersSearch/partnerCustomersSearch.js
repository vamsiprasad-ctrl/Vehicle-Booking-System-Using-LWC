import { LightningElement, track } from 'lwc';

export default class PartnerCustomersSearch extends LightningElement {
    @track searchKey = '';

    handleInput(e) { this.searchKey = e.target.value; }

    handleSearch() {
        this.dispatchEvent(new CustomEvent('search', {
            detail: { searchKey: this.searchKey }
        }));
    }

    clearSearch() {
        this.searchKey = '';
        this.dispatchEvent(new CustomEvent('search', {
            detail: { searchKey: '' }
        }));
    }
}