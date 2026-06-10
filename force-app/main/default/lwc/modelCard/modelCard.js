import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

const PILLS = {
    'sierra':['Petrol / EV','AWD','5-Star'],
    'punch-ev':['Electric','421km','Fast Charge'],
    'gravite':['Petrol/Diesel','7 Seater','4WD'],
    'seltos':['ADAS','Panoramic','5-Star'],
    'thar-roxx':['4x4','Off-Road','Diesel'],
    'nexon-ev':['Electric','453km','V2L'],
    'safari':['7 Seater','Diesel','Panoramic'],
    'altroz':['5-Star','Petrol','Sunroof'],
    'e-vitara':['Electric','500km','AWD'],
    'harrier-ev':['Electric','500km','AWD']
};

export default class ModelCard extends NavigationMixin(LightningElement) {
    @api car = {};
    @track wished = false;

    get priceFormatted() {
        if (!this.car || !this.car.price) return '';
        const l = this.car.price / 100000;
        return '&#8377;' + (Number.isInteger(l) ? l : l.toFixed(1)) + 'L';
    }
    get carPills() { return PILLS[this.car?.id] || []; }
    get tagClass() { return 'tag ' + (this.car?.tc || 'tnew'); }
    get wishClass() { return this.wished ? 'wish-btn wished' : 'wish-btn'; }
    get wishIcon() { return this.wished ? '❤️' : '🤍'; }

    handleClick() { this.handleExplore(); }
    handleExplore() { this.dispatchEvent(new CustomEvent('explore', { detail: { carId: this.car?.id }, bubbles: true, composed: true })); }
    handleTestDrive(e) { e.stopPropagation(); this.dispatchEvent(new CustomEvent('testdrive', { detail: { carId: this.car?.id }, bubbles: true, composed: true })); }
    handleWish(e) { e.stopPropagation(); this.wished = !this.wished; }
}