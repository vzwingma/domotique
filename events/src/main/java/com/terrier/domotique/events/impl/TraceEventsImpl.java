/**
 * 
 */
package com.terrier.domotique.events.impl;

import org.osgi.service.event.Event;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.terrier.domotique.events.ITraceEvents;

/**
 * @author vzwingma
 *
 */
public class TraceEventsImpl implements ITraceEvents {

	
	private static final Logger LOG = LoggerFactory.getLogger(TraceEventsImpl.class);

	/* (non-Javadoc)
	 * @see com.terrier.domotique.events.ITraceEvents#traceEvent(org.w3c.dom.events.Event)
	 */
	@Override
	public void traceEvent(Event event) {
		LOG.info("[EVENTS] Réception d'un événement : {}", event.getTopic());
		for (String propName : event.getPropertyNames()) {
			LOG.info("[EVENTS] 	> {} : {}", propName, event.getProperty(propName));	
		}
		
	}

}
