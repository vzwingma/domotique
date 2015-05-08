package com.terrier.domotique.interfaces.tv;

import org.apache.camel.test.blueprint.CamelBlueprintTestSupport;
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

}
