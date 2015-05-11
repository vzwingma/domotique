/**
 * 
 */
package com.terrier.domotique.interfaces.tv.impl;

import java.util.ArrayList;
import java.util.List;

import org.apache.camel.Exchange;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Splitter de la commande de chaine
 * @author vzwingma
 *
 */
public class ChannelSplitter  {


	// Logs
	private static final Logger LOG = LoggerFactory.getLogger(ChannelSplitter.class);

	/* (non-Javadoc)
	 * @see org.apache.camel.processor.aggregate.AggregationStrategy#aggregate(org.apache.camel.Exchange, org.apache.camel.Exchange)
	 */
	public List<String> split(Exchange exchange) {

		if(exchange == null){
			return null;
		}
		String chaine = (String)exchange.getIn().getHeader("chaine");
		LOG.info("[INTERFACE TV]	Chaine à afficher : [{}]" , chaine);
		if(chaine != null){
			List<String> listeChiffres = new ArrayList<>();
			for(int i = 0; i < chaine.length(); i++){
				listeChiffres.add(chaine.substring(i, i+1));
			}
			LOG.debug("[INTERFACE TV]	Commandes touches : {}" , listeChiffres);
			return listeChiffres;
		}
		return null;
	}



}
