package jd2m.util;

/**
 *
 * @author muhtaris
 */
public final class Ref<T> {

    private T _referee;

    private  Ref (final T referee) {
        _referee = referee;
    }
    private Ref () {
    }

    public T Deref () {
        return _referee;
    }

    public void Assign (final T newReferee) {
        _referee = newReferee;
    }

    public static <T> Ref<T> CreateRef (final T referee) {
        return new Ref<T>(referee);
    }
}
