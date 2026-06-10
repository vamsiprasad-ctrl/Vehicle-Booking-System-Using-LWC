import { LightningElement, api } from 'lwc';

export default class PartnerModelsTable extends LightningElement {
    @api loading = false;
    @api models = [];
    get empty() { return !this.loading && (!this.models || this.models.length === 0); }
}