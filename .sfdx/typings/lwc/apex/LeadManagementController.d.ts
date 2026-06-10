declare module "@salesforce/apex/LeadManagementController.getLeads" {
  export default function getLeads(param: {statusFilter: any}): Promise<any>;
}
declare module "@salesforce/apex/LeadManagementController.getSalesExecutives" {
  export default function getSalesExecutives(): Promise<any>;
}
declare module "@salesforce/apex/LeadManagementController.updateLeadStatus" {
  export default function updateLeadStatus(param: {leadId: any, newStatus: any}): Promise<any>;
}
declare module "@salesforce/apex/LeadManagementController.assignLead" {
  export default function assignLead(param: {leadId: any, newOwnerId: any}): Promise<any>;
}
declare module "@salesforce/apex/LeadManagementController.convertLead" {
  export default function convertLead(param: {leadId: any}): Promise<any>;
}
declare module "@salesforce/apex/LeadManagementController.getLeadById" {
  export default function getLeadById(param: {leadId: any}): Promise<any>;
}
