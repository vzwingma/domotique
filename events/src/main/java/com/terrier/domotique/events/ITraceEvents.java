/**
 * 
 */
package com.terrier.domotique.events;

import org.osgi.service.event.Event;



/**
 * Traçes des événements EventAdmin
 * @author vzwingma
 *
 */
public interface ITraceEvents {

	
	/**
	 * Traces des événements
	 * @param event
	 */
	public void traceEvent(Event event);
}
