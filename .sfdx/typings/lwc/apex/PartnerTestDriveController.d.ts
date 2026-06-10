declare module "@salesforce/apex/PartnerTestDriveController.getTestDrives" {
  export default function getTestDrives(param: {statusFilter: any}): Promise<any>;
}
declare module "@salesforce/apex/PartnerTestDriveController.getTodaysTestDrives" {
  export default function getTodaysTestDrives(): Promise<any>;
}
declare module "@salesforce/apex/PartnerTestDriveController.confirmTestDrive" {
  export default function confirmTestDrive(param: {testDriveId: any}): Promise<any>;
}
declare module "@salesforce/apex/PartnerTestDriveController.completeTestDrive" {
  export default function completeTestDrive(param: {testDriveId: any, notes: any}): Promise<any>;
}
declare module "@salesforce/apex/PartnerTestDriveController.cancelTestDrive" {
  export default function cancelTestDrive(param: {testDriveId: any}): Promise<any>;
}
declare module "@salesforce/apex/PartnerTestDriveController.getCurrentUserRole" {
  export default function getCurrentUserRole(): Promise<any>;
}
