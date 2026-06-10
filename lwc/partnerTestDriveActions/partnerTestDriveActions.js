import { LightningElement, api, track } from 'lwc';
import confirmTestDrive from '@salesforce/apex/PartnerTestDriveController.confirmTestDrive';
import completeTestDrive from '@salesforce/apex/PartnerTestDriveController.completeTestDrive';
import cancelTestDrive from '@salesforce/apex/PartnerTestDriveController.cancelTestDrive';

const STATUS_CLASS = {
    'Requested': 'badge requested',
    'Confirmed': 'badge confirmed',
    'Completed': 'badge completed',
    'Cancelled': 'badge cancelled'
};

export default class PartnerTestDriveActions extends LightningElement {
    @api testDrive = {};
    @track notes = '';
    @track successMsg = '';
    @track errorMsg = '';

    get statusClass() { return STATUS_CLASS[this.testDrive.Status__c] || 'badge'; }
    get canConfirm()  { return this.testDrive.Status__c === 'Requested'; }
    get canComplete() { return this.testDrive.Status__c === 'Confirmed'; }
    get canCancel()   { return !['Completed','Cancelled'].includes(this.testDrive.Status__c); }

    get dateFormatted() {
        if (!this.testDrive.Preferred_Date_Time__c) return '—';
        return new Date(this.testDrive.Preferred_Date_Time__c).toLocaleString('en-IN', {
            day: '2-digit', month: 'short', year: 'numeric',
            hour: '2-digit', minute: '2-digit', hour12: true
        });
    }

    handleNotes(e)  { this.notes = e.target.value; }
    handleClose()   { this.dispatchEvent(new CustomEvent('close')); }
    handleOverlayClick(e) { if (e.target === e.currentTarget) this.handleClose(); }

    confirmTD() {
        confirmTestDrive({ testDriveId: this.testDrive.Id })
            .then(() => {
                this.successMsg = 'Test drive confirmed! Email sent to customer.';
                setTimeout(() => this.dispatchEvent(new CustomEvent('refresh')), 1500);
            })
            .catch(err => { this.errorMsg = err.body ? err.body.message : 'Error'; });
    }

    completeTD() {
        completeTestDrive({ testDriveId: this.testDrive.Id, notes: this.notes })
            .then(() => {
                this.successMsg = 'Test drive marked as completed!';
                setTimeout(() => this.dispatchEvent(new CustomEvent('refresh')), 1500);
            })
            .catch(err => { this.errorMsg = err.body ? err.body.message : 'Error'; });
    }

    cancelTD() {
        cancelTestDrive({ testDriveId: this.testDrive.Id })
            .then(() => {
                this.successMsg = 'Test drive cancelled.';
                setTimeout(() => this.dispatchEvent(new CustomEvent('refresh')), 1500);
            })
            .catch(err => { this.errorMsg = err.body ? err.body.message : 'Error'; });
    }
}