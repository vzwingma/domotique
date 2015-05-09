package com.terrier.domotique.interfaces.box.reseaux;

import java.util.Calendar;

/**
 * Résultat de périphérique
 * @author vzwingma
 *
 */
public class PeripheriqueReseau {

	
	private boolean active;
	
	private String id;
	
	private int last_time_reachable;
	
	private boolean persistent;
	
	private String vendor_name;
	
	private String host_type;
	
	private boolean reachable;
	
	private int last_activity;
	
	private boolean primary_name_manual;
	
	private String primary_name;

	/**
	 * @return the active
	 */
	public boolean isActive() {
		return active;
	}

	/**
	 * @param active the active to set
	 */
	public void setActive(boolean active) {
		this.active = active;
	}

	/**
	 * @return the id
	 */
	public String getId() {
		return id;
	}

	/**
	 * @param id the id to set
	 */
	public void setId(String id) {
		this.id = id;
	}

	/**
	 * @return the last_time_reachable
	 */
	public Calendar getLastTimeReachable() {
		Calendar c = Calendar.getInstance();
		c.setTimeInMillis((long)last_time_reachable * 1000);
		return c;
	}

	/**
	 * @param last_time_reachable the last_time_reachable to set
	 */
	public void setLast_time_reachable(int last_time_reachable) {
		this.last_time_reachable = last_time_reachable;
	}

	/**
	 * @return the persistent
	 */
	public boolean isPersistent() {
		return persistent;
	}

	/**
	 * @param persistent the persistent to set
	 */
	public void setPersistent(boolean persistent) {
		this.persistent = persistent;
	}

	/**
	 * @return the vendor_name
	 */
	public String getVendor_name() {
		return vendor_name;
	}

	/**
	 * @param vendorName the vendor_name to set
	 */
	public void setVendor_name(String vendorName) {
		this.vendor_name = vendorName;
	}

	/**
	 * @return the host_type
	 */
	public HostTypeEnum getHostType() {
		return HostTypeEnum.getEnumOf(host_type);
	}

	/**
	 * @param hostType the host_type to set
	 */
	public void setHost_type(String hostType) {
		this.host_type = hostType;
	}

	/**
	 * @return the reachable
	 */
	public boolean isReachable() {
		return reachable;
	}

	/**
	 * @param reachable the reachable to set
	 */
	public void setReachable(boolean reachable) {
		this.reachable = reachable;
	}

	/**
	 * @return the last_activity
	 */
	public Calendar getLastActivity() {
		Calendar c = Calendar.getInstance();
		c.setTimeInMillis((long)last_activity * 1000);
		return c;
	}

	/**
	 * @param last_activity the last_activity to set
	 */
	public void setLast_activity(int last_activity) {
		this.last_activity = last_activity;
	}

	/**
	 * @return the primary_name_manual
	 */
	public boolean isPrimary_name_manual() {
		return primary_name_manual;
	}

	/**
	 * @param primary_name_manual the primary_name_manual to set
	 */
	public void setPrimary_name_manual(boolean primary_name_manual) {
		this.primary_name_manual = primary_name_manual;
	}

	/**
	 * @return the primary_name
	 */
	public String getPrimaryName() {
		return primary_name;
	}

	/**
	 * @param primary_name the primary_name to set
	 */
	public void setPrimary_name(String primary_name) {
		this.primary_name = primary_name;
	}
}
