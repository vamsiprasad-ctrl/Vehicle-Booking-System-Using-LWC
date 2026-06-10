import { LightningElement, api, track } from 'lwc';
import submitTestDriveRequest
    from '@salesforce/apex/TestDriveController.submitTestDriveRequest';

export default class TestDriveRequestForm extends LightningElement {
    @api modelId;
    @api variantId;
    @track submitted    = false;
    @track isSubmitting = false;
    @track error        = '';

    formData = {
        firstName: '', lastName: '', email: '',
        phone: '', city: '', preferredDateTime: ''
    };

    handleChange(event) {
        const field = event.target.dataset.field;
        this.formData[field] = event.target.value;
        this.error = '';
    }

    validateForm() {
        const { firstName, lastName, email,
                phone, preferredDateTime } = this.formData;
        if (!firstName || firstName.trim().length < 2)
            return 'First name must be at least 2 characters';
        if (!lastName || lastName.trim().length < 2)
            return 'Last name must be at least 2 characters';
        if (!email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email))
            return 'Please enter a valid email address';
        if (!phone || !/^[6-9][0-9]{9}$/.test(phone))
            return 'Phone must be 10 digits starting with 6-9';
        if (!preferredDateTime)
            return 'Please select a preferred date and time';
        return null;
    }

    async handleSubmit() {
        const validationError = this.validateForm();
        if (validationError) {
            this.error = validationError;
            return;
        }
        this.isSubmitting = true;
        this.error = '';
        try {
            await submitTestDriveRequest({
                firstName:        this.formData.firstName,
                lastName:         this.formData.lastName,
                email:            this.formData.email,
                phone:            this.formData.phone,
                city:             this.formData.city,
                variantId:        this.variantId,
                modelId:          this.modelId,
                preferredDateTime: new Date(
                    this.formData.preferredDateTime
                ).toISOString()
            });
            this.submitted = true;
        } catch (error) {
            this.error = error.body
                ? error.body.message
                : 'An error occurred. Please try again.';
        } finally {
            this.isSubmitting = false;
        }
    }

    handleReset() {
        this.submitted = false;
        this.formData  = {
            firstName: '', lastName: '', email: '',
            phone: '', city: '', preferredDateTime: ''
        };
        this.error = '';
    }
}