declare module "@salesforce/apex/PartnerBookingController.getBookings" {
  export default function getBookings(param: {statusFilter: any}): Promise<any>;
}
declare module "@salesforce/apex/PartnerBookingController.getPendingApprovals" {
  export default function getPendingApprovals(): Promise<any>;
}
declare module "@salesforce/apex/PartnerBookingController.approveBooking" {
  export default function approveBooking(param: {bookingId: any}): Promise<any>;
}
declare module "@salesforce/apex/PartnerBookingController.rejectBooking" {
  export default function rejectBooking(param: {bookingId: any, reason: any}): Promise<any>;
}
declare module "@salesforce/apex/PartnerBookingController.markDelivered" {
  export default function markDelivered(param: {bookingId: any}): Promise<any>;
}
declare module "@salesforce/apex/PartnerBookingController.getPaymentsByBooking" {
  export default function getPaymentsByBooking(param: {bookingId: any}): Promise<any>;
}
declare module "@salesforce/apex/PartnerBookingController.getCurrentUserRole" {
  export default function getCurrentUserRole(): Promise<any>;
}
