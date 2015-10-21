// created by Vladimir Martinov @ daizylogik
public class PledgeRollupUtility {
	private static final integer FISCAL_MONTH = 7;
	
	// this CY
	public static boolean isInCurrentCY(date dt) {
		return date.today().year() == dt.year();
	}
	
	// this FY
	public static boolean isInCurrentFY(date dt) {
		if (date.today().month() < FISCAL_MONTH) {
			return date.newInstance(date.today().addYears(-1).year(), FISCAL_MONTH, 1) <= dt && dt < date.newInstance(date.today().year(), FISCAL_MONTH, 1) ? true : false;
		} else {
			return date.newInstance(date.today().year(), FISCAL_MONTH, 1) <= dt && dt < date.newInstance(date.today().addYears(1).year(), FISCAL_MONTH, 1) ? true : false;
		}
	}
	
	// last CY
	public static boolean isInPreviousCY(date dt) {
		return date.today().addYears(-1).year() == dt.year();
	}
	
	// last FY
	public static boolean isInPreviousFY(date dt) {
		if (date.today().month() < FISCAL_MONTH) {
			return date.newInstance(date.today().addYears(-2).year(), FISCAL_MONTH, 1) <= dt && dt < date.newInstance(date.today().addYears(-1).year(), FISCAL_MONTH, 1) ? true : false;
		} else {
			return date.newInstance(date.today().addYears(-1).year(), FISCAL_MONTH, 1) <= dt && dt < date.newInstance(date.today().year(), FISCAL_MONTH, 1) ? true : false;
		}
	}
}