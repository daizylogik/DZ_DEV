// created by Vladimir Martinov @ daizylogik
// contact rollup batch job
global class PledgeContactRollupBatch implements Database.Batchable<sObject>{
	private static final string STAGE = 'Pledged';

	private static string query = 'select id, Pledge_Payment_Amt_Recvd_Current_CY__c, ' +
											'Pledge_Payment_Amt_Recvd_Current_FY__c, ' +
											'Pledge_Payment_Amt_Recvd_Previous_CY__c, ' +
											'Pledge_Payment_Amt_Recvd_Previous_FY__c, ' +
											'Total_Pledges_Current_CY__c, ' +
											'Total_Pledges_Current_FY__c, ' +
											'Total_Pledges_Previous_CY__c, ' +
											'Total_Pledges_Previous_FY__c ' +
											'from Contact';

	// web method
	webservice static void calculatePledgeContactRollups() {
		PledgeContactRollupBatch b = new PledgeContactRollupBatch();
		Database.executeBatch(b);
	}
	
    // execute batchable
	global void execute(Database.BatchableContext bc, List<Contact> scope) { 	 
 		calculateContactRollups(scope);					
	}
	
	// query locator
	global database.Querylocator start(Database.BatchableContext bc) {
		return Database.getQueryLocator(query);		 
	}
	
	// finish
	global void finish(Database.BatchableContext bc) {
	
	}
	
	// do the rollup calculations
	public static void calculateContactRollups(List<Contact> contacts) {
		List<OpportunityContactRole> oppContactRoles = [select id, OpportunityId, ContactId from OpportunityContactRole
														where ContactId in :contacts and IsPrimary = true];
		Set<id> opportunityIdsSet = new Set<id>();
		Map<id, List<id>> opportunityIdsByContact = new Map<id, List<id>>();
		for (OpportunityContactRole ocr : oppContactRoles) {
			opportunityIdsSet.add(ocr.OpportunityId);
			if (opportunityIdsByContact.containsKey(ocr.ContactId)) {
				opportunityIdsByContact.get(ocr.ContactId).add(ocr.OpportunityId);
			} else {
				opportunityIdsByContact.put(ocr.ContactId, new List<id> { ocr.OpportunityId });
			}
		}
		Map<id, Opportunity> opportunitiesMap = new Map<id, Opportunity>([select id, Amount, npe01__Payments_Made__c, CloseDate 
																		from Opportunity 
																		where StageName = :STAGE
																		and id in :opportunityIdsSet]);
		
		Map<id, List<Opportunity>> opportunitiesByContact = getRelatedOpportunities(opportunityIdsByContact, opportunitiesMap);
		Map<id, List<npe01__OppPayment__c>> paymentsByContact = getRelatedPayments(opportunityIdsByContact, opportunitiesMap);
		
		for (Contact contact : contacts) {
			resetContactTotals(contact);
			addTotals(contact, opportunitiesByContact.get(contact.id));
			addTotals(contact, paymentsByContact.get(contact.id));
		}
		update contacts;
	}
	
	// get opportunities on contacts
	private static Map<id, List<Opportunity>> getRelatedOpportunities(Map<id, List<id>> opportunityIdsByContact, 
																	  Map<id, Opportunity> opportunitiesMap) {
		
		Map<id, List<Opportunity>> opportunitiesByContact = new Map<id, List<Opportunity>>();
		
		for (id contactId : opportunityIdsByContact.keySet()) {
			for (id oppId : opportunityIdsByContact.get(contactid)) {
				Opportunity opp = opportunitiesMap.get(oppId);
				if (opp != null) {
					if (opportunitiesByContact.containsKey(contactId)) {
						opportunitiesByContact.get(contactId).add(opp);
					} else {
						opportunitiesByContact.put(contactId, new List<Opportunity>{ opp });
					}
				}
			} 
		}
		return opportunitiesByContact;
	}
	
	// get related payments
	private static Map<id, List<npe01__OppPayment__c>> getRelatedPayments(Map<id, List<id>> opportunityIdsByContact, 
																		  Map<id, Opportunity> opportunitiesMap) {
																			
		Map<id, List<npe01__OppPayment__c>> paymentsByContact = new Map<id, List<npe01__OppPayment__c>>();
		
		List<npe01__OppPayment__c> payments = [select id, npe01__Payment_Amount__c, npe01__Opportunity__r.CloseDate, npe01__Opportunity__c
												from npe01__OppPayment__c
												where npe01__Opportunity__c in :opportunitiesMap.keySet() and npe01__Paid__c = true];
												
		Map<id, List<npe01__OppPayment__c>> paymentByOppId = new Map<id, List<npe01__OppPayment__c>>();
		for (npe01__OppPayment__c payment : payments) {
			if (paymentByOppId.containsKey(payment.npe01__Opportunity__c)) {
				paymentByOppId.get(payment.npe01__Opportunity__c).add(payment);
			} else {
				paymentByOppId.put(payment.npe01__Opportunity__c, new List<npe01__OppPayment__c> { payment });
			}
		}
		
		for (id contactId : opportunityIdsByContact.keySet()) {
			for (id oppId : opportunityIdsByContact.get(contactid)) {
				List<npe01__OppPayment__c> paymentsList = paymentByOppId.get(oppId);
				if (paymentsList != null) {
					for (npe01__OppPayment__c payment : paymentsList) {
						if (paymentsByContact.containsKey(contactId)) {
							paymentsByContact.get(contactId).add(payment);
						} else {
							paymentsByContact.put(contactId, new List<npe01__OppPayment__c>{ payment });
						}
					}
				}	
			} 
		}
		return paymentsByContact;
	}
	
	// add totals for contact
	private static void addTotals(Contact c, List<npe01__OppPayment__c> payments) {
		if (payments != null) {
			for (npe01__OppPayment__c payment : payments) {
				addTotals(c, payment);
			}
		}
	}
	
	// add totals for payment
	private static void addTotals(Contact c, npe01__OppPayment__c payment) {
		if (PledgeRollupUtility.isInCurrentCY(payment.npe01__Opportunity__r.CloseDate)) {
			c.Pledge_Payment_Amt_Recvd_Current_CY__c += payment.npe01__Payment_Amount__c == null ? 0 : payment.npe01__Payment_Amount__c;
		}  
		
		if (PledgeRollupUtility.isInCurrentFY(payment.npe01__Opportunity__r.CloseDate)) {
			c.Pledge_Payment_Amt_Recvd_Current_FY__c += payment.npe01__Payment_Amount__c == null ? 0 : payment.npe01__Payment_Amount__c;
		} 
		
		if (PledgeRollupUtility.isInPreviousCY(payment.npe01__Opportunity__r.CloseDate)) {
			c.Pledge_Payment_Amt_Recvd_Previous_CY__c += payment.npe01__Payment_Amount__c == null ? 0 : payment.npe01__Payment_Amount__c;
		}
		
		if (PledgeRollupUtility.isInPreviousFY(payment.npe01__Opportunity__r.CloseDate)) {
			c.Pledge_Payment_Amt_Recvd_Previous_FY__c += payment.npe01__Payment_Amount__c == null ? 0 : payment.npe01__Payment_Amount__c;
		}
	}
	
	// add totals for contact
	private static void addTotals(Contact c, List<Opportunity> opportunities) {
		if (opportunities != null) {
			for (Opportunity opp : opportunities) {
				addTotals(c, opp);
			}
		}
	}
	
	//add totals for opp
	private static void addTotals(Contact c, Opportunity opp) {
		if (PledgeRollupUtility.isInCurrentCY(opp.CloseDate)) {
			c.Total_Pledges_Current_CY__c += opp.Amount == null ? 0 : opp.Amount;
		}  
		
		if (PledgeRollupUtility.isInCurrentFY(opp.CloseDate)) {
			c.Total_Pledges_Current_FY__c += opp.Amount == null ? 0 : opp.Amount;
		} 
		
		if (PledgeRollupUtility.isInPreviousCY(opp.CloseDate)) {
			c.Total_Pledges_Previous_CY__c += opp.Amount == null ? 0 : opp.Amount;
		}
		
		if (PledgeRollupUtility.isInPreviousFY(opp.CloseDate)) {
			c.Total_Pledges_Previous_FY__c += opp.Amount == null ? 0 : opp.Amount;
		}
	}
	
	// clear totals
	private static void resetContactTotals(Contact c) {
		c.Pledge_Payment_Amt_Recvd_Current_CY__c = 0;
		c.Pledge_Payment_Amt_Recvd_Current_FY__c = 0;
		c.Pledge_Payment_Amt_Recvd_Previous_CY__c = 0;
		c.Pledge_Payment_Amt_Recvd_Previous_FY__c = 0;
		c.Total_Pledges_Current_CY__c = 0;
		c.Total_Pledges_Current_FY__c = 0;
		c.Total_Pledges_Previous_CY__c = 0;
		c.Total_Pledges_Previous_FY__c = 0;
	}
}