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
	     'passwd'::'secret'
	];	
	
	//shp files //TODO convertir en Map<>
	file comunas_shp <- file("../includes/limite-comunal.shp");
	file terrenos_shp <- file("../includes/terrenos-agricolas.shp");
	file ferias_shp <- file("../includes/ferias-libres.shp");
	
	geometry shape <- envelope(comunas_shp);
	
	list<list> products <- [];
	
	//Cantidad de agentes //TODO convertir en Map<>
	int number_of_farmers <- 20;
	int number_of_feriante <- 20;
	int number_of_consumer <- 20;
	
	//Colores de los agentes //TODO convertir en Map<>
	string farmer_color <- 'yellow';
	string feriante_color <- 'green';
	string consumer_color <- 'blue';
	
	//Variables estáticas para cálculos de riesgo (Amenazas x vulnerabilidad, GRD)
	list<string> threats <- ["Ola de calor", "Helada", "Inundacion","Plaga"];
	map<string, list<int>> result_risk_scale <- [
		"Baja"::[1,2],
		"Media"::[3,4,5],
		"Alta"::[6,7,8],
		"Muy Alta"::[9]	
	];
	map<string, int> risk_scale <- [
		"Baja"::1,
		"Media"::2,
		"Alta"::3	
	];
	map<string, list<int>> affect_score <- [
		"Ola de calor"::[1,4,7],
		"Helada"::[3,5,8],
		"Inundacion"::[2,5,7],
		"Plaga"::[6,8,10]	
	];
	map<string, unknown> affect_weight <- user_input([enter("Peso de afectación Ola de calor",''), enter("Peso de afectación Helada",''), enter("Peso de afectación Inundación",''), enter("Peso de afectación Plaga",'')]); 
	
	/*float drought_prob <- 0.1;
	float frost_prob <- 0.1;*/  
	
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
		create terrenos from: terrenos_shp; 
		create ferias from: ferias_shp; /*with: [type::float(get(veg))]{
			if (type > 0){
				color <- #brown;
			}
		}*/
		
	}

}

/*They are not agents, its just for display */
species terrenos {
	rgb color <- #white;
	rgb border <- #black;
	
	aspect base {
		draw shape color: color border: border;
	}
	
	
	//Calcular riesgo en el terreno
	action getMinRisk{
		map<string, list<int>> finalRisks <- [];
		write "productos desde la bd" + products; 
		/*
		 * for cada producto
		 *		push array <- do calculateRisk()
		  */
	}
	
	list<int> calculateRisk{
		/*
		 * for cada amenaza:
		 * 		a = buscar la probabilidad de ocurrencia de ese mes (step)
		 * 		clasificacion_a = ver si la clasificación de a en 
		 * 			
		 */	
		list<int> hola;
		return hola;
	}
	
	reflex prueba_reflex{
		do getMinRisk;
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
	
	init{
		if(testConnection(POSTGRES)){
			products <- list<list> (select(POSTGRES, "SELECT * FROM productos ;"));
			products <- products[2];
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
