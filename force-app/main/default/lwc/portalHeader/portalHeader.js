import { LightningElement, track, wire } from 'lwc';
import { CurrentPageReference, NavigationMixin }
    from 'lightning/navigation';
import { getRecord, getFieldValue }
    from 'lightning/uiRecordApi';
import userId from '@salesforce/user/Id';
import NAME_FIELD from '@salesforce/schema/User.Name';
import EMAIL_FIELD from '@salesforce/schema/User.Email';

export default class PortalNav
    extends NavigationMixin(LightningElement) {

    @track showDropdown = false;
    @track showMobile   = false;
    @track activePage   = 'home';

    userId = userId;

    // ── User Data ──────────────────────────────────

    @wire(getRecord, {
        recordId: '$userId',
        fields: [NAME_FIELD, EMAIL_FIELD]
    })
    currentUser;

    get userName() {
        return getFieldValue(this.currentUser.data, NAME_FIELD)
            || '';
    }

    get userEmail() {
        return getFieldValue(this.currentUser.data, EMAIL_FIELD)
            || '';
    }

    get userInitial() {
        return this.userName
            ? this.userName.charAt(0).toUpperCase()
            : '?';
    }

    get isLoggedIn() {
        return this.userId &&
               !this.userId.startsWith('0052o000000');
    }

    // ── Track Active Page ──────────────────────────

    @wire(CurrentPageReference)
    handlePageRef(pageRef) {
        if (!pageRef) return;
        const url = window.location.pathname;
        if (url.includes('book-test-drive')) {
            this.activePage = 'book';
        } else if (url.includes('my-dashboard')) {
            this.activePage = 'dashboard';
        } else if (url.includes('my-bookings')) {
            this.activePage = 'bookings';
        } else if (url.includes('my-test-drives')) {
            this.activePage = 'drives';
        } else {
            this.activePage = 'home';
        }
    }

    // ── Active Link Classes ────────────────────────

    get homeClass() {
        return this.activePage === 'home'
            ? 'nav-link nav-link--active' : 'nav-link';
    }

    get carsClass() {
        return this.activePage === 'cars'
            ? 'nav-link nav-link--active' : 'nav-link';
    }

    get bookClass() {
        return this.activePage === 'book'
            ? 'nav-link nav-link--active' : 'nav-link';
    }

    get dashClass() {
        return this.activePage === 'dashboard'
            ? 'nav-link nav-link--active' : 'nav-link';
    }

    get bookingsClass() {
        return this.activePage === 'bookings'
            ? 'nav-link nav-link--active' : 'nav-link';
    }

    get drivesClass() {
        return this.activePage === 'drives'
            ? 'nav-link nav-link--active' : 'nav-link';
    }

    // ── Toggle Handlers ────────────────────────────

    toggleDropdown() {
        this.showDropdown = !this.showDropdown;
        this.showMobile   = false;
    }

    toggleMobile() {
        this.showMobile   = !this.showMobile;
        this.showDropdown = false;
    }

    // ── Navigation Handlers ────────────────────────

    navigate(path) {
        this.showDropdown = false;
        this.showMobile   = false;
        window.location.href = path;
    }

    goHome()     { this.navigate('/customer/home'); }
    goCars()     {
        this.navigate('/customer/home');
        setTimeout(() => {
            const el = document.getElementById('models');
            if (el) el.scrollIntoView({ behavior: 'smooth' });
        }, 300);
    }
    goBook()     { this.navigate('/customer/book-test-drive'); }
    goDashboard(){ this.navigate('/customer/my-dashboard'); }
    goBookings() { this.navigate('/customer/my-bookings'); }
    goDrives()   { this.navigate('/customer/my-test-drives'); }
    goLogin()    { this.navigate('/customer/login'); }
    goLogout()   { this.navigate('/customer/logout'); }

    // Mobile versions
    goHomeMobile()      { this.goHome(); }
    goCarsMobile()      { this.goCars(); }
    goBookMobile()      { this.goBook(); }
    goDashboardMobile() { this.goDashboard(); }
    goBookingsMobile()  { this.goBookings(); }
    goDrivesMobile()    { this.goDrives(); }
}