import { LightningElement, track, wire, api } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import userId from '@salesforce/user/Id';
import getMyContact from '@salesforce/apex/BookingController.getMyContact';

export default class PortalNav extends NavigationMixin(LightningElement) {
    @api activePage = 'home';
    @track showMobileMenu = false;
    @track showUserMenu = false;
    @track currentPage = '';
    @track userFirstName = '';

    userId = userId;

    get isLoggedIn() {
        return !!this.userId && this.userFirstName !== '';
    }

    get userInitial() {
        return this.userFirstName
            ? this.userFirstName.charAt(0).toUpperCase()
            : 'U';
    }

    get hamLine1() { return this.showMobileMenu ? 'ham-open-1' : ''; }
    get hamLine2() { return this.showMobileMenu ? 'ham-open-2' : ''; }
    get hamLine3() { return this.showMobileMenu ? 'ham-open-3' : ''; }

    get siteBase() {
        const path = window.location.pathname;
        const match = path.match(/^\/([^\/]+)/);
        const prefix = match ? match[1] : 'tatamotorscus';
        return window.location.origin + '/' + prefix;
    }

    navigate(page) {
        window.location.href = page ? `${this.siteBase}/${page}` : this.siteBase;
        this.showMobileMenu = false;
        this.showUserMenu = false;
    }

    @wire(CurrentPageReference)
    handlePageRef() {
        const parts = window.location.pathname.split('/').filter(p => p);
        this.currentPage = parts.length > 1 ? parts[1] : '';
    }

    @wire(getMyContact)
    wiredContact({ data, error }) {
        if (data && data.FirstName) {
            this.userFirstName = data.FirstName;
        } else {
            this.userFirstName = '';
        }
        if (error) console.error('Nav contact error:', error);
    }

    linkClass(page) {
        return this.currentPage === page ? 'nav-btn active' : 'nav-btn';
    }

    get homeClass()       { return this.linkClass(''); }
    get modelsClass()     { return this.linkClass('models'); }
    get testDriveClass()  { return this.linkClass('book-test-drive'); }
    get aboutClass()      { return this.linkClass('about'); }
    get dashClass()       { return this.linkClass('my-dashboard'); }
    get bookingsClass()   { return this.linkClass('my-bookings'); }
    get testDrivesClass() { return this.linkClass('my-test-drives'); }
    get profileClass()    { return this.linkClass('my-profile'); }

    goHome()       { this.navigate(''); }
    goModels()     { this.navigate('models'); }
    goTestDrive()  { this.navigate('book-test-drive'); }
    goAbout()      { this.navigate('about'); }
    goDashboard()  { this.navigate('my-dashboard'); }
    goBookings()   { this.navigate('my-bookings'); }
    goTestDrives() { this.navigate('my-test-drives'); }
    goProfile()    { this.navigate('my-profile'); }

    handleLogin() {
        this[NavigationMixin.Navigate]({
            type: 'comm__loginPage',
            attributes: { actionName: 'login' }
        });
    }

    handleLogout() {
        const path = window.location.pathname;
        const match = path.match(/^\/([^\/]+)/);
        const prefix = match ? match[1] : 'tatamotorscus';
        window.location.href = `${window.location.origin}/${prefix}/secur/logout.jsp`;
    }

    toggleMobileMenu() { this.showMobileMenu = !this.showMobileMenu; }
    toggleUserMenu()   { this.showUserMenu   = !this.showUserMenu; }
}