package com.terrier.domotique.interfaces.tv;

import org.apache.camel.impl.DefaultExchange;
import org.apache.camel.test.blueprint.CamelBlueprintTestSupport;
import org.junit.Ignore;
import org.junit.Test;



/**
 * Test des routes du module TV
 * @author vzwingma
 *
 */
public class RoutesTVTest extends CamelBlueprintTestSupport {

	@Override
	protected String getBlueprintDescriptor() {
		return "/OSGI-INF/blueprint/interface-tv-blueprint.xml";
	}

	/**
	 * Routes
	 * @throws Exception
	 */
	@Test
	public void testRoutes() throws Exception {

		assertEquals(3, context.getRoutes().size());

	}

	
	/**
	 * Démarrage de la tv
	 */
	@Ignore
	public void commandeRouteStartTV(){
		template.setDefaultEndpointUri("direct-vm:itv-start-tv");
		template.send(new DefaultExchange(context));
	}
	
	

	
	/**
	 * Démarrage de la tv
	 */
	@Ignore
	public void commandeRouteStopTV(){
		template.setDefaultEndpointUri("direct-vm:itv-stop-tv");
		template.send(new DefaultExchange(context));
	}
}
