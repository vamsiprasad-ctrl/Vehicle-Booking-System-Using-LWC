import { LightningElement, api } from 'lwc';

const STATUS_MAP = {
    'Pending': 1, 'Under Approval': 2, 'Approved': 3, 'Delivered': 4, 'Cancelled': 0
};

const STEP_LABELS = ['Pending', 'Under Approval', 'Approved', 'Delivered'];

export default class BookingProgress extends LightningElement {
    @api status = 'Pending';

    get steps() {
        const curr = STATUS_MAP[this.status] || 0;
        return STEP_LABELS.map((label, i) => ({
            label, num: i + 1,
            done: i + 1 < curr,
            active: i + 1 === curr,
            last: i === STEP_LABELS.length - 1,
            cls: i + 1 < curr ? 'bp-step done' : (i + 1 === curr ? 'bp-step active' : 'bp-step')
        }));
    }
}