({
    handleRefresh: function(component, event, helper) {
        console.log('Refreshing Lightning record page...');
        $A.get("e.force:refreshView").fire();
    }
})