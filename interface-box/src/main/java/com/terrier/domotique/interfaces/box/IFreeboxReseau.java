/**
 * 
 */
package com.terrier.domotique.interfaces.box;

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
	void getListeConnexionsReseau(String listeConnexionsReseau);

}
