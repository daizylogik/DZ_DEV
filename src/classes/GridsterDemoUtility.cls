public with sharing class GridsterDemoUtility {
	
	// teams and projects
	public class TeamProject {
		public Id teamId { get; set; }
		public String teamName { get; set; }
		public Map<integer, List<Project__c>> projects{ get; set; }

		// constructor
		public TeamProject() {
			projects = new Map<integer, List<Project__c>>();
		}
	}

	// holds a date for the calendar
	public class DateElement {
		public Date calendarDate { get; set; }
		
		public string dayOfWeek { 
			get { 
				List<String> listDay = new List<String>{'SAT' , 'SUN' , 'MON' , 'TUE' , 'WED' , 'THU' , 'FRI'};
				Date startDate = date.newInstance(0001, 1, 1);
				Integer remainder = Math.mod(startDate.daysBetween(calendarDate) , 7);
				return listDay.get(remainder);  
			}
		}
		
		public string label {
			get { return dayOfWeek + ' '+ calendarDate.month() + '/' + calendarDate.day(); }
		}
	}

	// matrix item class
    public class MatrixItem {
    	
        // label 
        public string label { get; set; }

       	//id
       	public string id { get; set; }

       	// css class
       	public string cssClass {get; set; }
        
		// data-row
	    public integer dataRow { get; set; }
	         
	    // data-col
	    public integer dataCol { get; set; }
	     
	    // data-sizex
	    public integer dataSizeX { get; set; }
	    
	    // data-sizex
	    public integer dataSizeY { get; set; }
	}

	// populate the dates
    public static List<DateElement> getDates(Date first, Date last) {
    	List<DateElement> dates = new List<DateElement>();

        for (Date current = first; current <= last; current = current.addDays(1)) {
        	DateElement dt = new DateElement();
        	dt.calendarDate = current;
        	dates.add(dt);
        }
        return dates;
    }

	// get the projects per month
    public static List<Project__c> getProjectsForCurrentMonth(Date first, Date last) {
    	return [select id, Project_Name__c
	    		from Project__c
	    		where Start_Date__c <= :last and  End_Date__c >= :first
	    		order by Team__r.Team_Name__c, Start_Date__c];
    } 

	// map project wrappers
    public static List<TeamProject> mapProjectWrappers(Date first, Date last) {
        List<TeamProject> teamProjects = new List<TeamProject>();
        List<Project__c> currentProjects = getProjectsForCurrentMonth(first, last);
    	
    	for (Team__c team : [SELECT Id, Team_Name__c, 
    							(select Id, Project_Name__c, Start_Date__c, End_Date__c
	    						from Team__c.Projects__r
    							Where Id in :currentProjects order by Start_Date__c) 
    						FROM Team__c ORDER BY Team_Name__c]) {
    		
			TeamProject teamProject = new TeamProject();
			teamProject.teamId = team.Id;
			teamProject.teamName = team.Team_Name__c;
			
			for ( Project__c project : team.Projects__r ) {
        		if (teamProject.projects.size() == 0) {
        			List<Project__c> newList = new List<Project__c>();
        			newList.add(project);
        			teamProject.projects.put(0, newList);
        		} else {
        			List<integer> keys = new List<integer>();
	    			keys.addAll(teamProject.projects.keySet());
	    			keys.sort();
	    			
	    			for (integer row : keys) {
						List<Project__c> teamProjectList = teamProject.projects.get(row);
						if (teamProjectList.size() == 0) {
							teamProjectList.add(project);
		        			break;
						} else {
							Project__c lastProject = teamProjectList[teamProjectList.size() - 1];
							if (isProjectOverlap(lastProject, project)) { 
								if (row == keys.size() - 1) {
									integer newRow = row + 1;
			            			List<Project__c> newList = new List<Project__c>();
			            			newList.add(project);
			            			teamProject.projects.put(newRow, newList);	
			            			break;
								} else {
		            				// go to the next row;
		            			}       		
			        		} else {
			        			teamProjectList.add(project);
			        			break;
			        		}
						}
    				}
    			}
     
    		}
    		teamProjects.add(teamProject);
		}   
        return teamProjects;
	}

	// check for projetc overlap
    public static boolean isProjectOverlap(Project__c project1, Project__c project2) {
    	return project1.Start_Date__c <= project2.End_Date__c && project2.Start_Date__c <= project1.End_Date__c;
    }

    // display the projects and crews
    public static void populateTeams(Date first, Date last, List<TeamProject> teamProjects, List<MatrixItem> matrix) {
		integer row = 2;
    	integer col = 2;
    	
    	for (TeamProject teamProject : teamProjects) {
    		Map<integer, List<Project__c>> currentTeamProjects = teamProject.projects;
    		
    		// show the crew
    		integer height = math.max(currentTeamProjects.size(), 1);
    		matrix.add(createMatrixItem(teamProject.teamName, teamProject.teamId, 'header', row, 1, 1, height));
    		
    		// no projects
    		if (currentTeamProjects.size() == 0) {
    			integer space = first.daysBetween(last) + 1;
				matrix.add(createMatrixItem('', '', 'free', row , col, space, 1));
    		}
            
    		List<integer> pRows = new List<integer>();
    		pRows.addAll(currentTeamProjects.keySet());
    		pRows.sort();
    		
    		// add the projects
    		for (integer rowIndex : pRows) {
				List<Project__c> teamProjectList = currentTeamProjects.get(rowIndex);
				
				if (teamProjectList.size() == 0) {
					integer space = first.daysBetween(last) + 1;
					matrix.add(createMatrixItem('', '', 'free', row , col, space, 1));

				} else {
				
					integer projectIndex = 0;
					integer colIndex = 0;
					Date startDate = first;
	    			for(Project__c project : teamProjectList) {
	    				Date projectStartDate = project.Start_Date__c;
	    				if (projectStartDate < first)
	    					projectStartDate = first;
	    				
	    				Date projectEndDate = project.End_Date__c;
	    				if (last < projectEndDate)
	    					projectEndDate = last;
	    				
	    				// space before
	    				integer spaceBefore = startDate.daysBetween(projectStartDate);
		    			if (0 < spaceBefore) {
		    				matrix.add(createMatrixItem('', '', 'free', row + rowIndex, col + colIndex, spaceBefore, 1));
		    				colIndex = colIndex + spaceBefore;
		    			}
					
	    				// project
	    				integer projectLength = projectStartDate.daysBetween(projectEndDate) + 1;
	    				MatrixItem matrixItem = createMatrixItem(project.Project_Name__c, project.id, 'field', row + rowIndex, col + colIndex, projectLength, 1);
                        matrix.add(matrixItem);
	    				colIndex = colIndex + projectLength;
	    				
	    				// space after
	    				if (projectIndex == teamProjectList.size() - 1) {
	    					integer spaceAfter = projectEndDate.daysBetween(last);
			    			if (0 < spaceAfter) {
			    				matrix.add(createMatrixItem('', '', 'free', row + rowIndex, col + colIndex, spaceAfter, 1));
			    			}
	    				}
	    				
	    				startDate = projectEndDate.addDays(1);
	    				projectIndex++;
	    			}
				}
    		}
    				
    		// go to the next row
    		row = row + height;
    	}
	}
    
    // add the dates
    public static void populateDates(Date first, Date last, List<matrixItem> matrix) {
    	List<DateElement> dates = getDates(first, last);
    	
    	// first cell
        matrix.add(createMatrixItem('', '', 'date', 1, 1, 1, 1));
        
        for( integer i = 0; i < dates.size(); i++ ) {
        	matrix.add(createMatrixItem(dates[i].label, dates[i].calendarDate.format(), 'date', 1, i + 2, 1, 1));
        }
    }
    
    // add a project to the list
    public static MatrixItem createMatrixItem(string label, string id, string cssClass, 
    								integer dataRow, integer dataCol, integer dataSizeX, integer dataSizeY)
    {
        MatrixItem item = new MatrixItem();
        item.label = label;
        item.id = id;
        item.cssClass = cssClass;
       	item.dataRow = dataRow;
        item.dataCol = dataCol;
        item.dataSizeX = dataSizeX;
        item.dataSizeY = dataSizeY;
        
        return item;
    }


}