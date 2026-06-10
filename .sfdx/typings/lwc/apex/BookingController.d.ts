declare module "@salesforce/apex/BookingController.getMyBookings" {
  export default function getMyBookings(): Promise<any>;
}
declare module "@salesforce/apex/BookingController.getPaymentsByBooking" {
  export default function getPaymentsByBooking(param: {bookingId: any}): Promise<any>;
}
declare module "@salesforce/apex/BookingController.getMyTestDrives" {
  export default function getMyTestDrives(): Promise<any>;
}
declare module "@salesforce/apex/BookingController.getMyContact" {
  export default function getMyContact(): Promise<any>;
}
declare module "@salesforce/apex/BookingController.getBookingReceipt" {
  export default function getBookingReceipt(param: {bookingId: any}): Promise<any>;
}
declare module "@salesforce/apex/BookingController.getMyDashboardKPIs" {
  export default function getMyDashboardKPIs(): Promise<any>;
}
