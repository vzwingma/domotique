package com.terrier.domotique.events.impl;

import org.osgi.service.event.Event;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.terrier.domotique.communs.NetworkEventEnum;
import com.terrier.domotique.events.IStatutsPresence;

/**
 * Statuts des modules
 * @author vzwingma
 *
 */
public class StatutsPresencesImpl implements IStatutsPresence {


	// Logs
	private static final Logger LOG = LoggerFactory.getLogger(StatutsPresencesImpl.class);
	
	private Boolean presenceSmartphones = null;
	

	

	/* (non-Javadoc)
	 * @see com.terrier.domotique.events.IStatutsPresence#receiveSmartphonesEvent(org.osgi.service.event.Event)
	 */
	@Override
	public void receiveSmartphonesEvent(Event event) {
		this.presenceSmartphones = (Boolean)event.getProperty(NetworkEventEnum.PRESENT.getId());
		
	}



	/* (non-Javadoc)
	 * @see com.terrier.domotique.events.IStatutsPresence#getPresence()
	 */
	@Override
	public Boolean getPresence() {
		LOG.info("Statut de présence : {}", presenceSmartphones);
		return this.presenceSmartphones;
	}
}
