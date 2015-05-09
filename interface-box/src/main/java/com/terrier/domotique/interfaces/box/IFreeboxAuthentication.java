/**
 * 
 */
package com.terrier.domotique.interfaces.box;

/**
 * Authentification Freebox
 * @author vzwingma
 *
 */
public interface IFreeboxAuthentication {

	
	/**
	 * Authentification Freebox
	 * @param challengeBody body Camel contenant le challenge
	 * @return le mot de passe token
	 */
	String authenticate(String challengeBody);
	
	
	/**
	 * Retourne le sessionToken
	 * @param responseAuth
	 * @return sessionToken
	 */
	String getSessionToken(String responseAuth);
}
