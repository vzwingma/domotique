/**
 * 
 */
package com.terrier.domotique.interfaces.box.impl;

import java.security.InvalidKeyException;
import java.security.NoSuchAlgorithmException;
import java.security.SignatureException;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.terrier.domotique.interfaces.box.IFreeboxAuthentication;

/**
 * @author vzwingma
 *
 */
public class FreeboxAuthenticationImpl implements IFreeboxAuthentication {
	
	private static final Logger LOG = LoggerFactory.getLogger(FreeboxAuthenticationImpl.class);

	// App token
	private String appToken;
	// App id
	private String appId;
	
	
	/* (non-Javadoc)
	 * @see com.terrier.domotique.interfaces.box.IFreeboxAuthentication#authenticate(java.lang.String)
	 */
	@Override
	public String authenticate(String challengeBody) {
		
		LOG.info("[INTERFACE BOX] Authentification Freebox : Challenge");
		LOG.debug("[INTERFACE BOX] 	ChallengeBody 	: {}", challengeBody);

		int debutChallenge = challengeBody.indexOf("challenge") + 12;
		int finChallenge = challengeBody.indexOf("\",\"", debutChallenge);
		String challenge = challengeBody.substring(debutChallenge, finChallenge);
		challenge = challenge.replaceAll("\\\\", "");
		LOG.debug("[INTERFACE BOX] 	Challenge 		: {}", challenge);
		LOG.debug("[INTERFACE BOX]	App Token 		: {}", appToken);

		String password = null;
		try {
			password = HmacSha1Signature.calculateRFC2104HMAC(challenge, appToken);
		} catch (InvalidKeyException | SignatureException
				| NoSuchAlgorithmException e) {
			LOG.error("[INTERFACE BOX] Erreur lors du calcul du mot de passe");
		}
		StringBuilder authPOSTBody = new StringBuilder("{\n").append(
		"	\"app_id\": \"").append(appId).append("\",\n").append(
		"	\"password\": \"").append(password).append("\"\n").append(
		"}");
		
		LOG.debug("[INTERFACE BOX] >> \n{}", authPOSTBody.toString());
		
		return authPOSTBody.toString();
	}
	
	
	/* (non-Javadoc)
	 * @see com.terrier.domotique.interfaces.box.IFreeboxAuthentication#getSessionToken(java.lang.String)
	 */
	public String getSessionToken(String responseAuth){
		LOG.debug("[INTERFACE BOX] Session Token response : {}", responseAuth);
		int debutSessionToken = responseAuth.indexOf("session_token") + 16;
		int finChallenge = responseAuth.indexOf("\",\"", debutSessionToken);
		
		String sessionToken = responseAuth.substring(debutSessionToken, finChallenge);
		sessionToken = sessionToken.replaceAll("\\\\", "");
	
		LOG.debug("[INTERFACE BOX] 	Session Token : {}", sessionToken);
		return sessionToken;
	}
	
	/**
	 * @return appToken
	 */
	public String getAppToken() {
		return appToken;
	}
	
	
	/**
	 * Set app token
	 * @param appToken
	 */
	public void setAppToken(String appToken) {
		this.appToken = appToken;
	}


	/**
	 * @return the appId
	 */
	public String getAppId() {
		return appId;
	}


	/**
	 * @param appId the appId to set
	 */
	public void setAppId(String appId) {
		this.appId = appId;
	}
}
