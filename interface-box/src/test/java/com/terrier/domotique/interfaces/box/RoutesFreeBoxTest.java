package com.terrier.domotique.interfaces.box;

import org.apache.camel.test.blueprint.CamelBlueprintTestSupport;
import org.junit.Test;

/**
 * Tests des routes Freebox
 * @author vzwingma
 *
 */
public class RoutesFreeBoxTest extends CamelBlueprintTestSupport {
	@Override
	protected String getBlueprintDescriptor() {
		return "/OSGI-INF/blueprint/interface-box-blueprint.xml";
	}

	/**
	 * Routes
	 * @throws Exception
	 */
	@Test
	public void testRoutes() throws Exception {

		assertEquals(4, context.getRoutes().size());
		
		Thread.sleep(4000);
	}

}
