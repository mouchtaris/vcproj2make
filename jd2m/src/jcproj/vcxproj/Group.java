package jcproj.vcxproj;

import java.util.LinkedList;
import java.util.List;
import java.util.Objects;

/**
 *
 * @date Sunday 7th of August 2011
 * @author amalia
 */
public final class Group<T> implements Conditioned {
    
    ///////////////////////////////////////////////////////
    
    public void Add (final T o) {
        assert type.isInstance(o);
        final boolean added = items.add(o);
        assert added;
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
    
    @Override
    public boolean equals (final Object o) {
        boolean result = o != null && Objects.equals(getClass(), o.getClass());
        
        if (result) {
            final Group<?> other = (Group<?>) o;
            
            result =       Objects.equals(type, other.type)
                        && Objects.equals(label, other.label)
                        && Objects.equals(condition, other.condition);
        }
        
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
