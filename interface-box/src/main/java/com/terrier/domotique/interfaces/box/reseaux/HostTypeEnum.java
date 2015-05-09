/**
 * 
 */
package com.terrier.domotique.interfaces.box.reseaux;

/**
 * Type de périphérique
 * @author vzwingma
 *
 */
public enum HostTypeEnum {

	
	POSTE_FIXE("workstation"),
	SMARTPHONE("smartphone"),
	TABLETTE("tablet"),
	FREEBOX_PLAYER("freebox_player"),
	CONSOLE("vg_console")
	;
	
	
	private String code;
	
	private HostTypeEnum(String code){
		this.code = code;
	}
	
	/**
	 * @param code code de l'enum
	 * @return l'énum correspondant
	 */
	public static HostTypeEnum getEnumOf(String code){
		for (HostTypeEnum enumType : HostTypeEnum.values()) {
			if(enumType.code.equals(code)){
				return enumType;
			}
		}
		return null;
	}
}
