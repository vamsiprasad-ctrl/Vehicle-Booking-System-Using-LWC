import { LightningElement, wire, track } from 'lwc';
import getTestDrives from '@salesforce/apex/PartnerTestDriveController.getTestDrives';
import getTodaysTestDrives from '@salesforce/apex/PartnerTestDriveController.getTodaysTestDrives';

export default class PartnerTestDrivesPage extends LightningElement {
    @track testDrives = [];
    @track loading = true;
    @track activeFilter = 'all';
    @track showToday = false;
    @track showActionModal = false;
    @track selectedTD = null;

    get todayLabel() { return this.showToday ? 'Show All' : "Today's Schedule"; }

    @wire(getTestDrives, { statusFilter: '$activeFilter' })
    wiredTDs({ data, error }) {
        if (!this.showToday) {
            this.loading = false;
            if (data) this.testDrives = data;
            if (error) console.error(error);
        }
    }

    handleFilter(event) {
        this.activeFilter = event.detail.filter;
        this.loading = true;
    }

    toggleToday() {
        this.showToday = !this.showToday;
        this.loading = true;
        if (this.showToday) {
            getTodaysTestDrives()
                .then(data => { this.testDrives = data; this.loading = false; })
                .catch(() => { this.loading = false; });
        } else {
            getTestDrives({ statusFilter: this.activeFilter })
                .then(data => { this.testDrives = data; this.loading = false; })
                .catch(() => { this.loading = false; });
        }
    }

    handleAction(event) {
        this.selectedTD = event.detail.testDrive;
        this.showActionModal = true;
    }

    closeModal() { this.showActionModal = false; this.selectedTD = null; }

    refreshData() {
        this.showActionModal = false;
        this.selectedTD = null;
        this.loading = true;
        getTestDrives({ statusFilter: this.activeFilter })
            .then(data => { this.testDrives = data; this.loading = false; })
            .catch(() => { this.loading = false; });
    }
}