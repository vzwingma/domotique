#include <wiringPi.h>
#include <iostream>
#include <stdio.h>
#include <sys/time.h>
#include <time.h>
#include <stdlib.h>
#include <sched.h>
#include <sstream>

/*
Par Idleman (idleman@idleman.fr - http://blog.idleman.fr)
Licence : CC by sa
Edite par vzwingma
*/

using namespace std;


int pin;
bool bit2[26]={};              // 26 bit Identifiant emetteur
bool bit2Interruptor[4]={}; 
int interruptor;
int sender;
string onoff;

// Log des actions
void log(string a){
	//Décommenter pour avoir les logs
	cout << a << endl;
}

// Scheduler en real time pour utiliser les microsecondes
void scheduler_realtime() {

	struct sched_param p;
	p.__sched_priority = sched_get_priority_max(SCHED_RR);
	if( sched_setscheduler( 0, SCHED_RR, &p ) == -1 ) {
		perror("Failed to switch to realtime scheduler.");
	}
}

// Retour au mode standard
void scheduler_standard() {

	struct sched_param p;
	p.__sched_priority = 0;
	if( sched_setscheduler( 0, SCHED_OTHER, &p ) == -1 ) {
		perror("Failed to switch to normal scheduler.");
	}
}




//Envois d'une pulsation (passage de l'etat haut a l'etat bas)
//1 = 281 haut puis 1346 bas
//0 = 281 haut puis 281 bas
void sendBit(bool b) {
	 if (b) {
	   digitalWrite(pin, HIGH);
	   delayMicroseconds(281);   //281 orinally, but tweaked 310
	   digitalWrite(pin, LOW);
	   delayMicroseconds(1346);  //1225 orinally, but tweaked 1340
	 }
	 else {
	   digitalWrite(pin, HIGH);
	   delayMicroseconds(281);   //281 orinally, but tweaked 310
	   digitalWrite(pin, LOW);
	   delayMicroseconds(281);   //281 orinally, but tweaked 310
	 }
}

//Calcul le nombre 2^chiffre indiqué, fonction utilisé par itob pour la conversion decimal/binaire
unsigned long power2(int power){
	unsigned long integer=1;
	for (int i=0; i<power; i++){
		integer*=2;
	}
	return integer;
} 


//Convertis un nombre en binaire, nécessite le nombre, et le nombre de bits souhaité en sortie (ici 26)
// Stocke le résultat dans le tableau global "bit2"
void itob(unsigned long integer, int length)
{
	for (int i=0; i<length; i++){
	  if ((integer / power2(length-1-i))==1){
		integer-=power2(length-1-i);
		bit2[i]=1;
	  }
	  else bit2[i]=0;
	}
}

void itobInterruptor(unsigned long integer, int length)
{
	for (int i=0; i<length; i++){
	  if ((integer / power2(length-1-i))==1){
		integer-=power2(length-1-i);
		bit2Interruptor[i]=1;
	  }
	  else bit2Interruptor[i]=0;
	}
}


//Envoie d'une paire de pulsation radio qui definissent 1 bit réel : 0 =01 et 1 =10
//c'est le codage de manchester qui necessite ce petit bouzin, ceci permet entre autres de dissocier les données des parasites
void sendPair(bool b) {
	if(b)
	{
		sendBit(true);
		sendBit(false);
	}
	else
	{
		sendBit(false);
		sendBit(true);
	}
}


//Fonction d'envois du signal
//recoit en parametre un booleen définissant l'arret ou la marche du matos (true = on, false = off)
void transmit(int blnOn)
{
 int i;

 // Sequence de verrou anoncant le départ du signal au recepeteur
 digitalWrite(pin, HIGH);
 delayMicroseconds(281);     // un bit de bruit avant de commencer pour remettre les delais du recepteur a 0
 digitalWrite(pin, LOW);
 delayMicroseconds(9900);     // premier verrou de 9900µs
 digitalWrite(pin, HIGH);   // high again
 delayMicroseconds(281);      // attente de 281µs entre les deux verrous
 digitalWrite(pin, LOW);    // second verrou de 2675µs
 delayMicroseconds(2772);
 digitalWrite(pin, HIGH);  // On reviens en état haut pour bien couper les verrous des données

 // Envoie du code emetteur (272946 = 1000010101000110010  en binaire)
 for(i=0; i<26;i++)
 {
   sendPair(bit2[i]);
 }

 // Envoie du bit définissant si c'est une commande de groupe ou non (26em bit)
 sendPair(false);

 // Envoie du bit définissant si c'est allumé ou eteint 27em bit)
 sendPair(blnOn);

 // Envoie des 4 derniers bits, qui représentent le code interrupteur, ici 0 (encode sur 4 bit donc 0000)
 // nb: sur  les télécommandes officielle chacon, les interrupteurs sont logiquement nommés de 0 à x
 // interrupteur 1 = 0 (donc 0000) , interrupteur 2 = 1 (1000) , interrupteur 3 = 2 (0100) etc...
 for(i=0; i<4;i++)
 {
	if(bit2Interruptor[i]==0){
		sendPair(false);
	}else{
		sendPair(true);
	}
}
 
 digitalWrite(pin, HIGH);   // coupure données, verrou
 delayMicroseconds(281);      // attendre 281µs
 digitalWrite(pin, LOW);    // verrou 2 de 2675µs pour signaler la fermeture du signal

}





// Démarrage du programme
int main (int argc, char** argv)
{
	// Vérification des permissions
	

	scheduler_realtime();

//	log(">>>*<<<");
	pin = atoi(argv[1]);
	sender = atoi(argv[2]);
	interruptor = atoi(argv[3]);
	onoff = argv[4];
		
	printf("{");
	printf("\"commande\":{");
	printf("   \"commande\":\"%s\",", argv[4]);
	// printf("   \"telecommande\":%s,", argv[2]);
	printf("   \"bouton\":\"%s\",", argv[3]);
	printf("   \"pin\":\"#%s\"", argv[3]);
	printf("},");
	
	//Si on ne trouve pas la librairie wiringPI, on arrête l'execution
    if(wiringPiSetup() == -1)
    {
        printf("\"erreur\":\"Librairie Wiring PI introuvable, veuillez lier cette librairie...\"");
		//printf("}");
        return -1;

    }
    pinMode(pin, OUTPUT);
	
	printf("\"resultat\":{");
	printf("   \"gpio\":\"ok\",");
	// 5 fois la commande
	for(int exec = 0; exec < 5 ; exec ++){

		itob(sender,26);            // conversion du code de l'emetteur (ici 8217034) en code binaire
		itobInterruptor(interruptor,4);
		
		
		if(onoff=="on"){
			printf("   \"radio_%d\":\"on\",", exec);
			for(int i=0;i<5;i++){
				transmit(true);            // envoyer ON
				delay(10);                 // attendre 10 ms (sinon le socket nous ignore)
			}
		}
		else{
			printf("   \"radio_%d\":\"off\",", exec);
			for(int i=0;i<5;i++){
				transmit(false);           // envoyer OFF
				delay(10);                // attendre 10 ms (sinon le socket nous ignore)
			}
		}
		scheduler_standard();
	}
	printf("   \"scheduler\":\"standard\"");
	printf("}");
	printf("}");
}

