package com.terrier.domotique.interfaces.box;

import org.junit.Assert;
import org.junit.Test;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.terrier.domotique.interfaces.box.impl.HmacSha1Signature;

public class TestHmacSha1Signature {


	private static final Logger LOG = LoggerFactory.getLogger(TestHmacSha1Signature.class);

	
	@Test
	public void testSignature() throws Exception{
		String hmac = HmacSha1Signature.calculateRFC2104HMAC("data", "key");

		LOG.info(hmac);
		Assert.assertEquals(hmac, "104152c5bfdca07bc633eebd46199f0255c9f49d");
	}
}
