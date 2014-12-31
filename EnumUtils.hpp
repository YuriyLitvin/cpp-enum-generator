#ifndef JDSOFT_ENUMGENERATOR_ENUMUTILS_HPP
#define JDSOFT_ENUMGENERATOR_ENUMUTILS_HPP

#include <string.h>
#include <stdlib.h>


namespace NS_JDSoft
{
namespace NS_EnumGenerator
{
    typedef int(*_DTpFCompare)(const void *, const void *);

    inline int StringFindLinear(const char * const * array, int arraySize, const char * valueFind)
    {
        for (int i = 0;i < arraySize;i++)
        {
            if (strcmp(array[i], valueFind) == 0)
                return i;
        }
        return -1;
    }

    template <class T>
    inline int ValueFindLinear(const T * array, int arraySize, const T & valueFind)
    {
        for (int i = 0;i < arraySize;i++)
        {
            if (array[i] == valueFind)
                return i;
        }
        return -1;
    }

    inline int StringCompare (const void * find, const void * cur)
    {
        return strcmp((const char *)find, *(const char **)cur);
    }

    inline int StringFindBinary(const char * const * array, int arraySize, const char * valueFind)
    {
        void *p = bsearch(valueFind, array, arraySize, sizeof(const char *), reinterpret_cast<_DTpFCompare>(&StringCompare));
        return (p) ? (static_cast<const char * const *>(p) - array) : -1;
    }

    template <class T>
    struct _DSValueSorted
    {
        T value;
        int index;
    };

    template <class T>
    inline int ValueCompare (const void * pKey, const void * pElem)
    {
        const T * key = static_cast<const T *>(pKey);
        const _DSValueSorted<T> * elem = static_cast<const _DSValueSorted<T> *>(pElem);
        return (*key < elem->value) ? -1 : ((*key == elem->value) ? 0 : 1);
    }

    template <class T>
    inline int ValueFindBinary(const _DSValueSorted<T> * array, int arraySize, const T & valueFind)
    {
        void *p = bsearch(&valueFind, array, arraySize, sizeof(_DSValueSorted<T>), reinterpret_cast<_DTpFCompare>(&ValueCompare<T>));
        return (p) ? (static_cast<const _DSValueSorted<T> *>(p)->index) : -1;
    }

}
}


#endif // JDSOFT_ENUMGENERATOR_ENUMUTILS_HPP
