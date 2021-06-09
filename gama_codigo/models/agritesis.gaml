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
	file comunas_shp <- file("../includes/limite-comunal.shp");
	file terrenos_shp <- file("../includes/terrenos-agricolas.shp");
	file ferias_shp <- file("../includes/ferias-libres.shp");
	
	geometry shape <- envelope(comunas_shp);
	
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
		
		/*map<string, unknown> selected_veg <- user_input([enter("hortaliza",'')]); 
		string veg <- selected_veg["hortaliza"];
		write "probando input de user";
		write selected_veg["hortaliza"];
		*/
		
		create comunas from: comunas_shp;
		create terrenos from: terrenos_shp; /*with: [type::float(get(veg))]{
			if (type > 0){
				color <- #brown;
			}
		}*/
		create ferias from: ferias_shp;
		
	}

}

/*They are not agents, its just for display */
species terrenos {
	rgb color <- #white;
	rgb border <- #black;
	
	aspect base {
		draw shape color: color border: border;
	}
}

species ferias {
	rgb color <- #red;
	
	aspect base{
		draw shape color: color;
	}
}

species comunas {
	rgb border <- #grey;
	rgb color <- #transparent;
	aspect base {
		draw shape color: color border: border;
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
	    parameter "Shapefile for the terrenos:" var: terrenos_shp category: "GIS";
	    parameter "Shapefile for the ferias:" var: ferias_shp category: "GIS";
	    parameter "Shapefile for the comunas:" var: comunas_shp category: "GIS";
	    
	   output{
	   		display map type: java2D{
	   			species comunas aspect:base;
		        species terrenos aspect:base;     
		        species ferias aspect:base; 
		    }
	   	} /*https://gama-platform.github.io/wiki/LuneraysFlu_step3 VER ESTE EJEMPLOOOOO */
	    
	
}  
