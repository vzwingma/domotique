package com.terrier.domotique.interfaces.box.reseaux;

import java.util.List;

/**
 * Liste des périphériques réseau connectés à la Freebox
 * @author vzwingma
 *
 */
public class PeripheriquesReseau {

	/**
	 *  Résultat de l'appel
	 */
	private boolean success;
	// Liste des périphériques
	private List<PeripheriqueReseau> result; 
	
	/**
	 * @return the success
	 */
	public boolean isSuccess() {
		return success;
	}

	/**
	 * @param success the success to set
	 */
	public void setSuccess(boolean success) {
		this.success = success;
	}

	/**
	 * @return the result
	 */
	public List<PeripheriqueReseau> getResult() {
		return result;
	}

	/**
	 * @param result the result to set
	 */
	public void setResult(List<PeripheriqueReseau> result) {
		this.result = result;
	}
}
