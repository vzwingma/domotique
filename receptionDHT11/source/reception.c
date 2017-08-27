/*
 *  dht11.c:
 *	Read DHT11 sensor
 */
 
#include <wiringPi.h>
 
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#define MAXTIMINGS	85
#define DHTPIN		7
int dht11_dat[5] = { 0, 0, 0, 0, 0 };
 
/** Lecture du capteur DHT11 **/
int* read_dht11_dat()
{
	uint8_t laststate	= HIGH;
	uint8_t counter		= 0;
	uint8_t j			= 0, i;
 
	dht11_dat[0] = dht11_dat[1] = dht11_dat[2] = dht11_dat[3] = dht11_dat[4] = 0;
 
	/* pull pin down for 18 milliseconds */
	pinMode( DHTPIN, OUTPUT );
	digitalWrite( DHTPIN, LOW );
	delay( 18 );
	/* then pull it up for 40 microseconds */
	digitalWrite( DHTPIN, HIGH );
	delayMicroseconds( 40 );
	/* prepare to read the pin */
	pinMode( DHTPIN, INPUT );
 
	/* detect change and read data */
	for ( i = 0; i < MAXTIMINGS; i++ )
	{
		counter = 0;
		while ( digitalRead( DHTPIN ) == laststate )
		{
			counter++;
			delayMicroseconds( 1 );
			if ( counter == 255 )
			{
				break;
			}
		}
		laststate = digitalRead( DHTPIN );
 
		if ( counter == 255 )
			break;
 
		/* ignore first 3 transitions */
		if ( (i >= 4) && (i % 2 == 0) )
		{
			/* shove each bit into the storage bytes */
			dht11_dat[j / 8] <<= 1;
			if ( counter > 16 )
				dht11_dat[j / 8] |= 1;
			j++;
		}
	}
 
	/*
	 * check we read 40 bits (8bit x 5 ) + verify checksum in the last byte
	 * print it out if data is good
	 */
	if ( (j >= 40) &&
	     (dht11_dat[4] == ( (dht11_dat[0] + dht11_dat[1] + dht11_dat[2] + dht11_dat[3]) & 0xFF) ) )
	{
		return dht11_dat;
	}
	else
	{
	//	printf( "[DHT11] Les données sont incorrectes. Recheche... \n" );
	}
}
 
int main( void )
{
	// printf( "[DHT11] Raspberry Pi wiringPi DHT11 Temperature reader\n" );
 	uint8_t counterread	= 0;
	
	if ( wiringPiSetup() == -1 )
	{
		exit( 1 );
	}
	counterread = 0;
	
	
	while ( counterread < 20 )
	{
		counterread ++;
		read_dht11_dat();
		
		int i;
		char buf[100];
		// Création de JSON à la main
		sprintf(buf, "{ \"humidite\":%d.%d, \"temperature\":%d.%d, \"log\":\"Humidite = %d.%d%, Temperature = %d.%d°C \"}", dht11_dat[0], dht11_dat[1], dht11_dat[2], dht11_dat[3], dht11_dat[0], dht11_dat[1], dht11_dat[2], dht11_dat[3]);
		
		// Fin si les données sont correctees
		if(dht11_dat[0] > 0 && dht11_dat[0] < 100 && dht11_dat[2] > 0 && dht11_dat[2] < 40){
			printf("%s\n", buf);
			exit(0);
		}
		delay( 500 ); /* wait 1sec to refresh */
	}
 	return(0);
}
