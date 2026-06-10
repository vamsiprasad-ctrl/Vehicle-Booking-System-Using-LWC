import { LightningElement, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getModelById from '@salesforce/apex/ModelController.getModelById';
import getVariantsByModel from '@salesforce/apex/ModelController.getVariantsByModel';

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

const VARIANT_IMAGES_BY_MODEL = {
    'Tata Sierra': [
        'https://imgd.aeplcdn.com/370x208/n/jeqddib_1893741.avif?q=80',
        'https://imgd.aeplcdn.com/370x208/n/3d5ddib_1893743.avif?q=80',
        'https://imgd.aeplcdn.com/370x208/n/crcedib_1893753.avif?q=80',
        'https://imgd.aeplcdn.com/370x208/n/wdeedib_1893755.avif?q=80',
        'https://imgd.aeplcdn.com/370x208/n/7mfedib_1893757.avif?q=80',
        'https://imgd.aeplcdn.com/370x208/n/9vhedib_1893759.avif?q=80',
        'https://imgd.aeplcdn.com/370x208/n/1bvddib_1893749.avif?q=80'
    ],
    'Sierra': [
        'https://imgd.aeplcdn.com/370x208/n/jeqddib_1893741.avif?q=80',
        'https://imgd.aeplcdn.com/370x208/n/3d5ddib_1893743.avif?q=80',
        'https://imgd.aeplcdn.com/370x208/n/crcedib_1893753.avif?q=80'
    ],
    'Nissan Gravite': [
        'https://imgd.aeplcdn.com/370x208/n/b4ku6ib_1907923.jpg?q=80',
        'https://imgd.aeplcdn.com/370x208/n/0h7u6ib_1907925.jpg?q=80',
        'https://imgd.aeplcdn.com/370x208/n/0ynu6ib_1907927.jpg?q=80',
        'https://imgd.aeplcdn.com/370x208/n/uu6u6ib_1907929.jpg?q=80',
        'https://imgd.aeplcdn.com/370x208/n/b8qu6ib_1907931.jpg?q=80'
    ],
    'Tata Punch EV': [
        'https://imgd.aeplcdn.com/370x208/n/cw/ec/217141/punch-ev-facelift-exterior-right-front-three-quarter-2.png?isig=0&q=80',
        'https://imgd.aeplcdn.com/370x208/n/cw/ec/217141/punch-ev-facelift-exterior-right-front-three-quarter-49.jpeg?isig=0&q=80',
        'https://imgd.aeplcdn.com/370x208/n/cw/ec/217141/punch-ev-facelift-exterior-right-front-three-quarter-53.jpeg?isig=0&q=80',
        'https://imgd.aeplcdn.com/370x208/n/cw/ec/217141/punch-ev-facelift-exterior-right-front-three-quarter-60.jpeg?isig=0&q=80',
        'https://imgd.aeplcdn.com/370x208/n/cw/ec/217141/punch-ev-facelift-exterior-right-front-three-quarter-64.jpeg?isig=0&q=80'
    ],
    'Punch EV': [
        'https://imgd.aeplcdn.com/370x208/n/cw/ec/217141/punch-ev-facelift-exterior-right-front-three-quarter-2.png?isig=0&q=80',
        'https://imgd.aeplcdn.com/370x208/n/cw/ec/217141/punch-ev-facelift-exterior-right-front-three-quarter-49.jpeg?isig=0&q=80'
    ],
    'Kia Seltos': [
        'https://imgd.aeplcdn.com/370x208/n/kck5heb_1763803.jpg?q=80',
        'https://imgd.aeplcdn.com/370x208/n/vp85heb_1763801.jpg?q=80',
        'https://imgd.aeplcdn.com/370x208/n/ngh5heb_1763799.jpg?q=80',
        'https://imgd.aeplcdn.com/370x208/n/5ln5heb_1763807.jpg?q=80',
        'https://imgd.aeplcdn.com/370x208/n/oeq5heb_1763811.jpg?q=80',
        'https://imgd.aeplcdn.com/370x208/n/qd65heb_1763809.jpg?q=80'
    ],
    'Mahindra Thar Roxx': [
        'https://imgd.aeplcdn.com/370x208/n/i3q4v9b_1808901.jpg?q=80',
        'https://imgd.aeplcdn.com/370x208/n/hy54v9b_1808903.jpg?q=80',
        'https://imgd.aeplcdn.com/370x208/n/0yv4v9b_1808909.jpg?q=80',
        'https://imgd.aeplcdn.com/370x208/n/11t4v9b_1808905.jpg?q=80',
        'https://imgd.aeplcdn.com/370x208/n/ciu4v9b_1808907.jpg?q=80',
        'https://imgd.aeplcdn.com/370x208/n/miauv9b_1808911.jpg?q=80',
        'https://imgd.aeplcdn.com/370x208/n/1bhuv9b_1808919.jpg?q=80'
    ],
    'Maruti Suzuki e Vitara': [
        'https://imgd.aeplcdn.com/370x208/n/vzhgcib_1892949.png?q=80',
        'https://imgd.aeplcdn.com/370x208/n/d98gcib_1892951.png?q=80',
        'https://imgd.aeplcdn.com/370x208/n/3zkgcib_1892953.png?q=80',
        'https://imgd.aeplcdn.com/370x208/n/qcngcib_1892957.png?q=80',
        'https://imgd.aeplcdn.com/370x208/n/bs6gcib_1892959.png?q=80'
    ]
};

function getModelImage(model) {
    if (model.Image_URL__c) return model.Image_URL__c;
    if (MODEL_IMAGES[model.Name]) return MODEL_IMAGES[model.Name];
    const key = Object.keys(MODEL_IMAGES).find(k =>
        model.Name.toLowerCase().includes(k.toLowerCase()) ||
        k.toLowerCase().includes(model.Name.toLowerCase())
    );
    return key ? MODEL_IMAGES[key] : '';
}

function getVariantImage(modelName, index) {
    if (VARIANT_IMAGES_BY_MODEL[modelName] && VARIANT_IMAGES_BY_MODEL[modelName][index]) {
        return VARIANT_IMAGES_BY_MODEL[modelName][index];
    }
    const key = Object.keys(VARIANT_IMAGES_BY_MODEL).find(k =>
        modelName.toLowerCase().includes(k.toLowerCase()) ||
        k.toLowerCase().includes(modelName.toLowerCase())
    );
    if (key && VARIANT_IMAGES_BY_MODEL[key][index]) return VARIANT_IMAGES_BY_MODEL[key][index];
    return '';
}

export default class ModelDetailPage extends LightningElement {
    @track model = null;
    @track variants = [];
    @track loading = true;
    @track loadingVariants = true;
    @track selectedVariantId = null;
    @track modelDisplayImage = '';

    modelId = null;
    modelName = '';

    get siteBase() {
        const path = window.location.pathname;
        const match = path.match(/^\/([^\/]+)/);
        const prefix = match ? match[1] : 'tatamotorscus';
        return window.location.origin + '/' + prefix;
    }

    navigate(page) { window.location.href = `${this.siteBase}/${page}`; }

    @wire(CurrentPageReference)
    handlePageRef() {
        const params = new URLSearchParams(window.location.search);
        this.modelId   = params.get('modelId');
        this.modelName = params.get('modelName') || '';
        if (this.modelId) {
            this.loadModel();
            this.loadVariants();
        } else {
            this.loading = false;
        }
    }

    loadModel() {
        getModelById({ modelId: this.modelId })
            .then(data => {
                this.model = data;
                this.modelDisplayImage = getModelImage(data);
                this.loading = false;
            })
            .catch(err => {
                console.error('Model error:', err);
                this.loading = false;
            });
    }

    loadVariants() {
        getVariantsByModel({ modelId: this.modelId })
            .then(data => {
                this.variants = data.map((v, index) => ({
                    ...v,
                    priceFormatted: v.Price__c
                        ? new Intl.NumberFormat('en-IN').format(v.Price__c)
                        : '—',
                    isSelected: false,
                    cardClass: 'variant-card',
                    variantImage: v.Image_URL__c || getVariantImage(this.modelName, index)
                }));
                this.loadingVariants = false;
            })
            .catch(err => {
                console.error('Variants error:', err);
                this.loadingVariants = false;
            });
    }

    get fuelOptions() {
        const fuels = [...new Set(this.variants.map(v => v.Fuel_Type__c).filter(f => f))];
        return fuels.join(' / ') || '—';
    }

    get transmissionOptions() {
        const t = [...new Set(this.variants.map(v => v.Transmission__c).filter(t => t))];
        return t.join(' / ') || '—';
    }

    get priceRange() {
        const prices = this.variants.map(v => v.Price__c).filter(p => p);
        if (!prices.length) return '—';
        const min = Math.min(...prices);
        const max = Math.max(...prices);
        const fmt = new Intl.NumberFormat('en-IN');
        return min === max ? `₹${fmt.format(min)}` : `₹${fmt.format(min)} – ₹${fmt.format(max)}`;
    }

    get selectedVariant() {
        return this.variants.find(v => v.Id === this.selectedVariantId) || null;
    }

    get noVariantSelected() { return !this.selectedVariantId; }

    get bookBtnClass() {
        return this.selectedVariantId ? 'btn-book active' : 'btn-book disabled';
    }

    selectVariant(event) {
        const id = event.currentTarget.dataset.id;
        this.selectedVariantId = id;
        this.variants = this.variants.map(v => ({
            ...v,
            isSelected: v.Id === id,
            cardClass: v.Id === id ? 'variant-card selected' : 'variant-card'
        }));
    }

    bookTestDrive() {
        if (!this.selectedVariantId || !this.model) return;
        const sv = this.selectedVariant;
        const params = [
            `modelId=${this.modelId}`,
            `modelName=${encodeURIComponent(this.model.Name)}`,
            `variantId=${sv.Id}`,
            `variantName=${encodeURIComponent(sv.Name)}`,
            `price=${sv.Price__c || ''}`
        ].join('&');
        this.navigate(`book-test-drive?${params}`);
    }

    goHome()   { window.location.href = this.siteBase; }
    goModels() { this.navigate('models'); }
}