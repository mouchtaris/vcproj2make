package jcproj.vcxproj.xml;

import java.util.Collections;
import java.util.Iterator;
import java.util.LinkedList;
import java.util.List;
import java.util.Objects;

/**
 *
 * @date Sunday 7th of August 2011
 * @author amalia
 */
public final class Group<T> implements Conditioned, Iterable<T> {
    
    ///////////////////////////////////////////////////////
    
    public void Add (final T o) {
        assert type.isInstance(o);
        final boolean added = items.add(o);
        assert added;
    }

    ///////////////////////////////////////////////////////
    
    @Override
    public Iterator<T> iterator () {
        return Collections.unmodifiableList(items).iterator();
    }
    
    ///////////////////////////////////////////////////////
    
    public String GetLabel () {
        return label;
    }
    
    ///////////////////////////////////////////////////////
    
    public Class<? extends T> GetType () {
        return type;
    }
    
    ///////////////////////////////////////////////////////
    
    
    @Override
    public String GetCondition () {
        return condition;
    }
    
    ///////////////////////////////////////////////////////
    
    public boolean Equals (final Group<?> other) {
        boolean d00, d01, d02;
        return
                (d00 = Objects.equals(type, other.type))
            &&  (d00 = Objects.equals(label, other.label))
            &&  (d00 = Objects.equals(condition, other.condition))
            ;
    }
    
    @Override
    public boolean equals (final Object o) {
        boolean result = o != null && Objects.equals(getClass(), o.getClass());
        
        if (result)
            result = Equals((Group<?>) o);
        
        return result;
    }

    @Override
    public int hashCode() {
        int hash = 5;
        hash = 97 * hash + Objects.hashCode(type);
        hash = 97 * hash + Objects.hashCode(label);
        hash = 97 * hash + Objects.hashCode(condition);
        return hash;
    }
            
    ///////////////////////////////////////////////////////
    
    public Group (final Class<? extends T> type, final String label, final String condition) {
        this.type = type;
        this.label = label;
        this.condition = condition;
    }
    
    ///////////////////////////////////////////////////////
    
    ///////////////////////////////////////////////////////
    // Private
    
    ///////////////////////////////////////////////////////
    // State
    private final Class<? extends T>    type;
    private final String                label;
    private final String                condition;
    private final List<T>               items   = new LinkedList<>();

} // class Group
