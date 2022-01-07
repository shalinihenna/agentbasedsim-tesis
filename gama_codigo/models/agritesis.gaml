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
		'ferias_shp'::file("../includes/ferias-libres.shp"),
		'floods_shp'::file("../includes/Zonas susceptibles a inundación.shp")
	];
	geometry shape <- envelope(shpfiles['comunas_shp']);
		
	list<list> products <- [];
	date starting_date <- date([2020,3]);
	date current_date <- date([2020,3]);
	float step update: 1 #month;
	string current_month update: months_names[current_date.month]; 
	list<int> generalRisks <- [];
	
	//Cantidad de agentes
	map<string, int> people <- [
		'number_of_farmers'::4695, //la misma cantidad de terrenos
		'number_of_feriantes'::20,
		'number_of_consumers'::20
	];
	
	//Colores de los agentes
	map<string, rgb> colors <- [
		'farmer_color'::#yellow,
		'feriante_color'::#green,
		'consumer_color'::#blue
	];
	
	//Variables estáticas para cálculos de riesgo (Amenazas x vulnerabilidad, GRD)
	list<string> threats <- ["Helada", "Ola de calor", "Sequia","Plaga"];
	map<string, list<int>> result_risk_scale <- [
		"Baja"::[1,2],
		"Media"::[3,4,5],
		"Alta"::[6,7,8],
		"Muy Alta"::[9]	
	];
	
	map<int,string> risk_scale <- [
		0::"Nulo",
		1::"Baja",
		2::"Media",
		3::"Alta"	
	];
	
	map<int, string> land_state <- [ 
		0::"Sin Agricultor",
		1::"Vacío",
		2::"Sembrando",
		3::"Proceso de cultivo",
		4::"Cosecha Lista"
	];
	
	//Input de user
	 map<string, unknown> affect_weight <- user_input([
	 	enter("Peso de afectación Helada",0.0),
		enter("Peso de afectación Ola de calor",0.0), 
		enter("Peso de afectación Sequía",0.0), 
		enter("Peso de afectación Plaga",0.0)
	]); 
	
	/*Creación e inicialización de los agentes en la simulación */
	init{
		
		write "Conectando DB";
		create agentDB;
		
		write "Cargando capas de mapas";
		create comunas from: shpfiles['comunas_shp'];
		create terrenos from: shpfiles['terrenos_shp'] with:[area::float(get("area_ha"))];
		create ferias from: shpfiles['ferias_shp']; 
		/*create floods from: shpfiles['floods_shp'] with: [risklevel::string((get("INUNDA2")))]{
				color <- risklevel = "ALTA (desborde)" ? #blue : #darkblue;
				border <- risklevel = "ALTA (desborde)" ? #blue : #darkblue;
		}*/
		
		write "Inicializando agentes";
		list<terrenos> te;
	 	create farmers number:people['number_of_farmers'];
		/*create feriantes number:number_of_feriante;
		create consumer number:number_of_consumer;*/
		
		
		write "Fin";
		
	}
	
	reflex climateRisks{
		write "Step " + current_month + ' ' + current_date.year;
		unknown frostRisk;
		int droughtRisk;
		int heatwaveRisk;	
		ask(agentDB){
		 	/*HELADAS */
		 	list<list> frost <- list<list> (select(params:POSTGRES, 
		 											select: "SELECT * FROM frost where mes = ? ;",
		 											values: [current_month])); 
		 	list<unknown> frost_values <- frost[2][0];
		 	float prob <- frost_values[1] as float;
		 	int days;
		 	string degree;
		 	if(flip(prob)){
		 		days <- ceil(frost_values[3] as float) as int;
		 		map<int, int> sumRisks <- [3::0,2::0,1::0];
		 		loop times: days {
		 			degree <- rnd_choice(["rango 1"::frost_values[4], "rango 2"::frost_values[5], "rango 3"::frost_values[6], "rango 4"::frost_values[7], "rango 5"::frost_values[8], "rango 6"::frost_values[9]]);
		 			switch (degree) {
		 				match_one["rango 1", "rango 2"] {sumRisks[1] <- sumRisks[1]+1;} //Riesgo bajo
		 				match_one["rango 3", "rango 4"] {sumRisks[2] <- sumRisks[2]+1;} //Riesgo medio
		 				match_one["rango 5", "rango 6"] {sumRisks[3] <- sumRisks[3]+1;} //Riesgo alto
		 			}
		 		}
		 		if(sumRisks[2] + sumRisks[3] >= sumRisks[1]){
		 			frostRisk <- sumRisks last_index_of max(sumRisks[2], sumRisks[3]); 
		 		}else{
		 			frostRisk <- sumRisks last_index_of max(sumRisks);
		 		}
		 	}else{
		 		frostRisk <- 0; 
		 	}
		 	write 'Riesgo de heladas: ' + frostRisk;
		 	
		 	/*SEQUIA METEOROLOGICA -- PRECIPITACIONES (SPI) */
		 	list<list<list>> spi <- list<list<list>> (select(params:POSTGRES,
		 										select: "SELECT * FROM spi_10 where month = ? and year = ?;",
		 										values: [current_month, string(current_date.year)])); 
		 	//Rango de spi asociado al riesgo (int)
		 	switch(spi[2][0][2]){
		 		match_between[0, #infinity] {droughtRisk <- 0;}
		 		match_between[-0.5,0]{droughtRisk <- 1;}
		 		match_between[-1,-0.5]{droughtRisk <- 1;}
		 		match_between[-1.5,-1]{droughtRisk <- 2;}
		 		match_between[-2,-1.5]{droughtRisk <- 2;}
		 		match_between[-#infinity,-2]{droughtRisk <- 3;}
		 	}
		 	
		 	write "Riesgo de sequía: " + droughtRisk;
		 	
		 	/*OLAS DE CALOR */
		 	list<list<list>> heatwaves <- list<list<list>>(select(params:POSTGRES,
		 											select: "SELECT * FROM heatwave where month = ? and year = ?;",
		 											values: [current_month, string(current_date.year)]));
		 	switch(heatwaves[2][0][2]){
		 		match 0{heatwaveRisk <- 0;}
		 		match_between[1,3]{heatwaveRisk <- 1;}
		 		match_between[4,7]{heatwaveRisk <- 2;}
		 		match_between[8,#infinity]{heatwaveRisk <- 3;}
		 	}
		 	write "Riesgo de olas de calor: " + heatwaveRisk;	
		 }
		generalRisks <- [int(frostRisk), heatwaveRisk, droughtRisk, 0];
		//Borrar
		//write 'risks: ' + generalRisks; 
	}
	
	list<string> finalRisksProduct;
	list<float> finalRisksValue;
	reflex generalRisk{
		finalRisksProduct <- [];
		finalRisksValue <- []; 
		loop i over: products {
			float affectionLevel <- 0.0; 
			float aux <- 0.0;
			list<int> indexes;
			string months_siembra <- i[2];
			if(i[2] != '' and (contains(months_siembra, current_month) or contains(months_siembra, 'Todos'))){
				loop j from:0 to:3 step:1 {
					switch(threats[j]){
						match 'Helada' { indexes <- [7,8,9]; }
						match 'Ola de calor' { indexes <- [10,11,12]; }
						match 'Sequia' { indexes <- [13, 14, 15]; }
						match 'Plaga' { indexes <- [16,17,18]; }
					}
					
					switch(generalRisks[j]){
						match 1 { aux <- float(i[indexes[0]]) * float(affect_weight["Peso de afectación " + threats[j]]); }
						match 2 { aux <- float(i[indexes[1]]) * float(affect_weight["Peso de afectación " + threats[j]]); }
						match 3 { aux <- float(i[indexes[2]]) * float(affect_weight["Peso de afectación " + threats[j]]); }
					}
					affectionLevel <- affectionLevel +  aux * generalRisks[j];
				}
				add affectionLevel to: finalRisksValue;		
				add i[0] to: finalRisksProduct;
			}
		}
		write "risks list valueeee " + finalRisksValue;
		write "risks list prodssss " + finalRisksProduct;
	}
	
	reflex getPrices{
			
	}
	
	//predicates for BDI agents
	//FARMER
	predicate esperar <- new_predicate("esperar");
	predicate cosecha_lista <- new_predicate("cosecha lista", true);
	predicate cosecha_nolista <- new_predicate("cosecha lista", false);
	predicate empty_land <- new_predicate("empty land");
	predicate sembrar <- new_predicate("sembrar");
	predicate preparar_tierra <- new_predicate("preparar tierra"); 
	predicate cosechar <- new_predicate("cosechar"); 
	predicate vender <- new_predicate("vender a feriante"); 

}

//Agente agricultores
species farmers skills:[moving] control:simple_bdi{
	//int riskLevel <- rnd_choice([1::0.6, 2::0.3, 3::0.1]);
	bool riskLevel <- flip(0.06); 
	rgb my_color <- colors['farmer_color'];
	terrenos terreno;
	int non_sold_vegetables;
	int sold_vegetables;
	
	
	init{
		//assign terreno 
		list<terrenos> te <- terrenos where (each.estado = 0);
		terreno <- one_of(te);
		terreno.estado <- 1;
		self.location <- centroid(terreno);
		
		//add first desire because terreno vacío
		do add_desire(esperar);
	}
	
	//cuando el terreno está vacío
	perceive target:terreno when: terreno.estado = 1 {
		//focus id:"algo" var:
		ask myself{
			do remove_intention(esperar, true);
			do add_belief(empty_land);
			do add_belief(cosecha_nolista);
			do remove_belief(cosecha_lista);
		}
	}
	
	rule belief: empty_land new_desire: sembrar;
	
	plan proceso_siembra intention: sembrar{
		
		if(terreno.estado = 1){
			//subdesire 1: Selección de hortaliza según el riesgo de eventos climáticos y el precio/demanda del periodo pasado
			if(!self.riskLevel){
				//write "Riesgo 1";
				//write " ";
				
			}else{
				
			}
			
			terreno.producto_seleccionado <- "Frutilla"; //hacer el random y falta agregar lo del precio/demanda!
			terreno.estado <- 2;
		}else if(terreno.estado = 2){
			//subdesire 2: Preparar tierra
			
			terreno.estado <- 3;
		}else if(terreno.estado = 3){
			//desire: Sembrar propiamente tal
			terreno.estado <- 4;
			
			//actualización de beliefs e intentions
			do remove_belief(empty_land);
			do remove_intention(sembrar);
			//falta
		}
		
	}
	
	//cuando el terreno está listo para cosechar
	perceive target:terreno when: terreno.estado = 4 {
		ask myself{
			do add_belief(cosecha_lista);
			do remove_belief(cosecha_nolista);
		}
	}
	
	
	aspect base {
        draw circle(70) color: my_color border: #black;  //depth: gold_sold;
    }
}

/*They are not agents, its just for display */
species terrenos {
	rgb color <- #white;
	rgb border <- #black;
	int estado <- 0; //0 --> vacío, 1 --> preparando tierra, 2 --> cultivando, 3 --> cosechando.
	float area;
	string producto_seleccionado;
	int plagaRisk;
	list<string> finalProducts;
	list<float> riskValues;
	  
	aspect base {
		draw shape color: color border: border;
	}
	
	//Calcular riesgo en el terreno	
	action getMinRisk{
		float riskValue;
		list<int> indexes;
		list<string> filteredProducts;
		
		//para los farmers con riskLevel 1
		riskValue <- min(riskValues);
		int contador <- 0;   
		loop j over: riskValues {
			if(j = riskValue){
				indexes <- indexes + contador;
			}
			contador <- contador + 1;
		}
		//indexes <- riskValues all_indexes_of riskValue; Este no funciona, así que se tuvo que hacer un loop para obtener los índices.
		filteredProducts <- indexes collect(finalProducts[each]);
		write "risk values:" + riskValues + " --- min risk value: " + riskValue + " --- min risk products: " + filteredProducts;		
	}
	action assignPlagaRisk{
		float aux <- 0.0;
		int index;	
		//asignación de riesgo a plaga en el mismo terreno, desde el "put" se mantiene tal cual	
		plagaRisk <- rnd_choice([0.7, 0.1, 0.1, 0.1]);
		write "plagaRisk: " + plagaRisk;
		finalProducts <- copy(finalRisksProduct);
		riskValues <- copy(finalRisksValue);
		list<list> i;
		loop prod over: finalProducts{
			ask(agentDB){
				i <- list<list> (select(params: POSTGRES,
										select: "SELECT * FROM productos_respaldo WHERE valid = true and nombre = ?;",
										values: [prod]));
				i <- i[2][0];
			}
			switch(plagaRisk){
				match 1 { aux <- float(i[16][0]) * float(affect_weight["Peso de afectación " + threats[3]]); }
				match 2 { aux <- float(i[17][0]) * float(affect_weight["Peso de afectación " + threats[3]]); }
				match 3 { aux <- float(i[18][0]) * float(affect_weight["Peso de afectación " + threats[3]]); }
			}
			index <- finalProducts index_of(prod);
			riskValues[index] <- riskValues[index] +  aux * plagaRisk;
		}
	}
	
	reflex all{
		do assignPlagaRisk;
		do getMinRisk;
	}
	//Cada step de la simulación
	/*reflex prueba_reflex{
		do getMinRisk;
	}*/
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

species floods {
	string risklevel;
	rgb color <- #darkblue;
	rgb border <- #darkblue;
	aspect base {
		draw shape color: color border: border;
	}
	
}

/*Agente conector a la base de datos PostgreSQL */
species agentDB skills:[SQLSKILL]{
	
	init{
		if(testConnection(POSTGRES)){
			products <- list<list> (select(POSTGRES,"SELECT * FROM productos_respaldo WHERE valid = true;"));
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
		        //species floods aspect:base;
		        species farmers aspect:base;
		    }
		    
		    monitor "Step actual " value: current_month + ' ' + current_date.year ;
		    /*monitor "Peso de afectación Helada" value: affect_weight['Peso de afectación Helada'];
		    monitor "Peso de afectación Ola de calor" value:  affect_weight['Peso de afectación Ola de calor'] ;
		    monitor "Peso de afectación Sequía" value: affect_weight['Peso de afectación Sequía'] ;
		    monitor "Peso de afectación Plaga" value: affect_weight['Peso de afectación Plaga'];
		    monitor "Peso de afectación Helada" value: affect_weight['Peso de afectación Helada'];*/
		    monitor "Riesgo Helada" value: risk_scale[generalRisks[0]] ;
		    monitor "Riesgo Ola de calor" value: risk_scale[generalRisks[1]] ;
		    monitor "Riesgo Sequía" value:risk_scale[generalRisks[2]] ;
		    
		    //para chart display: every 12 cycles
	   	} /*https://gama-platform.github.io/wiki/LuneraysFlu_step3 VER ESTE EJEMPLOOOOO (chart_display para gráficos) */
}  
