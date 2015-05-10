package com.terrier.domotique.events;

import java.util.Map;

import org.osgi.service.event.Event;

/**
 * Statuts des modules
 * @author vzwingma
 *
 */
public interface IStatutsModules {

	
	/**
	 * Reception des événements
	 * @param event événement 
	 */
	public void receiveBundleEvent(Event event);
	
	
	/**
	 * @return le statut des bundles
	 */
	public Map<String, Boolean> getStatutsModules();
}
