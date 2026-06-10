import { LightningElement, api, track } from 'lwc';
import submitTestDriveRequest
    from '@salesforce/apex/TestDriveController.submitTestDriveRequest';

export default class TestDriveFormPage extends LightningElement {
    @api modelId;
    @api modelName;
    @api variantId;
    @api variantName;

    @track isSubmitting   = false;
    @track hasGeneralError = false;
    @track generalError   = '';

    @track formData = {
        firstName:         '',
        lastName:          '',
        email:             '',
        phone:             '',
        city:              '',
        preferredDateTime: ''
    };

    @track errors = {
        firstName:         '',
        lastName:          '',
        email:             '',
        phone:             '',
        preferredDateTime: ''
    };

    // ── Input classes with error state ──
    get firstNameClass() {
        return this.errors.firstName
            ? 'form-input form-input--error'
            : 'form-input';
    }
    get lastNameClass() {
        return this.errors.lastName
            ? 'form-input form-input--error'
            : 'form-input';
    }
    get emailClass() {
        return this.errors.email
            ? 'form-input form-input--error'
            : 'form-input';
    }
    get phoneClass() {
        return this.errors.phone
            ? 'form-input form-input--error'
            : 'form-input';
    }
    get dateTimeClass() {
        return this.errors.preferredDateTime
            ? 'form-input form-input--error'
            : 'form-input';
    }

    handleChange(event) {
        const field = event.target.dataset.field;
        this.formData = {
            ...this.formData,
            [field]: event.target.value
        };
        // Clear error on change
        this.errors = { ...this.errors, [field]: '' };
        this.hasGeneralError = false;
    }

    validateForm() {
        let isValid = true;
        const errors = { ...this.errors };

        if (!this.formData.firstName ||
            this.formData.firstName.trim().length < 2) {
            errors.firstName =
                'First name must be at least 2 characters';
            isValid = false;
        }
        if (!this.formData.lastName ||
            this.formData.lastName.trim().length < 2) {
            errors.lastName =
                'Last name must be at least 2 characters';
            isValid = false;
        }
        if (!this.formData.email ||
            !/^[^\s@]+@[^\s@]+\.[^\s@]+$/
                .test(this.formData.email)) {
            errors.email = 'Please enter a valid email address';
            isValid = false;
        }
        if (!this.formData.phone ||
            !/^[6-9][0-9]{9}$/.test(this.formData.phone)) {
            errors.phone =
                'Phone must be 10 digits starting with 6-9';
            isValid = false;
        }
        if (!this.formData.preferredDateTime) {
            errors.preferredDateTime =
                'Please select preferred date and time';
            isValid = false;
        }

        this.errors = errors;
        return isValid;
    }

    async handleSubmit() {
        if (!this.validateForm()) return;

        this.isSubmitting    = true;
        this.hasGeneralError = false;

        try {
            await submitTestDriveRequest({
                firstName:        this.formData.firstName.trim(),
                lastName:         this.formData.lastName.trim(),
                email:            this.formData.email.trim(),
                phone:            this.formData.phone.trim(),
                city:             this.formData.city.trim(),
                variantId:        this.variantId,
                modelId:          this.modelId,
                preferredDateTime: new Date(
                    this.formData.preferredDateTime
                ).toISOString()
            });

            this.dispatchEvent(new CustomEvent('submitted', {
                bubbles: true
            }));

        } catch (error) {
            this.hasGeneralError = true;
            this.generalError = error.body
                ? error.body.message
                : 'An error occurred. Please try again.';
        } finally {
            this.isSubmitting = false;
        }
    }

    handleBack() {
        this.dispatchEvent(new CustomEvent('back', {
            bubbles: true
        }));
    }
}