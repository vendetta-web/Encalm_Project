import { LightningElement, track } from 'lwc';
import getQueues from '@salesforce/apex/QueueMemberController.getQueues';
import getQueueUsers from '@salesforce/apex/QueueMemberController.getQueueUsers';
import getAllUsers from '@salesforce/apex/QueueMemberController.getAllUsers';
import addUsersToQueue from '@salesforce/apex/QueueMemberController.addUsersToQueue';
import removeUsersFromQueue from '@salesforce/apex/QueueMemberController.removeUsersFromQueue';
import getUsersByIds from '@salesforce/apex/QueueMemberController.getUsersByIds';

export default class QueueMemberManager extends LightningElement {
    @track queueOptions = [];
    @track userOptions = [];
    @track selectedUserIds = [];
    @track selectedQueueId;
    @track showUserLists = false;    
    @track showView = false;
    @track showEdit = false;
    @track queueMembers = [];
    @track isModalOpen = true;
    @track viewColumns = [
        { label: 'Name', fieldName: 'Name', type: 'text' },
        { label: 'Role', fieldName: 'Role', type: 'text' },
    ];

    connectedCallback() {
        console.log('isModalOpen',this.isModalOpen);
        getQueues().then(result => {
            this.queueOptions = result.map(q => ({
                label: q.Name,
                value: q.Id
            }));
        }).catch(error => {
            console.error('Error fetching queues:', error);
        });
    }

    async handleQueueChange(event) {
        this.selectedQueueId = event.detail.value;
        this.showView = true;
        this.showEdit = false;
        this.showViewSection();
    }

    async loadQueueMembers() {
        if (!this.selectedQueueId) return;

        try {
            const [queueUsers, allUsers] = await Promise.all([
                getQueueUsers({ queueId: this.selectedQueueId }),
                getAllUsers()
            ]);

            this.userOptions = allUsers.map(user => ({
                label: user.Name,
                value: user.Id
            }));

            this.queueMembers = queueUsers;
            this.selectedUserIds = queueUsers.map(u => u.UserOrGroupId);
            this.showUserLists = true;

        } catch (error) {
            console.error('Error loading queue members:', error);
        }
    }

    handleUserSelection(event) {
        this.selectedUserIds = event.detail.value;
    }

    async saveChanges() {
        const currentMemberIds = this.queueMembers.map(u => u.UserOrGroupId);
        const toAdd = this.selectedUserIds.filter(id => !currentMemberIds.includes(id));
        const toRemove = currentMemberIds.filter(id => !this.selectedUserIds.includes(id));

        try {
            const promises = [];

            if (toAdd.length > 0) {
                promises.push(addUsersToQueue({ queueId: this.selectedQueueId, userIds: toAdd }));
            }

            if (toRemove.length > 0) {
                promises.push(removeUsersFromQueue({ queueId: this.selectedQueueId, userIds: toRemove }));
            }

            await Promise.all(promises); // Wait for add/remove to complete
            await this.loadQueueMembers(); // Wait for refresh before cancel

            this.handleCancel(); // Now close/hide the edit section

        } catch (error) {
            console.error('Error saving queue changes:', error);
        }
    }


    async showViewSection() {

        try {
            const groupMembers = await getQueueUsers({ queueId: this.selectedQueueId });
            const userIds = groupMembers.map(member => member.UserOrGroupId);
            const users = await getUsersByIds({ userIds });

            this.queueMembers = users.map(user => ({
                Id: user.Id,
                Name: user.Name,
                Role: user.UserRole ? user.UserRole.Name : 'N/A'
            }));
        } catch (error) {
            console.error('Error loading view section:', error);
        }
    }

    showEditSection() {
        this.showEdit = true;
        this.showView = false;
        this.loadQueueMembers();
    }

    closeModal() {
        this.isModalOpen = false;
    }
    async handleCancel(){
        
        this.showView = true;
        this.showEdit = false;
        await this.showViewSection();
        
    }
}