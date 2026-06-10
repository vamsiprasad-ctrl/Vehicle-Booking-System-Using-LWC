public class CommunityUserCreator implements Queueable {

    private List<Contact> contacts;

    public CommunityUserCreator(List<Contact> contacts) {
        this.contacts = contacts;
    }

    public void execute(QueueableContext context) {

        // Find customer portal profile
        List<Profile> profiles = [
            SELECT Id, Name FROM Profile
            WHERE Name IN (
                'Customer Community User',
                'Customer Community Plus Login',
                'Customer Community Login User',
                'Tata Motors Customer-Portal Profile'
            )
            LIMIT 1
        ];

        if (profiles.isEmpty()) {
            System.debug('No customer profile found');
            return;
        }

        Profile p = profiles[0];

        for (Contact con : contacts) {
            if (String.isBlank(con.Email)) continue;

            // Check if user already exists
            List<User> existing = [
                SELECT Id FROM User
                WHERE ContactId = :con.Id
                AND IsActive = true
                LIMIT 1
            ];
            if (!existing.isEmpty()) continue;

            // Check by email
            List<User> existingEmail = [
                SELECT Id FROM User
                WHERE Email = :con.Email
                AND ContactId != null
                LIMIT 1
            ];
            if (!existingEmail.isEmpty()) continue;

            // Generate unique username
            String username = con.Email.toLowerCase()
                + '.tatamotors'
                + String.valueOf(
                    Math.abs(Math.mod(
                        con.Email.hashCode(), 9999
                    ))
                )
                + '.com';

            // Generate alias
            String alias = '';
            if (con.FirstName != null) {
                alias = con.FirstName.left(1).toLowerCase();
            }
            alias = (alias + (con.LastName != null
                ? con.LastName.left(7) : 'cust'))
                .replaceAll('[^a-zA-Z0-9]', '')
                .left(8)
                .toLowerCase();
            if (String.isBlank(alias)) alias = 'cust';

            // Generate default password — Tata@ + 4 digits
            Integer hashNum = Math.abs(
                Math.mod(con.Email.hashCode(), 9000)
            ) + 1000;
            String defaultPassword = 'Tata@' + hashNum;

            try {
                // Create user
                User u = new User(
                    FirstName         = con.FirstName,
                    LastName          = con.LastName != null
                        ? con.LastName : 'Customer',
                    Email             = con.Email,
                    Username          = username,
                    Alias             = alias,
                    ProfileId         = p.Id,
                    ContactId         = con.Id,
                    TimeZoneSidKey    = 'Asia/Kolkata',
                    LocaleSidKey      = 'en_IN',
                    EmailEncodingKey  = 'UTF-8',
                    LanguageLocaleKey = 'en_US'
                );

                insert u;
                System.debug('User created: ' + u.Id);

                // Set password
                Boolean passwordSet = false;
                try {
                    System.setPassword(u.Id, defaultPassword);
                    passwordSet = true;
                    System.debug('Password set: ' + defaultPassword);
                } catch (Exception pwdEx) {
                    System.debug('Password set failed: '
                        + pwdEx.getMessage());
                    // Will use forgot password flow instead
                }

                // Send welcome email with credentials
                sendWelcomeEmail(
                    con.Email,
                    con.FirstName != null
                        ? con.FirstName : 'Customer',
                    username,
                    defaultPassword,
                    passwordSet
                );

            } catch (Exception e) {
                System.debug('User creation error: '
                    + e.getMessage());
            }
        }
    }

    private static void sendWelcomeEmail(
        String email,
        String firstName,
        String username,
        String defaultPassword,
        Boolean passwordSet
    ) {
        String portalUrl =
            'https://orgfarm-479a91b15c-dev-ed.develop.my.site.com/tatamotorscus';

        String body =
            'Dear ' + firstName + ',\n\n' +
            '🎉 Welcome to Tata Motors Customer Portal!\n\n' +
            'Your account has been created successfully.\n' +
            'You can now track your booking, make payments\n' +
            'and download receipts.\n\n' +
            '─────────────────────────────────\n' +
            'YOUR LOGIN CREDENTIALS\n' +
            '─────────────────────────────────\n' +
            'Portal URL : ' + portalUrl + '\n' +
            'Username   : ' + username + '\n' +
            'Password   : ' + defaultPassword + '\n\n' +
            '─────────────────────────────────\n\n' +
            'HOW TO LOGIN\n' +
            '─────────────────────────────────\n' +
            '1. Go to the Portal URL above\n' +
            '2. Enter your Username\n' +
            '3. Enter your Password: ' + defaultPassword + '\n' +
            '4. Click Login\n\n' +
            '⚠️  Please change your password after first login:\n' +
            '   My Profile → Change Password\n\n' +
            'If you face any issues:\n' +
            '1. Click Forgot Password on login page\n' +
            '2. Enter your email: ' + email + '\n' +
            '3. Check email and reset password\n\n' +
            'For help call us: 1800 209 7979\n\n' +
            'Warm Regards,\n' +
            'Tata Motors Digital Team';

        EmailUtility.sendEmail(
            email,
            '🚗 Welcome to Tata Motors Portal — Your Login Details',
            body
        );

        System.debug('Welcome email sent to: ' + email);
        System.debug('Username: ' + username);
        System.debug('Password: ' + defaultPassword);
    }
}