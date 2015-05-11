package com.terrier.domotique.interfaces.tv.impl;

import java.util.Arrays;
import java.util.List;

import org.apache.camel.Exchange;
import org.apache.camel.component.mock.MockEndpoint;
import org.apache.camel.impl.DefaultExchange;
import org.apache.camel.test.blueprint.CamelBlueprintTestSupport;
import org.junit.Test;

/**
 * Test du splitter
 * @author vzwingma
 *
 */
public class TestChannelSplitter extends CamelBlueprintTestSupport{

	
	
	@Override
	protected String getBlueprintDescriptor() {
		return "/OSGI-INF/test-blueprint/test-tv-blueprint.xml";
	}
	
	
	
	/* (non-Javadoc)
	 * @see org.apache.camel.test.blueprint.CamelBlueprintTestSupport#includeTestBundle()
	 */
	@Override
	protected boolean includeTestBundle() {
		return true;
	}



	@Override
	protected String getBundleFilter() {
	  // I don't want test container to scan and load Logback bundle during the test
	  return null;
	}
	
	/**
	 * Test du split java
	 */
	@Test
	public void testSplit(){
		
		ChannelSplitter splitter = new ChannelSplitter();

		Exchange exchange = new DefaultExchange(context);	
		assertNull(splitter.split(exchange));
		
		exchange.getIn().setHeader("chaine", "102");
		assertEquals(Arrays.asList(new String[]{"1", "0", "2"}), (List<String>)splitter.split(exchange));
	}
	
	
	/**
	 * Test de la route avec split
	 */
	@Test
	public void testRouteSplit() throws Exception{
		template.setDefaultEndpointUri("direct:testSplitter"); 
		template.sendBodyAndHeader("String", "chaine", "102");
		
		MockEndpoint resultEndpoint = context.getEndpoint("mock:result", MockEndpoint.class);
		resultEndpoint.setAssertPeriod(1000);
		resultEndpoint.expectedMessageCount(3);
		

		// now lets assert that the mock:foo endpoint received 2 messages
		resultEndpoint.assertIsSatisfied();
	}
	
}
