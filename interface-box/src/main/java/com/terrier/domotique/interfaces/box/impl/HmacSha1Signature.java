package com.terrier.domotique.interfaces.box.impl;

import java.security.InvalidKeyException;
import java.security.NoSuchAlgorithmException;
import java.security.SignatureException;
import java.util.Formatter;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;

/**
 * The <tt>HmacSha1Signature</tt> shows how to calculate 
 * a message authentication code using HMAC-SHA1 algorithm.
 *
 * <pre>
 * % java -version
 * java version "1.6.0_11"
 * % javac HmacSha1Signature.java 
 * % java -ea HmacSha1Signature
 * 104152c5bfdca07bc633eebd46199f0255c9f49d
 * </pre>
 *
 */
public class HmacSha1Signature {
	private static final String HMAC_SHA1_ALGORITHM = "HmacSHA1";

	/**
	 * @param bytes
	 * @return hexa
	 */
	private static String toHexString(byte[] bytes) {
		Formatter formatter = new Formatter();
		
		for (byte b : bytes) {
			formatter.format("%02x", b);
		}

		String hex = formatter.toString();
		formatter.close();
		return hex;
	}

	/**
	 * @param data donnée
	 * @param key clé
	 * @return calcul
	 * @throws SignatureException erreur signature
	 * @throws NoSuchAlgorithmException erreur 
	 * @throws InvalidKeyException erreur
	 */
	public static String calculateRFC2104HMAC(String data, String key)
		throws SignatureException, NoSuchAlgorithmException, InvalidKeyException
	{
		SecretKeySpec signingKey = new SecretKeySpec(key.getBytes(), HMAC_SHA1_ALGORITHM);
		Mac mac = Mac.getInstance(HMAC_SHA1_ALGORITHM);
		mac.init(signingKey);
		return toHexString(mac.doFinal(data.getBytes()));
	}
}