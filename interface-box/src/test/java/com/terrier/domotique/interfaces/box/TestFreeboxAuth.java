package com.terrier.domotique.interfaces.box;

import org.junit.Assert;
import org.junit.Test;

import com.terrier.domotique.interfaces.box.impl.FreeboxAuthenticationImpl;

/**
 * Test freebox Authentication
 * @author vzwingma
 *
 */
public class TestFreeboxAuth {

	
	private String challengeBody = "{\"success\":true,\"result\":{\"logged_in\":false,\"challenge\":\"f0CtcW8MD9BcDqqj9ksXw93GW9\\/GSlXj\",\"password_salt\":\"ZtXrpFMhQRSX7NpSD5f\\/sLH7rn01ss7w\"}}";
	
	private String authBody = "{\"result\":{\"session_token\":\"gc5YcosgAv0KUNoiN+oitwb63dX\\/c0wijhVjK2fW9jdfnH9Tsh+tYE9k42hj9dCB\",\"challenge\":\"IZtb+MQBCXtUtjm9nOB4KZqlDmS3Rngt\",\"password_salt\":\"ZtXrpFMhQRSX7NpSD5f\\/sLH7rn01ss7w\",\"permissions\":{\"parental\":false,\"downloader\":true,\"settings\":false,\"calls\":true,\"explorer\":true,\"pvr\":true,\"tv\":true,\"contacts\":true}},\"success\":true} ";
	
	private String sessionBody = "M0zmPRJdr7GGKt60cLbGSx9M0HyfI9P61DX\\/sqKk1RUuWv\\/2Y\\/xgBrwgPKcRIOyO"; 


	
	/**
	 * Test de l'authentification
	 */
	@Test
	public void testAuthenticate(){
		FreeboxAuthenticationImpl auth = new FreeboxAuthenticationImpl();
		auth.setAppToken("apptoken");
		auth.setAppId("domotique.box");
		auth.authenticate(challengeBody);
	}
	
	/**
	 * Test de l'authentification
	 */
	@Test
	public void testSessionToken(){
		FreeboxAuthenticationImpl auth = new FreeboxAuthenticationImpl();
		auth.setAppToken("apptoken");
		auth.setAppId("domotique.box");
		String sessionToken = auth.getSessionToken(authBody);
		Assert.assertEquals("gc5YcosgAv0KUNoiN+oitwb63dX/c0wijhVjK2fW9jdfnH9Tsh+tYE9k42hj9dCB", sessionToken);
	}
	
	
	@Test
	public void getRealToken(){
		String sessionB = sessionBody.replaceAll("\\\\", "");
		Assert.assertEquals("M0zmPRJdr7GGKt60cLbGSx9M0HyfI9P61DX/sqKk1RUuWv/2Y/xgBrwgPKcRIOyO", sessionB);
	}

}
