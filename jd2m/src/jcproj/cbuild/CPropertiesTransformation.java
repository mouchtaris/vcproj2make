package jcproj.cbuild;

/**
 *
 * @author muhtaris
 */
public interface CPropertiesTransformation {
	CProperties	ApplyTo				(CProperties props);
	boolean		IsApplicableTo		(CProperties props);
	CProperties	ApplyIfApplicableTo	(CProperties props);
}
