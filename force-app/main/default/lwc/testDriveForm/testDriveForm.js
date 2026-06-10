import { LightningElement, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getPortalCities from '@salesforce/apex/PortalController.getPortalCities';
import getModelById from '@salesforce/apex/ModelController.getModelById';
import submitTestDriveRequest from '@salesforce/apex/TestDriveController.submitTestDriveRequest';

const MODEL_IMAGES = {
    'Kia Seltos':             'https://imgd.aeplcdn.com/370x208/n/ngh5heb_1763799.jpg?q=80',
    'Mahindra Thar Roxx':     'https://imgd.aeplcdn.com/370x208/n/i3q4v9b_1808901.jpg?q=80',
    'Maruti Suzuki e Vitara': 'https://imgd.aeplcdn.com/370x208/n/vzhgcib_1892949.png?q=80',
    'Nissan Gravite':         'https://imgd.aeplcdn.com/370x208/n/cw/ec/200003/gravite-exterior-right-front-three-quarter-337.jpeg?isig=0&q=80',
    'Tata Punch EV':          'https://imgd.aeplcdn.com/370x208/n/cw/ec/217141/punch-ev-facelift-exterior-right-front-three-quarter-2.png?isig=0&q=80',
    'Punch EV':               'https://imgd.aeplcdn.com/370x208/n/cw/ec/217141/punch-ev-facelift-exterior-right-front-three-quarter-2.png?isig=0&q=80',
    'Tata Sierra':            'https://imgd.aeplcdn.com/1056x594/n/cw/ec/193017/sierra-exterior-right-front-three-quarter-263.jpeg?isig=0&q=80',
    'Sierra':                 'https://imgd.aeplcdn.com/1056x594/n/cw/ec/193017/sierra-exterior-right-front-three-quarter-263.jpeg?isig=0&q=80',
    'Nexon':                  'https://imgd.aeplcdn.com/664x374/n/cw/ec/141115/nexon-exterior-right-front-three-quarter-2.jpeg',
    'Punch':                  'https://imgd.aeplcdn.com/664x374/n/cw/ec/141867/punch-exterior-right-front-three-quarter.jpeg',
    'Harrier':                'https://imgd.aeplcdn.com/664x374/n/cw/ec/157239/harrier-exterior-right-front-three-quarter-3.jpeg',
    'Safari':                 'https://imgd.aeplcdn.com/664x374/n/cw/ec/161273/safari-exterior-right-front-three-quarter-2.jpeg',
    'Tiago':                  'https://imgd.aeplcdn.com/664x374/n/cw/ec/138609/tiago-exterior-right-front-three-quarter-56.jpeg',
    'Altroz':                 'https://imgd.aeplcdn.com/664x374/n/cw/ec/141121/altroz-exterior-right-front-three-quarter-3.jpeg',
    'Tigor':                  'https://imgd.aeplcdn.com/664x374/n/cw/ec/128171/tigor-exterior-right-front-three-quarter-6.jpeg',
    'Curvv':                  'https://imgd.aeplcdn.com/664x374/n/cw/ec/230991/curvv-exterior-right-front-three-quarter.jpeg'
};

function getModelImage(modelName, imageUrlFromOrg) {
    if (imageUrlFromOrg) return imageUrlFromOrg;
    if (MODEL_IMAGES[modelName]) return MODEL_IMAGES[modelName];
    const key = Object.keys(MODEL_IMAGES).find(k =>
        modelName.toLowerCase().includes(k.toLowerCase()) ||
        k.toLowerCase().includes(modelName.toLowerCase())
    );
    return key ? MODEL_IMAGES[key] : '';
}

export default class TestDriveForm extends LightningElement {
    @track modelId = '';
    @track modelName = '';
    @track variantId = '';
    @track variantName = '';
    @track price = '';
    @track modelImageUrl = '';

    @track cities = [];
    @track firstName = '';
    @track lastName = '';
    @track email = '';
    @track phone = '';
    @track city = '';
    @track preferredDate = '';
    @track preferredTime = '';

    @track firstNameError = '';
    @track lastNameError = '';
    @track emailError = '';
    @track phoneError = '';
    @track cityError = '';
    @track dateError = '';
    @track timeError = '';
    @track errorMsg = '';

    @track submitting = false;
    @track submitted = false;

    get siteBase() {
        const path = window.location.pathname;
        const match = path.match(/^\/([^\/]+)/);
        const prefix = match ? match[1] : 'tatamotorscus';
        return window.location.origin + '/' + prefix;
    }

    navigate(page) {
        window.location.href = page ? `${this.siteBase}/${page}` : this.siteBase;
    }

    @wire(CurrentPageReference)
    handlePageRef() {
        const params = new URLSearchParams(window.location.search);
        this.modelId     = params.get('modelId')     || '';
        this.variantId   = params.get('variantId')   || '';
        this.variantName = params.get('variantName') || '';
        this.price       = params.get('price')       || '';

        // Decode model name properly
        const rawName    = params.get('modelName')   || '';
        this.modelName   = decodeURIComponent(rawName);

        // Set image immediately from model name using JSON map
        if (this.modelName) {
            this.modelImageUrl = getModelImage(this.modelName, '');
        }

        // Also fetch from org in case Image_URL__c is set
        if (this.modelId) {
            getModelById({ modelId: this.modelId })
                .then(m => {
                    if (m) {
                        this.modelImageUrl = getModelImage(m.Name, m.Image_URL__c);
                    }
                })
                .catch(() => {});
        }
    }

    @wire(getPortalCities)
    wiredCities({ data, error }) {
        if (data) this.cities = data;
        if (error) console.error('Cities error:', error);
    }

    get hasModel()   { return !!this.modelId || !!this.modelName; }

    get priceFormatted() {
        const num = parseFloat(this.price);
        return isNaN(num) ? '' : new Intl.NumberFormat('en-IN').format(num);
    }

    get minDate() {
        const d = new Date();
        d.setDate(d.getDate() + 1);
        return d.toISOString().split('T')[0];
    }

    get maxDate() {
        const d = new Date();
        d.setDate(d.getDate() + 30);
        return d.toISOString().split('T')[0];
    }

    get timeSlots() {
        return [
            { value: '09:00', label: '9:00 AM'  },
            { value: '10:00', label: '10:00 AM' },
            { value: '11:00', label: '11:00 AM' },
            { value: '12:00', label: '12:00 PM' },
            { value: '13:00', label: '1:00 PM'  },
            { value: '14:00', label: '2:00 PM'  },
            { value: '15:00', label: '3:00 PM'  },
            { value: '16:00', label: '4:00 PM'  },
            { value: '17:00', label: '5:00 PM'  },
            { value: '18:00', label: '6:00 PM'  }
        ];
    }

    fieldClass(hasError) { return hasError ? 'form-input error' : 'form-input'; }
    get firstNameClass() { return this.fieldClass(this.firstNameError); }
    get lastNameClass()  { return this.fieldClass(this.lastNameError);  }
    get emailClass()     { return this.fieldClass(this.emailError);     }
    get phoneClass()     { return this.fieldClass(this.phoneError);     }
    get cityClass()      { return this.fieldClass(this.cityError);      }
    get dateClass()      { return this.fieldClass(this.dateError);      }
    get timeClass()      { return this.fieldClass(this.timeError);      }

    handleFirstName(e) { this.firstName = e.target.value; this.firstNameError = ''; }
    handleLastName(e)  { this.lastName  = e.target.value; this.lastNameError  = ''; }
    handleEmail(e)     { this.email     = e.target.value; this.emailError     = ''; }
    handlePhone(e)     { this.phone     = e.target.value; this.phoneError     = ''; }
    handleCity(e)      { this.city      = e.target.value; this.cityError      = ''; }
    handleDate(e)      { this.preferredDate = e.target.value; this.dateError  = ''; }
    handleTime(e)      { this.preferredTime = e.target.value; this.timeError  = ''; }

    validate() {
        let valid = true;
        this.firstNameError = '';
        this.lastNameError  = '';
        this.emailError     = '';
        this.phoneError     = '';
        this.cityError      = '';
        this.dateError      = '';
        this.timeError      = '';
        this.errorMsg       = '';

        if (!this.firstName || this.firstName.trim().length < 2) {
            this.firstNameError = 'First name must be at least 2 characters';
            valid = false;
        }
        if (!this.lastName || this.lastName.trim().length < 2) {
            this.lastNameError = 'Last name must be at least 2 characters';
            valid = false;
        }
        if (!this.email || !this.email.includes('@')) {
            this.emailError = 'Enter a valid email address';
            valid = false;
        }
        const phoneReg = /^[6-9][0-9]{9}$/;
        if (!phoneReg.test(this.phone)) {
            this.phoneError = 'Enter a valid 10-digit mobile number starting with 6–9';
            valid = false;
        }
        if (!this.city) {
            this.cityError = 'Please select a city';
            valid = false;
        }
        if (!this.preferredDate) {
            this.dateError = 'Please select a date';
            valid = false;
        } else {
            const d = new Date(this.preferredDate);
            const day = d.getDay();
            if (day === 0 || day === 6) {
                this.dateError = 'Please select a weekday (Monday–Saturday)';
                valid = false;
            }
        }
        if (!this.preferredTime) {
            this.timeError = 'Please select a time slot';
            valid = false;
        }
        return valid;
    }

    handleSubmit() {
        if (!this.validate()) return;
        this.submitting = true;

        const dt = new Date(`${this.preferredDate}T${this.preferredTime}:00`);

        submitTestDriveRequest({
            firstName:         this.firstName.trim(),
            lastName:          this.lastName.trim(),
            email:             this.email.trim(),
            phone:             this.phone.trim(),
            city:              this.city,
            variantId:         this.variantId || null,
            modelId:           this.modelId   || null,
            preferredDateTime: dt.toISOString()
        })
        .then(result => {
            if (result === 'Success') {
                this.submitted = true;
            }
        })
        .catch(err => {
            this.errorMsg = err.body
                ? err.body.message
                : 'Something went wrong. Please try again.';
        })
        .finally(() => { this.submitting = false; });
    }

    goHome()   { this.navigate(''); }
    goModels() { this.navigate('models'); }
}