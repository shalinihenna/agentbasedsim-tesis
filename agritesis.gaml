/**
* Name: agritesis
* Based on the internal empty template. 
* Author: shalini
* Tags: 
*/


model agritesis

/* Insert your model definition here */

/*Características del mundo */
global{
	/*Connection to postgres database */
	map<string, string>  POSTGRES <- [
	     'host'::'localhost',
	     'dbtype'::'postgres',
	     'database'::'agentbasedtesis',
	     'port'::'5432',
	     'user'::'postgres',
	     'passwd'::'password'
	];	
	
	//shp files
	file hortalizas_shapefile <- file("../includes/cc_horta.shp");
	geometry shape <- envelope(hortalizas_shapefile);
	//TODO:  archivo tuberculos y archivo frutas
	
	//Cantidad de agentes
	int number_of_farmers <- 20;
	int number_of_feriante <- 20;
	int number_of_consumer <- 20;
	
	//Colores de los agentes
	string farmer_color <- 'yellow';
	string feriante_color <- 'green';
	string consumer_color <- 'blue';
	
	float drought_prob <- 0.1;
	float frost_prob <- 0.1;
	//float  
	
	/*Creación e inicialización de los agentes en la simulación */
	init{
		write "Inicializando agentes";
	 	/*create farmers number:number_of_farmers;
		create feriantes number:number_of_feriante;
		create consumer number:number_of_consumer;*/
		
		write "Conectando DB";
		create agentDB;
		
		map<string, unknown> selected_veg <- user_input([enter("hortaliza",'')]); 
		string veg <- selected_veg["hortaliza"];
		write "probando input de user";
		write selected_veg["hortaliza"];
		
		create hortalizas from: hortalizas_shapefile with: [type::float(get(veg))]{
			//write "a" + type;
			if (type > 0){
				color <- #brown;
				border <- #black ;
			}
		}
		
	}

}

/*They are not agents, its just for display */
species hortalizas {
	string name;
	float type;
	rgb color <- #white;
	rgb border <- #white;
	
	aspect base {
		draw shape color: color border: #black;
	}
}


species agentDB skills:[SQLSKILL]{
	list<list> vegetables <- [];
	
	init{
		if(testConnection(POSTGRES)){
			vegetables <- list<list> (select(POSTGRES, "SELECT * FROM vegetables ;"));
			vegetables <- vegetables[2];
			write "aver en que quedó" + vegetables; 
		}else{
			write "Problemas de conexión con la BD.";
		}
	}
}

/*TODO: Revisar como hacer panel de usuario (sin seguir arquitetcura propiamente tal */
/*user_panel default initial:true{
	
}*/

experiment agriculture_world type: gui {
	    parameter "Shapefile for the vegetables:" var: hortalizas_shapefile category: "GIS";
	    
	   output{
	   		display map type: opengl{
		        species hortalizas aspect:base;      
		    }
	   	} /*https://gama-platform.github.io/wiki/LuneraysFlu_step3 VER ESTE EJEMPLOOOOO */
	    
	
}  
