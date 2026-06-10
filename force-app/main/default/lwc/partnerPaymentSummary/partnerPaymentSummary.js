import { LightningElement, api } from 'lwc';

const fmt = n => new Intl.NumberFormat('en-IN').format(n || 0);

export default class PartnerPaymentSummary extends LightningElement {
    @api summary = {};

    get totalCollectedFmt() { return fmt(this.summary.totalCollected); }
    get thisMonthFmt()      { return fmt(this.summary.thisMonth); }
    get outstandingFmt()    { return fmt(this.summary.totalOutstanding); }
}