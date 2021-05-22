/**
* Name: predatorprey
* Based on the internal empty template. 
* Author: shalini
* Tags: 
*/


model predatorprey

/* Insert your model definition here */

species hortalizas{
	string name;
	rgb color <- #black;
	
	aspect base{
		draw shape color:color;
	}
}

global{
	file hortalizas_shapefile <- file("../includes/cc_horta.shp");
	geometry shape <- envelope(hortalizas_shapefile); 
	
	init{
		create hortalizas from: hortalizas_shapefile with[name::read("")]
	}
}

experiment prueba type:gui{
	parameter "Shapefile for the hortalizas:" var: hortalizas_shapefile  category: "GIS;"
}