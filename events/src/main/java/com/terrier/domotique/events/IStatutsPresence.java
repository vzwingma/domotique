/**
 * 
 */
package com.terrier.domotique.events;

import org.osgi.service.event.Event;

/**
 * Présence à la maison
 * @author vzwingma
 *
 */
public interface IStatutsPresence {

	

	
	/**
	 * Event de présence des smartphones
	 * @param event evenement
	 */
	public void receiveSmartphonesEvent(Event event) ;

	
	
	/**
	 * @return le statut de présence de personnes
	 */
	public Boolean getPresence();
}
