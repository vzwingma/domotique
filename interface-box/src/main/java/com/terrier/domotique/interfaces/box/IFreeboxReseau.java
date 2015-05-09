/**
 * 
 */
package com.terrier.domotique.interfaces.box;

import com.terrier.domotique.interfaces.box.reseaux.PeripheriquesReseau;

/**
 * Interface Réseau de la freebox
 * @author vzwingma
 *
 */
public interface IFreeboxReseau {
	
	
	/**
	 * Fournit la liste des éléments réseau connectés
	 * @param listeConnexionsReseau liste des connexions réseaux
	 */
	Boolean getChangementPresenceSmartphones(PeripheriquesReseau listePeripheriques);
}
