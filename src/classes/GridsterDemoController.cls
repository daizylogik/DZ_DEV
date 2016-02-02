public with sharing class GridsterDemoController {
	public Date first = Date.newInstance(2016, 2, 7);
    public Date last = Date.newInstance(2016, 2, 13);

    public String nameParam {get; set;}
    public String teamParam {get; set;}
    public String dateParam {get; set;}

	public GridsterDemoController() {
		
	}

	// populates the matrix
	public List<GridsterDemoUtility.MatrixItem> getMatrix() {
        List<GridsterDemoUtility.MatrixItem> matrix = new List<GridsterDemoUtility.MatrixItem>();
     	List<GridsterDemoUtility.TeamProject> teamProjects = GridsterDemoUtility.mapProjectWrappers(first, last);
        GridsterDemoUtility.populateDates(first, last, matrix);
		GridsterDemoUtility.populateTeams(first, last, teamProjects, matrix);
        return matrix;    
	}

	// update the dragged project
	public PageReference saveProject() {
        if (!String.isBlank(nameParam) && !String.isBlank(teamParam) && !String.isBlank(dateParam)) {
        	Project__c project = [select Id, Project_Name__c, Team__c, Start_Date__c, End_Date__c 
        					from Project__c where Project_Name__c = :nameParam];

        	Team__c team = [select Id
        					from Team__c where Team_Name__c = :teamParam];

        	 if (project != null && team != null) {
        	 	project.Team__c = team.Id;
        	 	project.Start_Date__c = getDate(dateParam);
        	 	project.End_Date__c = getDate(dateParam);
        	 	update project;
        	 }
        }
        return null;
    }

    // parse the date
    private static Date getDate(string dt) {
    	String newDate = dt.replace('MON', '').replace('TUE', '').replace('WED', '').replace('THU', '').replace('FRI', '').replace('SAT', '').replace('SUN', '');
    	List<string> parts = newDate.split('/');
    	return Date.newInstance(Date.today().year(), Integer.valueOf(parts[0].trim()), Integer.valueOf(parts[1].trim()));
    }


}