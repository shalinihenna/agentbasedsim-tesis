/**
* Name: agritesis
* Based on the internal empty template. 
* Author: shalini
* Tags: 
*/

/*TODO:
 * Borrar todos los write extras.
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
	
	map<int, string> months_names <- [
		1::'Enero',
		2::'Febrero',
		3::'Marzo',
		4::'Abril',
		5::'Mayo',
		6::'Junio',
		7::'Julio',
		8::'Agosto',
		9::'Septiembre',
		10::'Octubre',
		11::'Noviembre',
		12::'Diciembre'
	];
	
	//shp files
	map<string, file> shpfiles <- [
		'comunas_shp'::file("../includes/limite-comunal.shp"),
		'terrenos_shp'::file("../includes/terrenos-agricolas.shp"),
		'ferias_shp'::file("../includes/ferias-libres.shp")
	];
	geometry shape <- envelope(shpfiles['comunas_shp']);
	
	list<list> products <- [];
	date starting_date <- date([2020,3]);
	date current_date <- date([2020,3]);
	float step update: 1 #month;
	string current_month update: months_names[current_date.month];
	
	//Cantidad de agentes
	map<string, int> people <- [
		'number_of_farmers'::20,
		'number_of_feriantes'::20,
		'number_of_consumers'::20
	];
	
	//Colores de los agentes
	map<string, string> colors <- [
		'farmer_color'::'yellow',
		'feriante_color'::'green',
		'consumer_color'::'blue'
	];
	
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
	map<string, unknown> affect_weight <- user_input([
		enter("Peso de afectación Ola de calor",0), 
		enter("Peso de afectación Helada",0), 
		enter("Peso de afectación Inundación",0), 
		enter("Peso de afectación Plaga",0)
	]); 
	/*write "probando input de user";
	write affect_weight["Peso de afectación Ola de calor"]  */
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
		
		write "Cargando capas de mapas";
		//TODO: Borrar cantidad de terrenos
		int number_terrenos <- 1;
		create comunas from: shpfiles['comunas_shp'];
		create terrenos from: shpfiles['terrenos_shp'] number: number_terrenos; 
		create ferias from: shpfiles['ferias_shp']; /*with: [type::float(get(veg))]{
			if (type > 0){
				color <- #brown;
			}
		}*/
		
		write "Fin";
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
		write "month " + current_month;
		map<string, list<int>> finalRisks;
		loop i over: products {
			string months_siembra <- i[2];
			if(i[2] != '' and (contains(months_siembra, current_month) or contains(months_siembra, 'Todos'))){
				write "product -- " + i[0];
				list<int> risk <- calculateRisk();
				add risk at: i[0] to: finalRisks;
			}
		}
		write "risks list " + finalRisks;
	}
	
	list<int> calculateRisk{
		/*
		 * for cada amenaza:
		 * 		a = buscar la probabilidad de ocurrencia de ese mes (step)
		 * 		clasificacion_a = ver si la clasificación de a en 
		 * 			
		 */	
		 
		 
		list<int> hola <- [1,2];
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

/*Todas las consultas a la base de datos PostgreSQL */
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
	    parameter "Shapefiles:" var: shpfiles category: "GIS";
	    /*parameter "Shapefile for the ferias:" var: shpfiles['ferias_shp'] category: "GIS";
	    parameter "Shapefile for the comunas:" var: shpfiles['comunas_shp'] category: "GIS";
*/	    
	   output{
	   		display map type: java2D{
	   			species comunas aspect:base;
		        species terrenos aspect:base;     
		        species ferias aspect:base; 
		    }
	   	} /*https://gama-platform.github.io/wiki/LuneraysFlu_step3 VER ESTE EJEMPLOOOOO */
	    
	
}  
