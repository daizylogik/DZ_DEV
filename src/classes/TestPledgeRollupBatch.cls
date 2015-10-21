// created by Vladimir Martinov @ daizylogik

@isTest
private class TestPledgeRollupBatch {

	// test the schedulable job
	@isTest static void testPledgeRollups() {
		Test.startTest();
		SchedulableContext sc;
		PledgeRollupBatch p = new PledgeRollupBatch();
		p.execute(sc);
		Test.stopTest();
		
		system.assert(true);
	}
    
	// test the account rollups
    @isTest static void testCalculateAccountRollups() {
    	Account a = createAccount();
    	Contact c = createContact();
        createOpportunitiesAndPayments(a, c);
        
		// run job
		Test.startTest();
		PledgeAccountRollupBatch.calculatePledgeAccountRollups();
		Test.stopTest();
		
		a = [select id, dz_Pledge_Payment_Amt_Recvd_Current_CY__c,
						dz_Pledge_Payment_Amt_Recvd_Current_FY__c,
						dz_Pledge_Payment_Amt_Recvd_Previous_CY__c,
						dz_Pledge_Payment_Amt_Recvd_Previous_FY__c,
						dz_Total_Pledges_Current_CY__c,
						dz_Total_Pledges_Current_FY__c,
						dz_Total_Pledges_Previous_CY__c,
						dz_Total_Pledges_Previous_FY__c
						from Account where id = :a.id];
						
		// pledge totals
		system.assertEquals(190, a.dz_Total_Pledges_Current_CY__c);
		system.assertEquals(110, a.dz_Total_Pledges_Previous_CY__c);
		system.assertEquals(40, a.dz_Total_Pledges_Current_FY__c);
		system.assertEquals(150, a.dz_Total_Pledges_Previous_FY__c);
		
		// payment totals
		system.assertEquals(109, a.dz_Pledge_Payment_Amt_Recvd_Current_CY__c);
		system.assertEquals(65, a.dz_Pledge_Payment_Amt_Recvd_Previous_CY__c);
		system.assertEquals(10, a.dz_Pledge_Payment_Amt_Recvd_Current_FY__c);
		system.assertEquals(99, a.dz_Pledge_Payment_Amt_Recvd_Previous_FY__c);
    }
    
    // test the account rollups
    @isTest static void testCalculateContactRollups() {
    	Account a = createAccount();
    	Contact c = createContact();
        createOpportunitiesAndPayments(a, c);
    	
    	// run job
		Test.startTest();
		PledgeContactRollupBatch.calculatePledgeContactRollups();
		Test.stopTest();
		
    	c = [select id, dz_Pledge_Payment_Amt_Recvd_Current_CY__c,
						dz_Pledge_Payment_Amt_Recvd_Current_FY__c,
						dz_Pledge_Payment_Amt_Recvd_Previous_CY__c,
						dz_Pledge_Payment_Amt_Recvd_Previous_FY__c,
						dz_Total_Pledges_Current_CY__c,
						dz_Total_Pledges_Current_FY__c,
						dz_Total_Pledges_Previous_CY__c,
						dz_Total_Pledges_Previous_FY__c
						from Contact where id = :c.id];
						
		// pledge totals
		system.assertEquals(190, c.dz_Total_Pledges_Current_CY__c);
		system.assertEquals(110, c.dz_Total_Pledges_Previous_CY__c);
		system.assertEquals(40, c.dz_Total_Pledges_Current_FY__c);
		system.assertEquals(150, c.dz_Total_Pledges_Previous_FY__c);
		
		// payment totals
		system.assertEquals(109, c.dz_Pledge_Payment_Amt_Recvd_Current_CY__c);
		system.assertEquals(65, c.dz_Pledge_Payment_Amt_Recvd_Previous_CY__c);
		system.assertEquals(10, c.dz_Pledge_Payment_Amt_Recvd_Current_FY__c);
		system.assertEquals(99, c.dz_Pledge_Payment_Amt_Recvd_Previous_FY__c);
    }
    
    // create opps and payments
    private static void createOpportunitiesAndPayments(Account a, contact c) {
    	List<Opportunity> opportunities = new List<Opportunity>();
        List<npe01__OppPayment__c> payments = new List<npe01__OppPayment__c>();
        List<OpportunityContactRole> oppContactRoles = new List<OpportunityContactRole>();
        
        // this CY; prev FY
        date closeDate1 = date.newInstance(date.today().year(), 4, 15);
		Opportunity opp1 = addOpportunity(opportunities, a, closeDate1, 100, 'Pledged');
		date closeDate2 = date.newInstance(date.today().year(), 4, 16);
		Opportunity opp2 = addOpportunity(opportunities, a, closeDate2, 50, 'Pledged');
		
        // last CY
        date closeDate3 = date.newInstance(date.today().addYears(-1).year(), 4, 15);
		Opportunity opp3 = addOpportunity(opportunities, a, closeDate3, 80, 'Pledged');
		date closeDate4 = date.newInstance(date.today().addYears(-1).year(), 4, 16);
		Opportunity opp4 = addOpportunity(opportunities, a, closeDate4, 30, 'Pledged');
		
		// current FY and CY
        date closeDate5 = date.newInstance(date.today().year(), 7, 15);
		Opportunity opp5 = addOpportunity(opportunities, a, closeDate5, 15, 'Pledged');
		date closeDate6 = date.newInstance(date.today().year(), 7, 16);
		Opportunity opp6 = addOpportunity(opportunities, a, closeDate6, 25, 'Pledged');
		date closeDate7 = date.newInstance(date.today().year(), 7, 17);
		Opportunity opp7 = addOpportunity(opportunities, a, closeDate7, 1000 ,'Prospecting');
		
        insert opportunities;
        
        addPayment(payments, opportunities[0], true, 99, closeDate1);
		addPayment(payments, opportunities[0], false, 2, closeDate1);
        addPayment(payments, opportunities[2], true, 40, closeDate3);
		addPayment(payments, opportunities[2], true, 25, date.today().addYears(5));
		addPayment(payments, opportunities[5], true, 10, closeDate6);
		addPayment(payments, opportunities[6], true, 1000, closeDate7);
		
		insert payments;
		
		addOpportunityContactRole(oppContactRoles, c, opportunities[0]);
		addOpportunityContactRole(oppContactRoles, c, opportunities[1]);
		addOpportunityContactRole(oppContactRoles, c, opportunities[2]);
		addOpportunityContactRole(oppContactRoles, c, opportunities[3]);
		addOpportunityContactRole(oppContactRoles, c, opportunities[4]);
		addOpportunityContactRole(oppContactRoles, c, opportunities[5]);
		addOpportunityContactRole(oppContactRoles, c, opportunities[6]);
		
		insert oppContactRoles;
	}
    
    // create a contact
    private static Contact createContact() {
    	Contact c = new Contact(Lastname = 'test');
    	insert c;
    	return c;
    }
    
    // create account
    private static Account createAccount() {
    	Account a = new Account(Name = 'test');
    	insert a;
    	return a;
    }
    
    // add an opp to the list
    private static Opportunity addOpportunity(List<Opportunity> opportunities, Account account, date closeDate, decimal amount, string stage) {
    	Opportunity opp = createOpportunity(account, closeDate, amount, stage);
    	opportunities.add(opp);
    	return opp;
    }
    
    // create opp
    private static Opportunity createOpportunity(Account account, date closeDate, decimal amount, string stage) {
    	Opportunity opp = new Opportunity(AccountId = account.id, CloseDate = closeDate, Amount = amount, Name='test', StageName=stage);
    	return opp;
    }
    
    // create an opp contact role
    private static OpportunityContactRole createOpportunityContactRole(Contact c, Opportunity opp) {
    	OpportunityContactRole oppContactRole = new OpportunityContactRole(ContactId = c.id, OpportunityId = opp.id, IsPrimary = true);
    	return oppContactRole;
    }
    
    // add opp contact role
    private static OpportunityContactRole addOpportunityContactRole(List<OpportunityContactRole> oppContactRoles, Contact c, Opportunity opp) {
    	OpportunityContactRole oppContactRole = createOpportunityContactRole(c, opp);
    	oppContactRoles.add(oppContactRole);
    	return oppContactRole;
    }
    
    // add a payment
    private static npe01__OppPayment__c addPayment(List<npe01__OppPayment__c> payments, Opportunity opp, boolean paid, decimal amount, date dt) {
    	npe01__OppPayment__c payment = createPayment(opp, paid, amount, dt);
    	payments.add(payment);
    	return payment;
    }
    
    // create a new payment
    private static npe01__OppPayment__c createPayment(Opportunity opp, boolean paid, decimal amount, date dt) {
    	npe01__OppPayment__c payment = new npe01__OppPayment__c(npe01__Opportunity__c = opp.id,
    															npe01__Paid__c = paid,
    															npe01__Payment_Amount__c = amount,
    															npe01__Payment_Date__c = dt);
    	return payment;
    }
    
}