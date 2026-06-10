import { LightningElement, api, wire, track } from 'lwc';
import updateLeadStatus from '@salesforce/apex/LeadManagementController.updateLeadStatus';
import assignLead from '@salesforce/apex/LeadManagementController.assignLead';
import convertLead from '@salesforce/apex/LeadManagementController.convertLead';
import getSalesExecutives from '@salesforce/apex/LeadManagementController.getSalesExecutives';
import getCurrentUserRole from '@salesforce/apex/PartnerDashboardController.getCurrentUserRole';

export default class PartnerLeadDetail extends LightningElement {
    @api lead = {};
    @track executives = [];
    @track selectedStatus = '';
    @track selectedExecId = '';
    @track successMsg = '';
    @track errorMsg = '';
    @track userRole = '';

    get isManager() { return this.userRole === 'Manager'; }
    get modelName()   { return this.lead.Preferred_Model__r   ? this.lead.Preferred_Model__r.Name   : '—'; }
    get variantName() { return this.lead.Preferred_Variant__r ? this.lead.Preferred_Variant__r.Name : '—'; }
    get canConvert()  { return this.lead.Status === 'Qualified' && !this.lead.IsConverted; }

    @wire(getCurrentUserRole)
    wiredRole({ data }) { if (data) this.userRole = data; }

    @wire(getSalesExecutives)
    wiredExecs({ data }) { if (data) this.executives = data; }

    handleStatusChange(e) { this.selectedStatus = e.target.value; }
    handleExecChange(e)   { this.selectedExecId  = e.target.value; }

    updateStatus() {
        if (!this.selectedStatus) return;
        updateLeadStatus({ leadId: this.lead.Id, newStatus: this.selectedStatus })
            .then(() => {
                this.successMsg = 'Status updated successfully';
                this.dispatchEvent(new CustomEvent('refresh'));
            })
            .catch(err => { this.errorMsg = err.body ? err.body.message : 'Error'; });
    }

    assignLead() {
        if (!this.selectedExecId) return;
        assignLead({ leadId: this.lead.Id, newOwnerId: this.selectedExecId })
            .then(() => {
                this.successMsg = 'Lead assigned successfully';
                this.dispatchEvent(new CustomEvent('refresh'));
            })
            .catch(err => { this.errorMsg = err.body ? err.body.message : 'Error'; });
    }

    convertLead() {
        convertLead({ leadId: this.lead.Id })
            .then(() => {
                this.successMsg = 'Lead converted successfully!';
                this.dispatchEvent(new CustomEvent('refresh'));
            })
            .catch(err => { this.errorMsg = err.body ? err.body.message : 'Error'; });
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }
}