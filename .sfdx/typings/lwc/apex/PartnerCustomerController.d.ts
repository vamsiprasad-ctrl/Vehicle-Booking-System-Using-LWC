declare module "@salesforce/apex/PartnerCustomerController.getCustomers" {
  export default function getCustomers(param: {searchKey: any}): Promise<any>;
}
declare module "@salesforce/apex/PartnerCustomerController.getCustomerProfile" {
  export default function getCustomerProfile(param: {contactId: any}): Promise<any>;
}
declare module "@salesforce/apex/PartnerCustomerController.sendEmailToCustomer" {
  export default function sendEmailToCustomer(param: {contactId: any, subject: any, body: any}): Promise<any>;
}
declare module "@salesforce/apex/PartnerCustomerController.getCurrentUserRole" {
  export default function getCurrentUserRole(): Promise<any>;
}
