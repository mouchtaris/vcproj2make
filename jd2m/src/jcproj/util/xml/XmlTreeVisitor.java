package jcproj.util.xml;

import java.util.Iterator;
import org.w3c.dom.NamedNodeMap;
import org.w3c.dom.Node;

/**
 *
 * Utilities for parsing common structures of Microsoft Visual Studio XML
 * files.
 * 
 * @date Sunday 7th of August 2011
 * @author amalia
 */
public class XmlTreeVisitor {
    
    ///////////////////////////////////////////////////////
    // Node utilities
    public static String GetPairLeft (final Node node) {
        assert IsPairNode(node);
        
        return node.getAttributes().getNamedItem("left").getNodeValue();
    }
    
    ///////////////////////////////////////////////////////
    
    public static String GetPairRight (final Node node) {
        assert IsPairNode(node);
        
        return node.getAttributes().getNamedItem("right").getNodeValue();
    }
    
    ///////////////////////////////////////////////////////
    
    public static String GetPairValue (final Node node) {
       final String left = GetPairLeft(node);
       final String right = GetPairRight(node);
       
       assert left.equals(right);
       
       return left;
    }
    
    ///////////////////////////////////////////////////////
    // Accessing children fast
    
    public static Node GetChildByName (final Node node, final String childname) {
        for (final Node child : MakeChildrenIterator(node))
            if (child.getNodeType() == Node.ELEMENT_NODE)
                if (child.getNodeName().equals(childname))
                    return child;
        return null;
    }
    
    ///////////////////////////////////////////////////////
    
    public static String GetSingleSubelementValue (final Node node) {
        for (final Node subelement : MakeChildrenIterator(node))
            if (subelement.getNodeType() == Node.TEXT_NODE)
                return subelement.getNodeValue();
        return null;
    }
    
    ///////////////////////////////////////////////////////
    
    public static String GetChildSingleSubelementValue (final Node node, final String childname) {
        return GetSingleSubelementValue(GetChildByName(node, childname));
    }
    
    public static String GetChildIfExistsSingleSubelementValue (final Node node, final String childname) {
        final Node child = GetChildByName(node, childname);
        return child == null? null : GetSingleSubelementValue(child);
    }
    
    ///////////////////////////////////////////////////////
    // Accessing attributes fast
    
    public static String GetAttributeValue (final Node node, final String attributename) {
        return node.getAttributes().getNamedItem(attributename).getNodeValue();
    }
    
    ///////////////////////////////////////////////////////
    
    public static String GetAttributeValueIfExists (final Node node, final String attributename) {
        final Node attribute = node.getAttributes().getNamedItem(attributename);
        return attribute == null? null : attribute.getNodeValue();
    }
    
    ///////////////////////////////////////////////////////
    // Iterator of Node's children
    
    public static Iterable<Node> MakeChildrenIterator (final Node node) {
        return new Iterable<Node>() { @Override public Iterator<Node> iterator() { return new Iterator<Node>() {
                private Node next = node.getFirstChild();

                @Override
                public boolean hasNext()
                    { return next != null; }

                @Override
                public Node next() {
                    final Node current = next;
                    next = next.getNextSibling();
                    return current;
                }

                @Override
                public void remove()
                    { throw new UnsupportedOperationException("Not supported."); }
                
        };}};
    }
    
    ///////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////
    // Private
    private XmlTreeVisitor () 
        { }
    
    ///////////////////////////////////////////////////////
    // Node utils
    private static boolean IsPairNode (final Node node) {
        boolean result = true;
                
        result = result && node.getNodeName().equals("Pair");
        result = result && node.getNodeType() == Node.ELEMENT_NODE;
        
        if (result) {
            final NamedNodeMap  attributes  = node.getAttributes();
            final Node          left        = attributes.getNamedItem("left");
            final Node          right       = attributes.getNamedItem("right");
        
            result = result && left != null;
            result = result && right != null;
            result = result && left.getNodeType() == Node.ATTRIBUTE_NODE;
            result = result && right.getNodeType() == Node.ATTRIBUTE_NODE;
        }
        
        return result;
    }
}
