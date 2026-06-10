import { LightningElement, wire, track } from 'lwc';
import getDashboardStats from '@salesforce/apex/PartnerDashboardController.getDashboardStats';
import getCurrentUserRole from '@salesforce/apex/PartnerDashboardController.getCurrentUserRole';
import getCurrentUserName from '@salesforce/apex/PartnerDashboardController.getCurrentUserName';

export default class PartnerProfilePage extends LightningElement {
    @track stats = {};
    @track userRole = '';
    @track userName = '';

    @wire(getCurrentUserRole)
    wiredRole({ data }) { if (data) this.userRole = data; }

    @wire(getCurrentUserName)
    wiredName({ data }) { if (data) this.userName = data; }

    @wire(getDashboardStats)
    wiredStats({ data }) { if (data) this.stats = data; }
}