package com.terrier.domotique.commandes;

import org.apache.camel.test.blueprint.CamelBlueprintTestSupport;
import org.junit.Test;



/**
 * Test de la route
 * @author vzwingma
 *
 */
public class RouteTest extends CamelBlueprintTestSupport {
	
    @Override
    protected String getBlueprintDescriptor() {
        return "/OSGI-INF/blueprint/commandes-blueprint.xml";
    }

    @Test
    public void testRoute() throws Exception {
		assertEquals(3, context.getRoutes().size());
		
    	Thread.sleep(10000);
    }

}
