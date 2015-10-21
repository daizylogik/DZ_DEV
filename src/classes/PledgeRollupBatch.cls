// created by Vladimir Martinov @ daizylogik
// schedulable class to call PledgeAccountRollupBatch and PledgeContactRollupJob
global class PledgeRollupBatch implements Schedulable {

	public void execute(SchedulableContext sc) {
        PledgeAccountRollupBatch b1 = new PledgeAccountRollupBatch();
		Database.executeBatch(b1);
		
		PledgeContactRollupBatch b2 = new PledgeContactRollupBatch();
		Database.executeBatch(b2);
    }
    
}