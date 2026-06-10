import { LightningElement, wire, track } from 'lwc';
import { updateRecord } from 'lightning/uiRecordApi';
import getMyContact from '@salesforce/apex/BookingController.getMyContact';
import CONTACT_FIRSTNAME from '@salesforce/schema/Contact.FirstName';
import CONTACT_LASTNAME  from '@salesforce/schema/Contact.LastName';
import CONTACT_EMAIL     from '@salesforce/schema/Contact.Email';
import CONTACT_PHONE     from '@salesforce/schema/Contact.Phone';
import CONTACT_CITY      from '@salesforce/schema/Contact.MailingCity';

export default class MyProfile extends LightningElement {
    @track contact    = null;
    @track loading    = true;
    @track editMode   = false;
    @track saving     = false;
    @track saveSuccess = false;
    @track saveError  = '';

    @track editFirstName = '';
    @track editLastName  = '';
    @track editEmail     = '';
    @track editPhone     = '';
    @track editCity      = '';

    get siteBase() {
        const path = window.location.pathname;
        const match = path.match(/^\/([^\/]+)/);
        const prefix = match ? match[1] : 'tatasite';
        return window.location.origin + '/' + prefix;
    }

    navigate(page) { window.location.href = `${this.siteBase}/${page}`; }

    get initials() {
        if (!this.contact) return 'U';
        const f = this.contact.FirstName ? this.contact.FirstName.charAt(0) : '';
        const l = this.contact.LastName  ? this.contact.LastName.charAt(0)  : '';
        return (f + l).toUpperCase() || 'U';
    }

    @wire(getMyContact)
    wiredContact({ data, error }) {
        this.loading = false;
        if (data) {
            this.contact = data;
            this.resetEditFields();
        }
        if (error) console.error('Contact error:', error);
    }

    resetEditFields() {
        if (!this.contact) return;
        this.editFirstName = this.contact.FirstName  || '';
        this.editLastName  = this.contact.LastName   || '';
        this.editEmail     = this.contact.Email      || '';
        this.editPhone     = this.contact.Phone      || '';
        this.editCity      = this.contact.MailingCity || '';
    }

    enableEdit() {
        this.editMode    = true;
        this.saveSuccess = false;
        this.saveError   = '';
        this.resetEditFields();
    }

    cancelEdit() {
        this.editMode = false;
        this.saveError = '';
        this.resetEditFields();
    }

    handleFirstName(e) { this.editFirstName = e.target.value; }
    handleLastName(e)  { this.editLastName  = e.target.value; }
    handleEmail(e)     { this.editEmail     = e.target.value; }
    handlePhone(e)     { this.editPhone     = e.target.value; }
    handleCity(e)      { this.editCity      = e.target.value; }

    saveProfile() {
        if (!this.editFirstName.trim() || !this.editLastName.trim()) {
            this.saveError = 'First name and last name are required.';
            return;
        }
        if (!this.editEmail.includes('@')) {
            this.saveError = 'Please enter a valid email address.';
            return;
        }
        const phoneReg = /^[6-9][0-9]{9}$/;
        if (this.editPhone && !phoneReg.test(this.editPhone)) {
            this.saveError = 'Please enter a valid 10-digit mobile number.';
            return;
        }

        this.saving    = true;
        this.saveError = '';

        const fields = {};
        fields['Id']                      = this.contact.Id;
        fields[CONTACT_FIRSTNAME.fieldApiName] = this.editFirstName.trim();
        fields[CONTACT_LASTNAME.fieldApiName]  = this.editLastName.trim();
        fields[CONTACT_EMAIL.fieldApiName]     = this.editEmail.trim();
        fields[CONTACT_PHONE.fieldApiName]     = this.editPhone.trim();
        fields[CONTACT_CITY.fieldApiName]      = this.editCity.trim();

        updateRecord({ fields })
            .then(() => {
                this.contact = {
                    ...this.contact,
                    FirstName:   this.editFirstName.trim(),
                    LastName:    this.editLastName.trim(),
                    Email:       this.editEmail.trim(),
                    Phone:       this.editPhone.trim(),
                    MailingCity: this.editCity.trim()
                };
                this.editMode    = false;
                this.saving      = false;
                this.saveSuccess = true;
                setTimeout(() => { this.saveSuccess = false; }, 4000);
            })
            .catch(err => {
                this.saving    = false;
                this.saveError = err.body ? err.body.message : 'Update failed. Please try again.';
            });
    }

    goDashboard() { this.navigate('my-dashboard'); }
}