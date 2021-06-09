/**
* Name: model1
* Based on the internal empty template. 
* Author: shalini
* Tags: 
*/


model human_rats

/* Insert your model definition here */

/*Características del mundo */
global{
	int number_of_humans <- 50;
	int number_of_rats <- 20;
	
	/*Creación e inicialización de los agentes en la simulación */
	/*Todos los inits se computan al inicio de la simulación */
	init{
		create humans number:number_of_humans;
		create rats number:number_of_rats;
	}
}

/* Definición de especies que poblarán la población */
/* SKILLS: are used to give some specific attributes and actions used to fulfill a certain attribute */
/* REFLEX: are used to give/create behaviour for our agent, which is executed at every step */
species humans skills:[moving]{
	/*Atributos del agente */
	bool is_infected <- false;
	
	reflex moving{
		do wander;	
	}	
	
	/*Aspecto visual */
	aspect base{
		draw circle(2) color: (is_infected) ? #red : #blue;
	}
}

species rats skills:[moving]{
	bool is_infected <- flip(0.5);
	int attack_range <- 5;
	
	reflex moving{
		do wander;
	}
	
	reflex attack when: !empty(humans at_distance attack_range){
		ask humans at_distance attack_range{
			/* self es el humano y myself el rat */
			if(self.is_infected){
				myself.is_infected <- true; 
			}else if(myself.is_infected){
				self.is_infected <- true;
			}
		}
	}
	/*Aspecto visual */
	aspect base{
		draw circle(1) color: (is_infected) ? #red : #blue;
	}
}

/* Se definen los inputs y outputs de la simulación */
experiment my_experiment type:gui{
	output{
		display my_display{
		  	 species humans aspect:base;
		  	 species rats aspect:base;
		}
	}
}