public class ContactTriggerHandler {

    public static void afterInsert(List<Contact> newContacts) {
        if (Test.isRunningTest()) return;

        List<Contact> contactsWithEmail = new List<Contact>();
        for (Contact c : newContacts) {
            if (!String.isBlank(c.Email)) {
                contactsWithEmail.add(c);
            }
        }
        if (!contactsWithEmail.isEmpty()) {
            System.enqueueJob(
                new CommunityUserCreator(contactsWithEmail)
            );
        }
    }
}