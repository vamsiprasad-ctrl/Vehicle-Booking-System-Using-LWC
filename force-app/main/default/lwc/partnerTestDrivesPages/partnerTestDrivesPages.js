import { LightningElement, wire, track } from 'lwc';
import getTestDrives      from '@salesforce/apex/PartnerTestDriveController.getTestDrives';
import getTodaysTestDrives from '@salesforce/apex/PartnerTestDriveController.getTodaysTestDrives';
import confirmTestDrive   from '@salesforce/apex/PartnerTestDriveController.confirmTestDrive';
import completeTestDrive  from '@salesforce/apex/PartnerTestDriveController.completeTestDrive';
import cancelTestDrive    from '@salesforce/apex/PartnerTestDriveController.cancelTestDrive';

const SC = {
    'Requested': 'badge amber',
    'Confirmed': 'badge blue',
    'Completed': 'badge green',
    'Cancelled': 'badge red'
};

const fmtDT = dt => dt ? new Date(dt).toLocaleString('en-IN', {
    day:'2-digit', month:'short', year:'numeric',
    hour:'2-digit', minute:'2-digit', hour12:true
}) : '—';

function enrichTD(td) {
    return {
        ...td,
        initial:       (td.Lead__r ? (td.Lead__r.FirstName || 'C') :
                       (td.Customer_First_Name__c || 'C')).charAt(0).toUpperCase(),
        customerName:  td.Lead__r
            ? (td.Lead__r.FirstName || '') + ' ' + (td.Lead__r.LastName || '')
            : (td.Customer_First_Name__c || '') + ' ' + (td.Customer_Last_Name__c || ''),
        customerPhone: td.Lead__r ? td.Lead__r.Phone || '—'
            : td.Customer_Phone__c || '—',
        modelName:     td.Model__r   ? td.Model__r.Name   : '—',
        variantName:   td.Variant__r ? td.Variant__r.Name : '—',
        ownerName:     td.Owner      ? td.Owner.Name      : '—',
        dateFmt:       fmtDT(td.Preferred_Date_Time__c),
        sc:            SC[td.Status__c] || 'badge'
    };
}

export default class PartnerTestDrivesPages extends LightningElement {
    @track testDrives    = [];
    @track loading       = true;
    @track activeFilter  = 'all';
    @track showToday     = false;
    @track selectedTD    = null;
    @track notes         = '';
    @track actionSuccess = '';
    @track actionError   = '';

    get todayLabel() { return this.showToday ? 'Show All' : "Today's Schedule"; }
    get empty()      { return !this.loading && this.testDrives.length === 0; }
    get canConfirm() { return this.selectedTD && this.selectedTD.Status__c === 'Requested'; }
    get canComplete(){ return this.selectedTD && this.selectedTD.Status__c === 'Confirmed'; }
    get canCancel()  { return this.selectedTD && !['Completed','Cancelled'].includes(this.selectedTD.Status__c); }

    btn(f) { return this.activeFilter === f ? 'fb active' : 'fb'; }
    get allClass() { return this.btn('all'); }
    get reqClass() { return this.btn('Requested'); }
    get conClass() { return this.btn('Confirmed'); }
    get comClass() { return this.btn('Completed'); }
    get canClass() { return this.btn('Cancelled'); }

    connectedCallback() { this.loadTDs(); }

    loadTDs() {
        this.loading = true;
        const call = this.showToday
            ? getTodaysTestDrives()
            : getTestDrives({ statusFilter: this.activeFilter });
        call.then(data => {
            this.testDrives = data.map(enrichTD);
            this.loading    = false;
            if (this.selectedTD) {
                const updated = this.testDrives.find(
                    td => td.Id === this.selectedTD.Id
                );
                if (updated) this.selectedTD = updated;
            }
        }).catch(() => { this.loading = false; });
    }

    filter(e) {
        this.activeFilter = e.currentTarget.dataset.f;
        this.selectedTD   = null;
        this.loadTDs();
    }

    toggleToday() {
        this.showToday = !this.showToday;
        this.loadTDs();
    }

    selectTD(e) {
        const id = e.currentTarget.dataset.id;
        this.selectedTD    = this.testDrives.find(td => td.Id === id);
        this.actionSuccess = '';
        this.actionError   = '';
        this.notes         = '';
    }

    closePanel()   { this.selectedTD = null; }
    handleNotes(e) { this.notes = e.target.value; }

    confirmTD() {
        this.actionSuccess = '';
        this.actionError   = '';
        confirmTestDrive({ testDriveId: this.selectedTD.Id })
            .then(() => {
                this.actionSuccess = '✅ Test drive confirmed!';
                this.loadTDs();
            })
            .catch(err => {
                this.actionError = err.body ? err.body.message : 'Error';
            });
    }

    completeTD() {
        if (!this.notes.trim()) {
            this.actionError = 'Notes are required.';
            return;
        }
        this.actionSuccess = '';
        this.actionError   = '';
        completeTestDrive({
            testDriveId: this.selectedTD.Id,
            notes:       this.notes
        })
            .then(() => {
                this.actionSuccess = '✅ Marked as completed!';
                this.loadTDs();
            })
            .catch(err => {
                this.actionError = err.body ? err.body.message : 'Error';
            });
    }

    cancelTD() {
        this.actionSuccess = '';
        this.actionError   = '';
        cancelTestDrive({ testDriveId: this.selectedTD.Id })
            .then(() => {
                this.actionSuccess = 'Test drive cancelled.';
                this.loadTDs();
            })
            .catch(err => {
                this.actionError = err.body ? err.body.message : 'Error';
            });
    }
}