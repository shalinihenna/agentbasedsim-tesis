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
		
		create hortalizas from: hortalizas_shapefile with: [type::read("GEOM")];
		
	}

}

/*They are not agents, its just for display */
species hortalizas {
	string type;
	aspect base {
		draw shape color: #black;
	}
}


species agentDB skills:[SQLSKILL]{
	list<list> vegetables <- [];
	
	init{
		map<string, unknown> selected_veg <- user_input([enter("hortaliza",'')]); 
		write "probando input de user";
		write selected_veg["hortaliza"];
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

experiment default_expr type: gui {
	    parameter "Shapefile for the prueba:" var: hortalizas_shapefile category: "GIS";
	    
	   output{
	   		display map type: opengl{
		        species hortalizas aspect:base;      
		    }
	   	} /*https://gama-platform.github.io/wiki/LuneraysFlu_step3 VER ESTE EJEMPLOOOOO */
	    
	
}  
