import { LightningElement, api } from 'lwc';

export default class BookingSuccessPage extends LightningElement {
    @api modelName;
    @api variantName;

    handleNewBooking() {
        this.dispatchEvent(new CustomEvent('newbooking', {
            bubbles: true
        }));
    }
}