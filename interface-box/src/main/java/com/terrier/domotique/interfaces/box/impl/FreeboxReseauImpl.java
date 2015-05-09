/**
 * 
 */
package com.terrier.domotique.interfaces.box.impl;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.terrier.domotique.interfaces.box.IFreeboxReseau;
import com.terrier.domotique.interfaces.box.reseaux.HostTypeEnum;
import com.terrier.domotique.interfaces.box.reseaux.PeripheriqueReseau;
import com.terrier.domotique.interfaces.box.reseaux.PeripheriquesReseau;

/**
 * @author vzwingma
 *
 */
public class FreeboxReseauImpl implements IFreeboxReseau {

	
	private static final Logger LOG = LoggerFactory.getLogger(FreeboxReseauImpl.class);
	/**
	 * Smartphone présents
	 */
	private boolean smartphonesPresents = false;
	
	/**
	 * nb de minutes
	 */
	private int compteurAvantChgtEtat = 3;
	/**
	 * Limite
	 */
	private int limiteAvantChtEtat = 3;
	
	/* (non-Javadoc)
	 * @see com.terrier.domotique.interfaces.box.IFreeboxReseau#getListeConnexionsReseau(java.lang.String)
	 */
	@Override
	public Boolean getChangementPresenceSmartphones(PeripheriquesReseau peripheriquesReseau) {
		LOG.trace("[FREEBOX] Connexion réseaux : {}", peripheriquesReseau.isSuccess());
		
		int nbSmartphonesActifs = 0;
		for (PeripheriqueReseau peripherique : peripheriquesReseau.getResult()) {
			LOG.debug("[FREEBOX]  Périphérique : {} {}, actif={}", 
					peripherique.getHostType(),
					peripherique.getPrimaryName(), 
					peripherique.isActive() && peripherique.isReachable());
			
			if(peripherique.getHostType().equals(HostTypeEnum.SMARTPHONE) && peripherique.isActive() && peripherique.isReachable()){
				nbSmartphonesActifs ++;
			}
		}
		LOG.debug("[FREEBOX] Nombres de smartphones actifs : {}", nbSmartphonesActifs);
		// Si l'état en cours est "vrai" et qu'il n'y a plus de smartphones actifs 
		//on diminue le compteur d'un
		if(nbSmartphonesActifs == 0){
			compteurAvantChgtEtat --;
			LOG.debug("[FREEBOX] Perte de signal depuis {} minutes...", limiteAvantChtEtat - compteurAvantChgtEtat);
		}
		// Si l'état en cours est faux et qu'il y a un smartphone actif : changement d'état immédiat
		if(nbSmartphonesActifs > 0 && !smartphonesPresents){
			LOG.debug("[FREEBOX] Détection de smartphones présents : Etat actif");
			smartphonesPresents = true;
			compteurAvantChgtEtat = limiteAvantChtEtat;
			return Boolean.TRUE;
		}
		else if(compteurAvantChgtEtat == 0){
			LOG.debug("[FREEBOX] Perte de signal depuis {} minutes : Etat inactif", limiteAvantChtEtat);
			smartphonesPresents = false;
			return Boolean.FALSE;
		}
		// Pas de changements d'état
		return null;
	}

	/**
	 * @return the compteurAvantChgtEtat
	 */
	public int getCompteurAvantChgtEtat() {
		return compteurAvantChgtEtat;
	}

	/**
	 * @param compteurAvantChgtEtat the compteurAvantChgtEtat to set
	 */
	public void setCompteurAvantChgtEtat(int compteurAvantChgtEtat) {
		this.compteurAvantChgtEtat = compteurAvantChgtEtat;
	}
}
