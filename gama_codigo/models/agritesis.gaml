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
		'ferias_shp'::file("../includes/Ferias Libres (RM) 2.shp")
	];
	geometry shape <- envelope(shpfiles['comunas_shp']);
		
	list<list> products <- [];
	map<string, int> days_cosecha <- [];
	map<string, string> units <- [];
	map<string, int> production <- [];
	date starting_date <- date([2020,3]);
	date current_date <- date([2020,3]);
	float step update: 1 #month;
	string current_month update: months_names[current_date.month]; 
	list<int> generalRisks <- [];
	map<string, int> mercadoMayoristaVol <- [];
	list<string> listadoProducts <- [];
	map<string, string> months_venta <- []; 
	map<string, list<int>> priceFerianteConsumer <-[];
	map<string, int> priceFerianteConsumerPromedio <- [];
	map<string, int> priceMayoristaFeriante <- [];
	map<string, int> volumeMayorista_lastyear <- [];
	map<string, int> volumeOneFeriante <- [];
	map<string, int> volumeOneConsumer <- [];
	list<string> available_products <- [];
	list<string> used_products <- [];
	map<int, int> months_sequia <- [];
	map<int, int> months_helada <- [];
	map<int, int> months_oladecalor <- [];
	map<string, int> actualPrices <- [];
	int totalFerianteValues;
	
	
	//Variables totales para los gráficos
	map<string, int> mercadoMayoristaVolumenTotal <- []; 
	map<string, int> feriantesVolumenTotal <- [];
	map<string, int> consumersVolumenTotal <- [];
	
	//Cantidad de agentes
	map<string, int> people <- [
		'number_of_farmers'::4695, //la misma cantidad de terrenos
		'number_of_feriantes':: 14735, //la misma cantidad que los puestos de verduras en cada feria (sumatoria)
		'number_of_consumers':: 20000 //cantidad de hogares en RM aprox reducido porque no aguanta 2millones de agentes 
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
		2::"Sembrado. En proceso de cultivo",
		3::"Cosecha Lista"
	];
	
	//Input de user
	 map<string, unknown> affect_weight <- user_input([
	 	enter("Peso de afectación Helada",0.0),
		enter("Peso de afectación Ola de calor",0.0), 
		enter("Peso de afectación Sequia",0.0), 
		enter("Peso de afectación Plaga",0.0)
	]); 
	
	/*Creación e inicialización de los agentes en la simulación */
	init{
		
		write "Conectando DB";
		create agentDB;
		
		write "Cargando capas de mapas...";
		create comunas from: shpfiles['comunas_shp'];
		create terrenos from: shpfiles['terrenos_shp'] with:[area::float(get("area_ha"))];  //number:2;
		create ferias from: shpfiles['ferias_shp'] with:[puesto_verduras::int(get("VERDURAS")), dias_puesto::string(get("DIAPOSTU")), puestos_vacios::int(get("VERDURAS"))];
		
		write "Inicializando agentes...";
		list<terrenos> te;
	 	create farmers number:people['number_of_farmers'];
	 	write "Agricultores listo";
		create feriantes number:people['number_of_feriantes'];
		write "Feriantes listo";
		create consumers number:people['number_of_consumers'];
		write "Consumidores listo";
		
		write "Inicializando mercado mayorista...";
		loop d over:products{
			add 0 at:d[0] to: mercadoMayoristaVol;
			add 0 at:d[0] to: mercadoMayoristaVolumenTotal;
			add 0 at:d[0] to: feriantesVolumenTotal;
			add 0 at:d[0] to: consumersVolumenTotal;
			add 0 at:d[0] to: actualPrices;
		}

		write "Fin";
		
	}
	
	reflex getAvailableProducts{
		ask(agentDB){
			list<list> prods <- list<list> (select(params:POSTGRES,
													select: "SELECT productos FROM meses_de_venta where mes = ? ;",
													values: [current_month]));
			list<string> prods2 <- list<string>(prods[2][0]);
			available_products <- string(prods2[0]) split_with ',';  
		}
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
		 }
		generalRisks <- [int(frostRisk), heatwaveRisk, droughtRisk, 0];
		add int(frostRisk) at: current_date.month to: months_helada;
		add droughtRisk at: current_date.month to: months_sequia;
		add heatwaveRisk at: current_date.month to:months_oladecalor;
	}
	
	list<string> finalRisksProduct0; //Riesgo de Plaga 0
	list<float> finalRisksValue0;
	list<string> finalRisksProduct1; //Riesgo de Plaga 1
	list<float> finalRisksValue1;
	list<string> finalRisksProduct2; //Riesgo de Plaga 2
	list<float> finalRisksValue2;
	list<string> finalRisksProduct3; //Riesgo de Plaga 3
	list<float> finalRisksValue3;
	reflex generalRisk{
		list<string> finalRisksProduct;
		list<float> finalRisksValue;
		loop a from: 0 to: 3 step:1 {
			finalRisksProduct <- [];
			finalRisksValue <- [];
			put a at:3 in:generalRisks;
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
			
			switch(a){
				match 0 {finalRisksValue0 <- copy(finalRisksValue); finalRisksProduct0 <- copy(finalRisksProduct);}
				match 1 {finalRisksValue1 <- copy(finalRisksValue); finalRisksProduct1 <- copy(finalRisksProduct);}
				match 2 {finalRisksValue2 <- copy(finalRisksValue); finalRisksProduct2 <- copy(finalRisksProduct);}
				match 3 {finalRisksValue3 <- copy(finalRisksValue); finalRisksProduct3 <- copy(finalRisksProduct);}
			}
		}
		
		write "finalRisk -- Plaga 0" + finalRisksValue0 + " --" + finalRisksProduct0;
		write "finalRisk -- Plaga 1" + finalRisksValue1 + " --" + finalRisksProduct1;
		write "finalRisk -- Plaga 2" + finalRisksValue2 + " --" + finalRisksProduct2;
		write "finalRisk -- Plaga 3" + finalRisksValue3 + " --" + finalRisksProduct3;
	}
	
	//Para los farmers con riskLevel false
	list<string> minRiskFilteredProducts0;
	list<string> minRiskFilteredProducts1;
	list<string> minRiskFilteredProducts2;
	list<string> minRiskFilteredProducts3;
	reflex getMinRisk{
		list<float> riskValues;
		float oneRiskValue;
		list<int> indexes;
		loop b from: 0 to: 3 step: 1{
			riskValues <- [];
			indexes <- []; 
			switch(b){
				match 0 {riskValues <- copy(finalRisksValue0);}
				match 1 {riskValues <- copy(finalRisksValue1);}
				match 2 {riskValues <- copy(finalRisksValue2);}
				match 3 {riskValues <- copy(finalRisksValue3);}
			}
			
			oneRiskValue <- min(riskValues);
			int contador <- 0;
			loop j over:riskValues{
				if(j = oneRiskValue){
					indexes <- indexes + contador;
				}
				contador <- contador + 1;
			}
			
			switch(b){
				match 0 { minRiskFilteredProducts0 <- indexes collect(finalRisksProduct0[each]); }
				match 1 { minRiskFilteredProducts1 <- indexes collect(finalRisksProduct1[each]); }
				match 2 { minRiskFilteredProducts2 <- indexes collect(finalRisksProduct2[each]); }
				match 3 { minRiskFilteredProducts3 <- indexes collect(finalRisksProduct3[each]); }
			}
		}
		
		write "minProducts -- Plaga 0: " + minRiskFilteredProducts0;
		write "minProducts -- Plaga 1: " + minRiskFilteredProducts1;
		write "minProducts -- Plaga 2: " + minRiskFilteredProducts2;
		write "minProducts -- Plaga 3: " + minRiskFilteredProducts3;
		write " ";
		
	}
	
	
	//Para obtener los precios y volúmen de este mes del año pasado (del step)
	reflex getInfo{
		priceFerianteConsumer <- [];
		priceFerianteConsumerPromedio <- [];
		priceMayoristaFeriante <- [];
		volumeMayorista_lastyear <- [];
		list<list> dbdata;
		ask agentDB{
			dbdata <- list<unknown> (select(params:POSTGRES, 
													select: "SELECT producto, \"Precio mínimo\", \"Precio máximo\", \"Precio promedio\", \"Precio ponderado mayorista\", \"Volumen mayorista\" 
															FROM detalle_productos_2 
															WHERE mes_escrito = ? and anio = ?
															union
															select dp.producto, dp.\"Precio mínimo\", dp.\"Precio máximo\",dp.\"Precio promedio\",dp.\"Precio ponderado mayorista\", dp.\"Volumen mayorista\" 
															from public.detalle_productos_2 dp
															where (dp.producto, dp.mes) in (
																SELECT producto, max(mes) as mes
																FROM public.detalle_productos_2
																where producto not in (SELECT producto
																						FROM public.detalle_productos_2
																						WHERE mes_escrito = ? and anio = ? )
																group by producto
															)
															order by \"Volumen mayorista\" desc;",
													values: [current_month, current_date.year-1,current_month, current_date.year-1])); 
		 											
		}
		dbdata <- dbdata[2];

		loop a over: dbdata{
			add [int(a[1]), int(a[2])] at: a[0] to: priceFerianteConsumer;
			add int(a[3]) at: a[0] to: priceFerianteConsumerPromedio;
			add int(a[4]) at: a[0] to: priceMayoristaFeriante;
			add int(a[5]) at: a[0] to: volumeMayorista_lastyear;
		}
	}
	
	reflex pricesInfo when: after(starting_date + 1#months){
		//Asignación de nuevos precios por producto dependiendo de la cantidad de producción hasta ese mes, comparandolo con la producción del año pasado.
		used_products <- [];
		
		//obtener la mediana de la sequía y heladas de los últimos tres meses
		list<int> lastheladas <- [];
		list<int> lastsequias <- [];
		list<int> medians;
	
		if(current_date.month = 1){
			lastheladas <- [months_helada[11], months_helada[12], months_helada[current_date.month]];
			lastsequias <- [months_sequia[11], months_sequia[12], months_sequia[current_date.month]];
		}else if(current_date.month = 2){
			lastheladas <- [months_helada[12], months_helada[current_date.month-1], months_helada[current_date.month]];
			lastsequias <- [months_sequia[12], months_sequia[current_date.month-1], months_sequia[current_date.month]];
		}else{
			lastheladas <- [months_helada[current_date.month-2], months_helada[current_date.month-1], months_helada[current_date.month]];
			lastsequias <- [months_sequia[current_date.month-2], months_sequia[current_date.month-1], months_sequia[current_date.month]];
		}
		medians <- [median(lastheladas), median(lastsequias)];
		
		//switch con todos los rangos
		int increasePrice;
		switch medians{
			match_one [[1,2],[2,1]] { increasePrice <- rnd(5,10); }
			match_one [[1,3],[3,1]] { increasePrice <- rnd(10,15); }
			match_one [[2,3],[3,2]] { increasePrice <- rnd(15,20); }
			match_one [[2,2],[3,0],[0,3]] { increasePrice <- rnd(10,20); }
			match [3,3] { increasePrice <- rnd(20,30); }
		}
		
		//subir o mantener el precio y asignarlo a todos los productos.
		if(increasePrice > 0){
			loop a over: listadoProducts{
				actualPrices[a] <- ((100 + increasePrice)/100)*priceFerianteConsumerPromedio[a];
			}	
		}else{
			loop a over: listadoProducts{
				actualPrices[a] <- priceFerianteConsumerPromedio[a];
			}	
		}
	}
	map<int, float> avg_feriantes;
	reflex generateCSVs when: every(1#cycles){
		save [mercadoMayoristaVolumenTotal] to: "Mercado_Mayorista_total.csv" type: "csv";
		loop mes from: 1 to: 12 step: 1 {
			add feriantes mean_of each.ganancias[mes] at: mes to: avg_feriantes;
		}
		save [avg_feriantes] to: "Avg_Feriante.csv" type: "csv";
	}
	
	//predicates for BDI agents
	//FARMER
	predicate esperar <- new_predicate("esperar");
	predicate cosecha_lista <- new_predicate("cosecha lista", true);
	predicate cosecha_nolista <- new_predicate("cosecha lista", false);
	predicate empty_land <- new_predicate("empty land");
	predicate sembrar <- new_predicate("sembrar");
	predicate cosechar <- new_predicate("cosechar"); 
	predicate vender <- new_predicate("vender a mayorista"); 
	
	//FERIANTE
	predicate comprar_mm <- new_predicate("comprar a mercado mayorista");
	
	//CONSUMIDOR
	predicate comprar_feriante <- new_predicate("comprar a feriante");

}

species scheduler schedules:shuffle(farmers)+shuffle(feriantes)+shuffle(consumers);

//Agente agricultores
species farmers skills:[moving] control:simple_bdi schedules: []{
	bool riskLevel <- flip(0.06); 
	rgb my_color <- colors['farmer_color'];
	terrenos terreno;
	int non_sold_vegetables;
	int sold_vegetables;
	list random_products <- [];
	list<int> prices <- [];
	
	
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
		}
	}
	
	//The rules are used to create a desire from a belief. We can specify the priority of the desire with a statement priority.
	rule belief: empty_land new_desire: sembrar;
	
	plan proceso_siembra intention: sembrar{
		
		if(terreno.estado = 1){
			//subdesire 1: Selección de hortaliza según el riesgo de eventos climáticos y el precio/demanda del periodo pasado
			if(!self.riskLevel){
				//Dado que NO toma riesgo, toma el producto con mínimo riesgo --> Si hay varios con mínimo riesgo, random entre ellos
				self.prices <- [];
				self.random_products <- [];
				switch(terreno.plagaRisk){
					match 0 {self.random_products <- sample(minRiskFilteredProducts0,3,false);}
					match 1 {self.random_products <- sample(minRiskFilteredProducts1,3,false);}
					match 2 {self.random_products <- sample(minRiskFilteredProducts2,3,false);}
					match 3 {self.random_products <- sample(minRiskFilteredProducts3,3,false);}
				}

				loop a over: random_products{
					self.prices <- self.prices + priceFerianteConsumerPromedio[string(a)];
				}
				terreno.producto_seleccionado <- random_products[prices index_of(max(prices))];
				//terreno.producto_seleccionado <- any(minRiskFilteredProducts0 o 1 o 2 o 3);
			}else{
				//SI toma riesgo, así que toma cualquier producto --> random entre todos
				switch(terreno.plagaRisk){
					match 0 {terreno.producto_seleccionado <- any(finalRisksProduct0);}
					match 1 {terreno.producto_seleccionado <- any(finalRisksProduct1);}
					match 2 {terreno.producto_seleccionado <- any(finalRisksProduct2);}
					match 3 {terreno.producto_seleccionado <- any(finalRisksProduct3);}
				}
			}
			terreno.estado <- 2;
			terreno.start_date <- current_date plus_days terreno.days_left;
			terreno.days_left <- terreno.days_left + days_cosecha[terreno.producto_seleccionado];
			terreno.end_date <- current_date plus_days terreno.days_left;  
			
			do remove_belief(empty_land);
			do remove_intention(sembrar, true);
			do add_belief(cosecha_nolista);
		}
	}
	
	rule belief: cosecha_nolista new_desire: esperar;
	
	//cuando el terreno está listo para cosechar
	perceive target:terreno when: terreno.estado = 2 {
		//Agregar condiciones para extraer la cosecha
		if(current_date.month = self.end_date.month){
			ask myself{
				do add_belief(cosecha_lista);
				do remove_intention(esperar, true);
				do remove_belief(cosecha_nolista);
			}	
		}
	}
	
	rule belief: cosecha_lista new_desire: cosechar;
	
	plan extraer_cosecha intention: cosechar instantaneous: true{
		//Cambio de estado del terreno (último estado)
		terreno.estado <- 3;
		
		//Extraer la cosecha (modificar la siguiente línea) 
		self.non_sold_vegetables <- int(floor(terreno.area*production[terreno.producto_seleccionado])); //lo que se saca en una ha multiplicado por el área
		
		//Recalcular cuantos días han pasado desde la fecha actual hasta la fecha de cosecha
		terreno.days_left <- int((terreno.end_date - current_date) / 86400);

		//Resetear todo sobre terreno
		terreno.plagaRisk <- rnd_choice([0.85, 0.05, 0.05, 0.05]);
		terreno.historial_productos <- terreno.historial_productos + terreno.producto_seleccionado; 
		if(not(used_products contains terreno.producto_seleccionado)){
			used_products <- used_products + terreno.producto_seleccionado;
		}
		terreno.producto_seleccionado <- nil;
		terreno.start_date <- nil;
		terreno.end_date <- nil;  
		
		//Actualización de beliefs y desires
		do remove_belief(cosecha_lista);
		do remove_intention(cosechar, true);
		do add_desire(vender, 2.0); //se le pone strength de 2 para que primero venda y luego siembre, así no se ejecuta la venta en el siguiente step
		do add_desire(sembrar, 1.0);
		
		//Cambio de estado del terreno (para volver al inicio y sembrar otro producto)
		terreno.estado <- 1;
	}
	
	plan venta_a_mm intention: vender instantaneous: true{
		mercadoMayoristaVol[last(terreno.historial_productos)] <- mercadoMayoristaVol[last(terreno.historial_productos)] + self.non_sold_vegetables;
		mercadoMayoristaVolumenTotal[last(terreno.historial_productos)] <- mercadoMayoristaVolumenTotal[last(terreno.historial_productos)] + self.non_sold_vegetables;
		self.non_sold_vegetables <- 0;
		do remove_intention(vender, true);
	}
	
	aspect base {
        draw circle(70) color: my_color border: #black;  //depth: gold_sold;
    }
}

//Agente feriantes
species feriantes skills:[moving] control:simple_bdi schedules: []{
	rgb my_color <- colors['feriante_color'];
	ferias feria;
	int quantity <- rnd(3,12); //Cantidad de productos que vende el feriante
	list<string> selling_products_list <- []; //Listado de productos sin sus volumenes
	map<string, int> selling_products; //Productos con sus volumenes a la venta	
	map<int, int> ganancias; //primer int es el mes y el segundo int son las ganancias en CLP
	
	init{
		//Assign feria
		list<ferias> f <- ferias where (each.puestos_vacios > 0);
		feria <- one_of(f);
		feria.puestos_vacios <- feria.puestos_vacios - 1;
		self.location <- any_location_in(feria);
		
		//Assign productos
		list p <- sample(listadoProducts,quantity,false);
		loop i over:p{
			add 0 at:i to: selling_products;
			selling_products_list <- selling_products_list + i;
		}
		
		//Inicializar ganancias por mes
		loop i from: 1  to: 12 step:1{
			add 0 at:i to:ganancias;
		}
		
		//Deseo inicial y único
		do add_desire(comprar_mm);
	}
	
	reflex monthlyReset{
		loop i over: selling_products_list{
			selling_products[i] <- 0;
		}
	}
	
	plan compra_a_mayoristas intention: comprar_mm{
		int initialVol;
		loop times: feria.days_puesto*4{
			loop a over:selling_products_list{
				if(months_venta[a] != '' and (contains(months_venta[a], current_month) or contains(months_venta[a], 'Todos')) and mercadoMayoristaVol[a] > 0){
					if(volumeMayorista_lastyear[a] != nil and volumeMayorista_lastyear[a] > 0){
						//Hace la proporcion con la hortaliza/fruta con mayor volumen del año pasado
						int mayoristaVol <- first(volumeMayorista_lastyear); //mayor volumen del año pasado
						string biggestProd <- volumeMayorista_lastyear index_of(mayoristaVol); //producto con mayor vol
						initialVol <- int((volumeMayorista_lastyear[a] * volumeOneFeriante[biggestProd])/mayoristaVol);
						if(mercadoMayoristaVol[a] < initialVol){
							selling_products[a] <- selling_products[a] + mercadoMayoristaVol[a];
							mercadoMayoristaVol[a] <- 0;
						}else{	
							selling_products[a] <- selling_products[a] + initialVol;
							mercadoMayoristaVol[a] <- mercadoMayoristaVol[a] - initialVol;
						}
					}else{
						//Obtiene desde el volume_oneFeriante
						if(mercadoMayoristaVol[a] < volumeOneFeriante[a]){
							selling_products[a] <- selling_products[a] + mercadoMayoristaVol[a];
							mercadoMayoristaVol[a] <- 0;
						}else{	
							selling_products[a] <- selling_products[a] + volumeOneFeriante[a];
							mercadoMayoristaVol[a] <- mercadoMayoristaVol[a] - volumeOneFeriante[a];
						}
					}
				}
			}
		}
		loop c over: selling_products_list{
			feriantesVolumenTotal[c] <- feriantesVolumenTotal[c] + selling_products[c];
		}
	}
	
	aspect base {
        draw circle(70) color: my_color border: #black;  //depth: gold_sold;
    }
}

species consumers control:simple_bdi schedules:[]{
	rgb my_color <-  colors['consumer_color'];
	//ferias feria;
	list<feriantes> puestos_de_feria;
	int presupuesto;
	//int kilos_comprados <- 0; //puede no ser necesario 
	list<string> products_a_comprar;
	map<string,int> productos_comprados <- [];
	
	init{
		self.location <- {92455.63984443404, 57339.11668546737, 0.0};
		//Assign feria (permanente)
		/*list<ferias> f <- ferias where(each.personas > 0);
		feria <- one_of(f);
		feria.personas <- feria.personas - 1;*/
		
		//Assign inicialmente 10 o menos feriantes random
		//list<feriantes> fer <- feriantes where(each.feria = feria);
		/*list<feriantes> fer <- feriantes of_generic_species feriantes;
		puestos_de_feria <- sample(fer, 10, false);
		
		//Assign productos a la venta de ese mes que quiere comprar
		products_a_comprar <- sample(available_products,10, false);
		*/
		//Deseo inicial y único
		do add_desire(comprar_feriante);
	}
	
	reflex monthlyReset{
		//Reset presupuesto
		presupuesto <- rnd(25000,45000,1000);
		
		//Reset puestos de feria
		list<feriantes> fer <- feriantes of_generic_species feriantes;
		puestos_de_feria <- sample(fer, 10, false);
		
		//Reset productos
		products_a_comprar <- sample(available_products,10, false);
		productos_comprados <- [];
		loop prod over:products_a_comprar{
			add 0 at:prod to: productos_comprados;
		}
	}
	
	plan compra_a_feriantes intention: comprar_feriante{
		loop a over:puestos_de_feria{
			loop b over:products_a_comprar{
				int priceToPay <- 0;
				if(presupuesto <= 0){
					break;
				}
				/*Que no se haya comprado ese producto, que el feriante lo venda y que al feriante le quede stock de ese producto */
				if(productos_comprados[b] = 0 and (a.selling_products_list contains b) and (a.selling_products[b] > 0)){ 
					if(a.selling_products[b] < volumeOneConsumer[b]){
						productos_comprados[b] <- a.selling_products[b];
						a.selling_products[b] <- 0; 
					}else{
						productos_comprados[b] <- volumeOneConsumer[b];
						a.selling_products[b] <- a.selling_products[b] - volumeOneConsumer[b];
					}
					priceToPay <- productos_comprados[b]*actualPrices[b];
					a.ganancias[current_date.month] <- a.ganancias[current_date.month] + priceToPay;
					presupuesto <- presupuesto - priceToPay;
				}
			}
			if(presupuesto <= 0){
				break;
			}
		}
		loop c over:products_a_comprar{
			consumersVolumenTotal[c] <- consumersVolumenTotal[c] + productos_comprados[c];
		}
	}
	
	aspect base {
        draw circle(170) color: my_color border: #black;  //depth: gold_sold;
    }
	
}

/*They are not agents, its just for display */
species terrenos {
	//Atributos visuales
	rgb color <- #white;
	rgb border <- #black;
	//Atributos para el producto a sembrar
	list<string> finalProducts;
	list<float> riskValues;
	list<string> minRiskFilteredProducts;
	string producto_seleccionado;
	//Atributos del terreno en sí
	int estado <- 0; //0 --> sin agricultor, 1 --> vacío, 2 --> cultivando, 3 --> cosecha lista.
	list<string> historial_productos <- [];
	int plagaRisk <- rnd_choice([0.85, 0.05, 0.05, 0.05]);
	float area;
	int days_left <- 0;
	date start_date;
	date end_date; 
	  
	aspect base {
		draw shape color: color border: border;
	}
}

species ferias {
	rgb color <- #red;
	int puesto_verduras;
	int puestos_vacios;
	int personas; 
	string dias_puesto;
	int days_puesto;
	aspect base{
		draw shape color: color;
	}
	init{
		if(contains(dias_puesto,"-")){
			days_puesto <- 2;
		}else{
			days_puesto <- 1;
		}
		personas <- puesto_verduras*2;
	}
}

species comunas {
	rgb border <- #grey;
	rgb color <- #transparent;
	aspect base {
		draw shape color: color border: border;
	}
}

/*Agente conector a la base de datos PostgreSQL */
species agentDB skills:[SQLSKILL]{
	
	init{
		if(testConnection(POSTGRES)){
			products <- list<list> (select(POSTGRES,"SELECT * FROM productos WHERE valid = true;"));
			products <- products[2];
			loop c over: products{
				add int(c[4]) at:c[0] to: days_cosecha;
				add c[19] at:c[0] to: units;
				add int(c[20]) at:c[0] to: production;
				listadoProducts <- listadoProducts + c[0];
				add c[3] at: c[0] to: months_venta;
				add int(c[21]) at: c[0] to: volumeOneFeriante;
				add int(c[22]) at: c[0] to: volumeOneConsumer;
			}
			/*write "days cosecha: " + days_cosecha;  
			write "units: " + units;
			write "production: " + production;
			write "listadoProducts: " + listadoProducts;
			write "months_venta: " + months_venta;
			write "volumeOneFeriante: " + volumeOneFeriante;
			write "volumeOneConsumer: " + volumeOneConsumer;*/
			
		}else{
			write "Problemas de conexión con la BD.";
		}
	}
}

experiment agriculture_world type: gui {
	   parameter "Shapefiles:" var: shpfiles category: "GIS";
    
	   output{
	   		display map type: java2D{
	   			species comunas aspect:base;
		        species terrenos aspect:base;     
		        species ferias aspect:base; 
		        species farmers aspect:base;
		        species feriantes aspect:base;
		        species consumers aspect:base;
		    }
		    
		    monitor "Step actual " value: current_month + ' ' + current_date.year ;
		    monitor "Riesgo Helada" value: risk_scale[generalRisks[0]] ;
		    monitor "Riesgo Ola de calor" value: risk_scale[generalRisks[1]] ;
		    monitor "Riesgo Sequía" value:risk_scale[generalRisks[2]] ;
		    monitor "MM" value: mercadoMayoristaVol;
		    monitor "MM Total" value: mercadoMayoristaVolumenTotal;
		    monitor "FerianteTotal" value: feriantesVolumenTotal;
		    monitor "ConsumerTotal" value: consumersVolumenTotal;
		    monitor "Heladas" value: months_helada;
		    monitor "Sequias" value: months_sequia;
		    monitor "Olas de calor" value: months_oladecalor;
		    monitor "prueba" value: feriantes mean_of(each.ganancias);
		    
			/*display "graficos1" refresh: every(1#cycles){
				chart "Mercado Mayorista Total" type: histogram{
					datalist legend: listadoProducts value: mercadoMayoristaVolumenTotal collect (each);
				}
			}
			display "graficos2" refresh: every(1#cycles){
				chart "Avg feriante" type: series{
					data "average ganancias" value: feriantes mean_of each.ganancias color: #green;
				}
			}*/
			
			/*display "graficos2" refresh: every(1#cycles){
				chart "Mercado Mayorista" type: histogram{
					datalist legend: listadoProducts value: mercadoMayoristaVol collect (each);
				}
			}
			
			display "graficos3" refresh: every(1#cycles){
				chart "Compra feriantes acumulada" type: histogram{
					loop i from: 0 to: 20 step: 1 {
					 	data string(listadoProducts[i]) value: feriantes collect ((each.selling_products_list contains listadoProducts[i]) ? each.selling_products[listadoProducts[i]] : 0);
					}
					//datalist legend: feriantes collect (each.selling_products_list) value: feriantes collect (each.selling_products);
				}
			}*/
	   	} 
}  
