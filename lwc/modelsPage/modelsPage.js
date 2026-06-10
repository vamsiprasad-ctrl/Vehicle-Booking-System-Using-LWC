import { LightningElement, wire, track } from 'lwc';
import getActiveModels from '@salesforce/apex/ModelController.getActiveModels';
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

function getModelImage(model) {
    if (model.Image_URL__c) return model.Image_URL__c;
    if (MODEL_IMAGES[model.Name]) return MODEL_IMAGES[model.Name];
    const key = Object.keys(MODEL_IMAGES).find(k =>
        model.Name.toLowerCase().includes(k.toLowerCase()) ||
        k.toLowerCase().includes(model.Name.toLowerCase())
    );
    return key ? MODEL_IMAGES[key] : '';
}

export default class ModelsPage extends LightningElement {
    @track allModels = [];
    @track filteredModels = [];
    @track loading = true;
    @track activeFilter = 'all';

    get siteBase() {
        const path = window.location.pathname;
        const match = path.match(/^\/([^\/]+)/);
        const prefix = match ? match[1] : 'tatamotorscus';
        return window.location.origin + '/' + prefix;
    }

    navigate(page) { window.location.href = `${this.siteBase}/${page}`; }

    get isEmpty() { return !this.loading && this.filteredModels.length === 0; }

    get allBtnClass()      { return this.activeFilter === 'all'      ? 'filter-btn active' : 'filter-btn'; }
    get petrolBtnClass()   { return this.activeFilter === 'Petrol'   ? 'filter-btn active' : 'filter-btn'; }
    get dieselBtnClass()   { return this.activeFilter === 'Diesel'   ? 'filter-btn active' : 'filter-btn'; }
    get electricBtnClass() { return this.activeFilter === 'Electric' ? 'filter-btn active' : 'filter-btn'; }
    get cngBtnClass()      { return this.activeFilter === 'CNG'      ? 'filter-btn active' : 'filter-btn'; }

    @wire(getActiveModels)
    wiredModels({ data, error }) {
        this.loading = false;
        if (data) {
            this.allModels = data.map(m => ({
                ...m,
                displayImage: getModelImage(m),
                startingPrice: '—',
                variantCount: '—',
                fuelTypes: [],
                _fuels: []
            }));
            this.filteredModels = [...this.allModels];
            this.enrichModels(data);
        }
        if (error) console.error('Models error:', error);
    }

    enrichModels(models) {
        let completed = 0;
        models.forEach(model => {
            getVariantsByModel({ modelId: model.Id })
                .then(variants => {
                    const prices = variants.map(v => v.Price__c).filter(p => p);
                    const fuels  = [...new Set(variants.map(v => v.Fuel_Type__c).filter(f => f))];
                    const minP   = prices.length ? Math.min(...prices) : null;
                    const updated = {
                        startingPrice: minP ? new Intl.NumberFormat('en-IN').format(minP) : '—',
                        variantCount: variants.length,
                        fuelTypes: fuels,
                        _fuels: fuels
                    };
                    this.allModels = this.allModels.map(m =>
                        m.Id === model.Id ? { ...m, ...updated } : m
                    );
                    completed++;
                    if (completed === models.length) this.applyFilter();
                })
                .catch(() => { completed++; });
        });
    }

    filterByFuel(event) {
        this.activeFilter = event.currentTarget.dataset.fuel;
        this.applyFilter();
    }

    applyFilter() {
        if (this.activeFilter === 'all') {
            this.filteredModels = [...this.allModels];
        } else {
            this.filteredModels = this.allModels.filter(m =>
                m._fuels && m._fuels.includes(this.activeFilter)
            );
        }
    }

    resetFilter() {
        this.activeFilter = 'all';
        this.filteredModels = [...this.allModels];
    }

    openModel(event) {
        const modelId = event.currentTarget.dataset.id;
        if (!modelId) return;
        const model = this.allModels.find(m => m.Id === modelId);
        const name = model ? encodeURIComponent(model.Name) : '';
        this.navigate(`model-detail?modelId=${modelId}&modelName=${name}`);
    }

    goHome() { window.location.href = this.siteBase; }
}