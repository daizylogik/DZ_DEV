public with sharing class GridsterDemoController {
	public Date first = Date.newInstance(2016, 2, 7);
    public Date last = Date.newInstance(2016, 2, 13);

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

}