/**
 * 
 */
package com.terrier.domotique.interfaces.box.reseaux;

import java.io.File;
import java.io.FileInputStream;
import java.util.ArrayList;

import org.apache.camel.Exchange;
import org.apache.camel.component.gson.GsonDataFormat;
import org.apache.camel.impl.DefaultExchange;
import org.apache.camel.test.blueprint.CamelBlueprintTestSupport;
import org.junit.Test;

import com.google.gson.FieldNamingPolicy;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.terrier.domotique.interfaces.box.impl.FreeboxReseauImpl;

/**
 * Périphérique Réseau
 * @author vzwingma
 *
 */
public class TestPeripheriquesReseau extends CamelBlueprintTestSupport {
	
	//Override
	protected String getBlueprintDescriptor() {
		return "/blueprint/test-blueprint.xml";
	}
	
	/**
	 * Test du parsing
	 * @throws Exception
	*/
	@Test
	public void testParsingInterfacesReseau() throws Exception{
		
		FileInputStream fis = new FileInputStream(new File("src/test/resources/interfaces-reseaux.json"));
		
		Gson gson = new GsonBuilder().create();
		GsonDataFormat dataFormat = new GsonDataFormat(gson, PeripheriquesReseau.class);
		dataFormat.setFieldNamingPolicy(FieldNamingPolicy.LOWER_CASE_WITH_UNDERSCORES);
		
		Exchange exchange = new DefaultExchange(context);
		PeripheriquesReseau peripheriques = (PeripheriquesReseau)dataFormat.unmarshal(exchange, fis);
		
		assertNotNull(peripheriques);
		assertTrue(peripheriques.isSuccess());
		// Résultat du parsing
		assertTrue(peripheriques.getResult().get(0).isReachable());
		assertTrue(peripheriques.getResult().get(0).isActive());
		assertEquals(HostTypeEnum.SMARTPHONE, peripheriques.getResult().get(0).getHostType());
				
				
		assertFalse(peripheriques.getResult().get(1).isReachable());
		assertFalse(peripheriques.getResult().get(1).isActive());
		assertEquals(HostTypeEnum.TABLETTE, peripheriques.getResult().get(1).getHostType());
	} 
	
	/**
	 * Test les changements d'états
	 */
	@Test
	public void testEtatSmartphones(){
		FreeboxReseauImpl reseau = new FreeboxReseauImpl();
		
		PeripheriquesReseau listeConnexionsReseau = new PeripheriquesReseau();
		PeripheriqueReseau peripherique = new PeripheriqueReseau();
		peripherique.setActive(true);
		peripherique.setReachable(true);
		peripherique.setPrimary_name("Test");
		peripherique.setHost_type("smartphone");
		listeConnexionsReseau.setResult(new ArrayList<PeripheriqueReseau>());
		listeConnexionsReseau.getResult().add(peripherique);
		// Pas de changement
		assertTrue(reseau.getChangementPresenceSmartphones(listeConnexionsReseau));
		
		// Perte du signal 1x
		peripherique.setReachable(false);
		assertNull(reseau.getChangementPresenceSmartphones(listeConnexionsReseau));
		// Perte du signal 2x
		assertNull(reseau.getChangementPresenceSmartphones(listeConnexionsReseau));
		// Perte du signal 3x : Changement d'état
		assertFalse(reseau.getChangementPresenceSmartphones(listeConnexionsReseau));
		// Perte du signal 4x 
		assertNull(reseau.getChangementPresenceSmartphones(listeConnexionsReseau));
		// Perte du signal 5x
		assertNull(reseau.getChangementPresenceSmartphones(listeConnexionsReseau));
		// Retrouve le signal
		peripherique.setReachable(true);
		assertTrue(reseau.getChangementPresenceSmartphones(listeConnexionsReseau));
		// Pas de changement
		assertNull(reseau.getChangementPresenceSmartphones(listeConnexionsReseau));

	}
}
