package com.terrier.domotique.events.impl;

import java.util.HashMap;
import java.util.Map;

import org.osgi.service.event.Event;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.terrier.domotique.events.IStatutsModules;

/**
 * Statuts des modules
 * @author vzwingma
 *
 */
public class StatutsModulesImpl implements IStatutsModules {


	// Logs
	private static final Logger LOG = LoggerFactory.getLogger(StatutsModulesImpl.class);
	
	private Map<String, Boolean> statutsBundles = new HashMap<String, Boolean>();
	
	// Topics des bundles KO
	private final String[] bundleKOTopics = {
			"org/osgi/framework/BundleEvent/STOPPED" ,
			"org/osgi/framework/BundleEvent/UNRESOLVED",
			"org/osgi/framework/BundleEvent/RESOLVED"
			};
	// Topics des bundles OK
	private final String[] bundleOKTopics = {
			"org/osgi/framework/BundleEvent/STARTED"
			};
	
	


	/* (non-Javadoc)
	 * @see com.terrier.domotique.events.ITraceEvents#traceEvent(org.w3c.dom.events.Event)
	 */
	@Override
	public void receiveBundleEvent(Event event) {
		
		String topic = event.getTopic();
		String bundleName = (String)event.getProperty("bundle.symbolicName");
		// Liste des status KO
		for (String bundleKOTopic : bundleKOTopics) {
			if(bundleKOTopic.equals(topic)){
				statutsBundles.put(bundleName, Boolean.FALSE);
				return;
			}
		}
		// Liste des statuts OK
		for (String bundleOKTopic : bundleOKTopics) {
			if(bundleOKTopic.equals(topic)){
				statutsBundles.put(bundleName, Boolean.TRUE);
				return;
			}
		}
		statutsBundles.put(bundleName, null);
	}




	/**
	 * @return le statut des bundles
	 */
	public Map<String, Boolean> getStatutsModules() {
		LOG.info("Statut des bundles : {}", statutsBundles);
		return statutsBundles;
	}
}
