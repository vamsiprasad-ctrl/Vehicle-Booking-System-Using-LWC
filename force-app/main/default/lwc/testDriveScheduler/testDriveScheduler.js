import { LightningElement, wire, track } from 'lwc';
import getMyTestDrives
    from '@salesforce/apex/DashboardController.getMyTestDrives';

export default class TestDriveScheduler extends LightningElement {
    @track testDrives   = [];
    @track noTestDrives = false;

    @wire(getMyTestDrives)
    wiredTestDrives({ error, data }) {
        if (data) {
            this.testDrives   = data;
            this.noTestDrives = data.length === 0;
        } else if (error) {
            console.error('testDriveScheduler error:', error);
            this.noTestDrives = true;
        }
    }
}