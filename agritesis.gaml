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
		
	}

}

species agentDB skills:[SQLSKILL]{
	
	list<list> vegetables <- [];
	
	init{
		if(!testConnection(POSTGRES)){
			vegetables <- list<list> (select(POSTGRES, "SELECT * FROM vegetables ;"));
			vegetables <- vegetables[2];
			write "aver en que quedó" + vegetables; 
		}else{
			write "Problemas de conexión con la BD.";
		}
		 
	}
	      
	      // select
		/*list <list> vegetables <- list <list> ( self select (
		select :" SELECT * FROM vegetables ;") ) ;
		
		write "seleccionando vegetales " + vegetables;*/
	
}

experiment default_expr type: gui {}  
