@isTest
Public class QueueMemberControllerTest {
    
    @testSetup
    static void setupTestData() {
        // Create a queue
        Group queue = new Group(Name = 'Test Queue', Type = 'Queue');
        insert queue;
        String testQueueId = queue.Id;
        
        // Create users
        List<User> testUsers = new List<User>();
        for (Integer i = 0; i < 3; i++) {
            testUsers.add(new User(
                Alias = 'user' + i,
                Email = 'user' + i + '@test.com',
                Username = 'user' + i + '@test.com.' + System.currentTimeMillis(),
                LastName = 'User' + i,
                TimeZoneSidKey = 'America/New_York',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                ProfileId = UserInfo.getProfileId(),
                LanguageLocaleKey = 'en_US'
            ));
        }
        insert testUsers;
        List<Id> userIds = new List<Id>();
        for (User u : testUsers) {
            userIds.add(u.Id);
        }
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        
        // Create a single admin user
        User adminUser = new User(
            Alias = 'admin',
            Email = 'admin@test.com',
            Username = 'admin@test.com.' + System.currentTimeMillis(),
            LastName = 'AdminUser',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = adminProfile.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert adminUser;
        
        // Add 1 user to queue
        insert new GroupMember(GroupId = queue.Id, UserOrGroupId = userIds[0]);
    }
    
    @isTest
    static void testGetQueues() {
        List<Group> queues = QueueMemberController.getQueues();
        System.assertNotEquals(0, queues.size(), 'Queues should be returned');
    }
    
    @isTest
    static void testGetQueueUsers() {
        String testQueueId = [SELECT id FROM Group LIMIT 1].Id;
        List<GroupMember> members = QueueMemberController.getQueueUsers(testQueueId);
    }
    
    @isTest
    static void testGetAllUsers() {
        List<User> users = QueueMemberController.getAllUsers();
        System.assert(users.size() > 0, 'Should return active standard users');
    }
    
    @isTest
    static void testRemoveUsersFromQueue() {
        User adminnUser = [SELECT Id from User WHERE Email = 'admin@test.com' LIMIT 1];
        String testQueueId = [SELECT id FROM Group LIMIT 1].Id;
        List<User> users = [SELECT Id FROM User WHERE LastName IN  ('User0','User1','User2')];
        List<Id> toAdd = new List<Id>();
        for (User u : users) {
            toAdd.add(u.Id);
        }
        System.runAs(adminnUser){
            QueueMemberController.addUsersToQueue(testQueueId, toAdd);
            
            Test.startTest();
            QueueMemberController.removeUsersFromQueue(testQueueId, toAdd);
            Test.stopTest();
        }
        
        List<GroupMember> membersAfter = QueueMemberController.getQueueUsers(testQueueId);
        System.assertEquals(0, membersAfter.size(), 'Users should be removed from queue');
    }
    
    @isTest
    static void testGetUsersByIds() {
        List<User> users = [SELECT Id FROM User WHERE LastName LIKE 'User%'];
        List<Id> toAdd = new List<Id>();
        for (User u : users) {
            toAdd.add(u.Id);
        }
        List<User> fetchedUsers = QueueMemberController.getUsersByIds(toAdd);
        System.assertEquals(toAdd.size(), fetchedUsers.size(), 'Should return all users by IDs');
    }
}