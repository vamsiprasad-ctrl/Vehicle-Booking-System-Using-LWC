import { LightningElement, api } from 'lwc';

export default class PartnerProfileCard extends LightningElement {
    @api userName = '';
    @api userRole = '';

    get initial()   { return this.userName ? this.userName.charAt(0).toUpperCase() : 'U'; }
    get isManager() { return this.userRole === 'Manager'; }
}