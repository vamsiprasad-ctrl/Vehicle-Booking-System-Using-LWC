import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getActiveModels from '@salesforce/apex/ModelController.getActiveModels';

export default class PortalFooter extends NavigationMixin(LightningElement) {
    @track models = [];
    @track loadingModels = true;

    get currentYear() { return new Date().getFullYear(); }

    get siteBase() {
        const path = window.location.pathname;
        const match = path.match(/^\/([^\/]+)/);
        const prefix = match ? match[1] : 'tatasite';
        return window.location.origin + '/' + prefix;
    }

    navigate(page) {
        window.location.href = page ? `${this.siteBase}/${page}` : this.siteBase;
    }

    @wire(getActiveModels)
    wiredModels({ error, data }) {
        this.loadingModels = false;
        if (data) this.models = data.slice(0, 6);
        if (error) console.error('Footer models error:', error);
    }

    goHome()      { this.navigate(''); }
    goModels()    { this.navigate('models'); }
    goTestDrive() { this.navigate('book-test-drive'); }
    goAbout()     { this.navigate('about'); }
    goLogin() {
        this[NavigationMixin.Navigate]({ type: 'comm__loginPage', attributes: { actionName: 'login' } });
    }
}