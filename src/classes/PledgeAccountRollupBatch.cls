// created by Vladimir Martinov @ daizylogik
// account rollup batch job
global class PledgeAccountRollupBatch implements Database.Batchable<sObject>{
	private static final string STAGE = 'Pledged';

	private static string query = 'select id, Pledge_Payment_Amt_Recvd_Current_CY__c, ' +
											'Pledge_Payment_Amt_Recvd_Current_FY__c, ' +
											'Pledge_Payment_Amt_Recvd_Previous_CY__c, ' +
											'Pledge_Payment_Amt_Recvd_Previous_FY__c, ' +
											'Total_Pledges_Current_CY__c, ' +
											'Total_Pledges_Current_FY__c, ' +
											'Total_Pledges_Previous_CY__c, ' +
											'Total_Pledges_Previous_FY__c ' +
											'from Account';

	// web method
	webservice static void calculatePledgeAccountRollups() {
		PledgeAccountRollupBatch b = new PledgeAccountRollupBatch();
		Database.executeBatch(b);
	}
    
    // execute batchable
	global void execute(Database.BatchableContext bc, List<Account> scope) { 	 
 		calculateAccountRollups(scope);					
	}
	
	// query locator
	global database.Querylocator start(Database.BatchableContext bc) {
		return Database.getQueryLocator(query);		 
	}
	
	// finish
	global void finish(Database.BatchableContext bc) {
	
	}
	
	// do the rollup calculations
	public static void calculateAccountRollups(List<Account> accounts) {
		List<Opportunity> opportunities = [select id, AccountId, Amount, npe01__Payments_Made__c, CloseDate 
											from Opportunity 
											where StageName = :STAGE
											and AccountId in :accounts];

		Map<id, List<Opportunity>> opportunitiesByAccount = getRelatedOpportunities(opportunities);
		Map<id, List<npe01__OppPayment__c>> paymentsByAccount = getRelatedPayments(opportunities);
		
		for (Account account : accounts) {
			resetAccountTotals(account);
			addTotals(account, opportunitiesByAccount.get(account.id));
			addTotals(account, paymentsByAccount.get(account.id));
		}
		update accounts;
	}
	
	// get opportunities on accounts
	private static Map<id, List<Opportunity>> getRelatedOpportunities(List<Opportunity> opportunities) {
		Map<id, List<Opportunity>> opportunitiesByAccount = new Map<id, List<Opportunity>>();
		
		for (Opportunity opp : opportunities) {
			if (opportunitiesByAccount.containsKey(opp.AccountId)) {
				opportunitiesByAccount.get(opp.AccountId).add(opp);
			} else {
				opportunitiesByAccount.put(opp.AccountId, new List<Opportunity>{ opp });
			}
		}
		return opportunitiesByAccount;
	}
	
	// get payments on accounts
	private static Map<id, List<npe01__OppPayment__c>> getRelatedPayments(List<Opportunity> opportunities) {
		Map<id, List<npe01__OppPayment__c>> paymentsByAccount = new Map<id, List<npe01__OppPayment__c>>();
		
		List<npe01__OppPayment__c> payments = [select id, npe01__Payment_Amount__c, npe01__Opportunity__r.AccountId,
												npe01__Opportunity__r.CloseDate
												from npe01__OppPayment__c
												where npe01__Opportunity__c in :opportunities and npe01__Paid__c = true];
		
		for (npe01__OppPayment__c payment : payments) {
			if (paymentsByAccount.containsKey(payment.npe01__Opportunity__r.AccountId)) {
				paymentsByAccount.get(payment.npe01__Opportunity__r.AccountId).add(payment);
			} else {
				paymentsByAccount.put(payment.npe01__Opportunity__r.AccountId, new List<npe01__OppPayment__c>{ payment });
			}
		}
		return paymentsByAccount;
	}
	
	// add totals for account
	private static void addTotals(Account a, List<npe01__OppPayment__c> payments) {
		if (payments != null) {
			for (npe01__OppPayment__c payment : payments) {
				addTotals(a, payment);
			}
		}
	}
	
	// add totals for payment
	private static void addTotals(Account a, npe01__OppPayment__c payment) {
		if (PledgeRollupUtility.isInCurrentCY(payment.npe01__Opportunity__r.CloseDate)) {
			a.Pledge_Payment_Amt_Recvd_Current_CY__c += payment.npe01__Payment_Amount__c == null ? 0 : payment.npe01__Payment_Amount__c;
		}  
		
		if (PledgeRollupUtility.isInCurrentFY(payment.npe01__Opportunity__r.CloseDate)) {
			a.Pledge_Payment_Amt_Recvd_Current_FY__c += payment.npe01__Payment_Amount__c == null ? 0 : payment.npe01__Payment_Amount__c;
		} 
		
		if (PledgeRollupUtility.isInPreviousCY(payment.npe01__Opportunity__r.CloseDate)) {
			a.Pledge_Payment_Amt_Recvd_Previous_CY__c += payment.npe01__Payment_Amount__c == null ? 0 : payment.npe01__Payment_Amount__c;
		}
		
		if (PledgeRollupUtility.isInPreviousFY(payment.npe01__Opportunity__r.CloseDate)) {
			a.Pledge_Payment_Amt_Recvd_Previous_FY__c += payment.npe01__Payment_Amount__c == null ? 0 : payment.npe01__Payment_Amount__c;
		}
	}
	
	// add totals for account
	private static void addTotals(Account a, List<Opportunity> opportunities) {
		if (opportunities != null) {
			for (Opportunity opp : opportunities) {
				addTotals(a, opp);
			}
		}
	}
	
	//add totals for opp
	private static void addTotals(Account a, Opportunity opp) {
		if (PledgeRollupUtility.isInCurrentCY(opp.CloseDate)) {
			a.Total_Pledges_Current_CY__c += opp.Amount == null ? 0 : opp.Amount;
		}  
		
		if (PledgeRollupUtility.isInCurrentFY(opp.CloseDate)) {
			a.Total_Pledges_Current_FY__c += opp.Amount == null ? 0 : opp.Amount;
		} 
		
		if (PledgeRollupUtility.isInPreviousCY(opp.CloseDate)) {
			a.Total_Pledges_Previous_CY__c += opp.Amount == null ? 0 : opp.Amount;
		}
		
		if (PledgeRollupUtility.isInPreviousFY(opp.CloseDate)) {
			a.Total_Pledges_Previous_FY__c += opp.Amount == null ? 0 : opp.Amount;
		}
	}
	
	// clear totals
	private static void resetAccountTotals(Account a) {
		a.Pledge_Payment_Amt_Recvd_Current_CY__c = 0;
		a.Pledge_Payment_Amt_Recvd_Current_FY__c = 0;
		a.Pledge_Payment_Amt_Recvd_Previous_CY__c = 0;
		a.Pledge_Payment_Amt_Recvd_Previous_FY__c = 0;
		a.Total_Pledges_Current_CY__c = 0;
		a.Total_Pledges_Current_FY__c = 0;
		a.Total_Pledges_Previous_CY__c = 0;
		a.Total_Pledges_Previous_FY__c = 0;
	}
	
}