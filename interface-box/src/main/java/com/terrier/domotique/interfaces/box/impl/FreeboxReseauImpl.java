/**
 * 
 */
package com.terrier.domotique.interfaces.box.impl;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.terrier.domotique.interfaces.box.IFreeboxReseau;

/**
 * @author vzwingma
 *
 */
public class FreeboxReseauImpl implements IFreeboxReseau {

	
	private static final Logger LOG = LoggerFactory.getLogger(FreeboxReseauImpl.class);
	/* (non-Javadoc)
	 * @see com.terrier.domotique.interfaces.box.IFreeboxReseau#getListeConnexionsReseau(java.lang.String)
	 */
	@Override
	public void getListeConnexionsReseau(String listeConnexionsReseau) {
		LOG.info("[FREEBOX] connexion réseaux : {}", listeConnexionsReseau);
	}

}
