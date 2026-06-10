declare module "@salesforce/apex/PaymentController.processPayment" {
  export default function processPayment(param: {bookingId: any, paymentAmount: any, paymentMethod: any}): Promise<any>;
}
declare module "@salesforce/apex/PaymentController.getRemainingBalance" {
  export default function getRemainingBalance(param: {bookingId: any}): Promise<any>;
}
