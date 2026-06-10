import { LightningElement, wire, track } from 'lwc';
import getMyOpportunities
    from '@salesforce/apex/DashboardController.getMyOpportunities';

const STAGE_PROGRESS = {
    'Qualification':    'width:20%',
    'Needs Analysis':   'width:35%',
    'Quotation Sent':   'width:50%',
    'Negotiation':      'width:70%',
    'Booking Confirmed':'width:90%',
    'Closed Won':       'width:100%'
};

export default class OpportunityPipeline extends LightningElement {
    @track opportunities = [];
    @track noOpps        = false;

    @wire(getMyOpportunities)
    wiredOpps({ error, data }) {
        if (data) {
            this.opportunities = data.map(opp => ({
                ...opp,
                progressStyle:
                    STAGE_PROGRESS[opp.StageName] || 'width:10%'
            }));
            this.noOpps = data.length === 0;
        } else if (error) {
            console.error('opportunityPipeline error:', error);
            this.noOpps = true;
        }
    }
}