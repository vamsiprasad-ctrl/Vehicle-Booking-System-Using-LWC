import { LightningElement, wire, track } from 'lwc';
import getActiveModels from '@salesforce/apex/ModelController.getActiveModels';
import getVariantsByModel from '@salesforce/apex/ModelController.getVariantsByModel';
import getPortalStats from '@salesforce/apex/PortalController.getPortalStats';

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

const HERO_SLIDES = [
    {
        id: 'slide1',
        name: 'Tata Sierra',
        tagline: 'Iconic SUV reborn with modern technology',
        price: '20,00,000',
        image: 'https://imgd.aeplcdn.com/1056x594/n/cw/ec/193017/sierra-exterior-right-front-three-quarter-263.jpeg?isig=0&q=80'
    },
    {
        id: 'slide2',
        name: 'Tata Punch EV',
        tagline: "India's most affordable electric micro SUV",
        price: '10,00,000',
        image: 'https://imgd.aeplcdn.com/370x208/n/cw/ec/217141/punch-ev-facelift-exterior-right-front-three-quarter-2.png?isig=0&q=80'
    },
    {
        id: 'slide3',
        name: 'Nissan Gravite',
        tagline: 'Bold SUV with premium features and sporty design',
        price: '15,00,000',
        image: 'https://imgd.aeplcdn.com/370x208/n/cw/ec/200003/gravite-exterior-right-front-three-quarter-337.jpeg?isig=0&q=80'
    },
    {
        id: 'slide4',
        name: 'Mahindra Thar Roxx',
        tagline: 'Legendary off-road SUV with premium comfort',
        price: '13,00,000',
        image: 'https://imgd.aeplcdn.com/370x208/n/i3q4v9b_1808901.jpg?q=80'
    }
];

function getModelImage(model) {
    if (model.Image_URL__c) return model.Image_URL__c;
    if (MODEL_IMAGES[model.Name]) return MODEL_IMAGES[model.Name];
    const key = Object.keys(MODEL_IMAGES).find(k =>
        model.Name.toLowerCase().includes(k.toLowerCase()) ||
        k.toLowerCase().includes(model.Name.toLowerCase())
    );
    return key ? MODEL_IMAGES[key] : '';
}

export default class CustomerHomePage extends LightningElement {
    @track models = [];
    @track stats = {};
    @track loadingModels = true;
    @track currentSlide = 0;

    _timer = null;

    get heroSlides() {
        return HERO_SLIDES.map((s, i) => ({
            ...s,
            idx: i,
            slideClass: i === this.currentSlide
                ? 'slide active'
                : 'slide',
            dotClass: i === this.currentSlide
                ? 'dot active'
                : 'dot'
        }));
    }

    get siteBase() {
        const path = window.location.pathname;
        const match = path.match(/^\/([^\/]+)/);
        const prefix = match ? match[1] : 'tatamotorscus';
        return window.location.origin + '/' + prefix;
    }

    navigate(page) {
        window.location.href = page
            ? `${this.siteBase}/${page}`
            : this.siteBase;
    }

    connectedCallback() {
        this.startTimer();
    }

    disconnectedCallback() {
        this.stopTimer();
    }

    startTimer() {
        this._timer = setInterval(() => {
            this.currentSlide = (this.currentSlide + 1) % HERO_SLIDES.length;
        }, 5000);
    }

    stopTimer() {
        if (this._timer) {
            clearInterval(this._timer);
            this._timer = null;
        }
    }

    goToSlide(event) {
        const idx = parseInt(event.currentTarget.dataset.idx, 10);
        this.currentSlide = idx;
        this.stopTimer();
        this.startTimer();
    }

    @wire(getPortalStats)
    wiredStats({ data, error }) {
        if (data) this.stats = data;
        if (error) console.error('Stats error:', error);
    }

    @wire(getActiveModels)
    wiredModels({ data, error }) {
        this.loadingModels = false;
        if (data) {
            this.models = data.map(m => ({
                ...m,
                displayImage: getModelImage(m),
                startingPriceFormatted: '—',
                fuelLabel: 'Petrol / Diesel'
            }));
            this.loadVariantData(data);
        }
        if (error) console.error('Models error:', error);
    }

    loadVariantData(models) {
        models.forEach(model => {
            getVariantsByModel({ modelId: model.Id })
                .then(variants => {
                    if (!variants || variants.length === 0) return;
                    const prices = variants.map(v => v.Price__c).filter(p => p);
                    const minPrice = prices.length ? Math.min(...prices) : null;
                    const fuels = [...new Set(variants.map(v => v.Fuel_Type__c).filter(f => f))];
                    this.models = this.models.map(m => {
                        if (m.Id === model.Id) {
                            return {
                                ...m,
                                startingPriceFormatted: minPrice
                                    ? new Intl.NumberFormat('en-IN').format(minPrice)
                                    : '—',
                                fuelLabel: fuels.join(' / ')
                            };
                        }
                        return m;
                    });
                })
                .catch(err => console.error('Variant error:', err));
        });
    }

    openModel(event) {
        const modelId = event.currentTarget.dataset.id;
        if (!modelId) return;
        const model = this.models.find(m => m.Id === modelId);
        const name = model ? encodeURIComponent(model.Name) : '';
        this.navigate(`model-detail?modelId=${modelId}&modelName=${name}`);
    }

    goModels()    { this.navigate('models'); }
    goTestDrive() { this.navigate('book-test-drive'); }
}