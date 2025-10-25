#if !defined(MW_ENABLE_BOOST_WARNINGS)
#  if defined(__GNUC__)
#    pragma GCC system_header
#  elif defined(_MSC_VER)
     /* The matching "pop" is in header_suffix.h */
#    pragma warning(push, 1)
       /*
        * These suppressions are only here because of the apparent compiler bug:
        * g782945
        *
        * If the bug didn't exist, these warnings would be suppressed solely by
        * the warning(push) above.  The state of the warnings prior to the
        * warning(push) above will be restored by the warning(pop) in the suffix
        * header.
        *
        * Other suppressions may need to be added as more Boost headers are used
        * and other bogus warnings are uncovered.
        */
#      pragma warning(disable: 4003)
#      pragma warning(disable: 4141)
#      pragma warning(disable: 4244)
#      pragma warning(disable: 4702)
#      pragma warning(disable: 4714)
       /* End g782945 workarounds. */
#  endif
#endif

#if !defined(MW_DISABLE_BOOST_DEFAULT_VISIBILITY)
#  if defined(__GNUC__)
#    if (__GNUC__ == 4 && __GNUC_MINOR__ >= 1) || (__GNUC__ > 4)
       /* The matching "pop" is in header_suffix.h */
#      pragma GCC visibility push (default)
#    endif
#  endif
#endif

#ifndef BOOST_CORE_TYPEINFO_HPP_INCLUDED
#define BOOST_CORE_TYPEINFO_HPP_INCLUDED

// MS compatible compilers support #pragma once

#if defined(_MSC_VER) && (_MSC_VER >= 1020)
# pragma once
#endif

//  core::typeinfo, BOOST_CORE_TYPEID
//
//  Copyright 2007, 2014 Peter Dimov
//
//  Distributed under the Boost Software License, Version 1.0.
//  See accompanying file LICENSE_1_0.txt or copy at
//  http://www.boost.org/LICENSE_1_0.txt)

#include <boost/config.hpp>

#if defined( BOOST_NO_TYPEID )

#include <boost/current_function.hpp>
#include <functional>
#include <cstring>

namespace mwboost {} namespace boost = mwboost; namespace mwboost
{

namespace core
{

class typeinfo
{
private:

    typeinfo( typeinfo const& );
    typeinfo& operator=( typeinfo const& );

    char const * name_;
    void (*lib_id_)();

public:

    typeinfo( char const * name, void (*lib_id)() ): name_( name ), lib_id_( lib_id )
    {
    }

    bool operator==( typeinfo const& rhs ) const
    {
#if ( defined(_WIN32) || defined(__CYGWIN__) ) && ( defined(__GNUC__) || defined(__clang__) ) && !defined(BOOST_DISABLE_CURRENT_FUNCTION)

        return lib_id_ == rhs.lib_id_? this == &rhs: std::strcmp( name_, rhs.name_ ) == 0;

#else

        return this == &rhs;

#endif
    }

    bool operator!=( typeinfo const& rhs ) const
    {
        return !( *this == rhs );
    }

    bool before( typeinfo const& rhs ) const
    {
#if ( defined(_WIN32) || defined(__CYGWIN__) ) && ( defined(__GNUC__) || defined(__clang__) ) && !defined(BOOST_DISABLE_CURRENT_FUNCTION)

        return lib_id_ == rhs.lib_id_? std::less< typeinfo const* >()( this, &rhs ): std::strcmp( name_, rhs.name_ ) < 0;

#else

        return std::less< typeinfo const* >()( this, &rhs );

#endif
    }

    char const* name() const
    {
        return name_;
    }
};

inline char const * demangled_name( core::typeinfo const & ti )
{
    return ti.name();
}

} // namespace core

namespace detail
{

template<class T> struct BOOST_SYMBOL_VISIBLE core_typeid_
{
    static mwboost::core::typeinfo ti_;

    static char const * name()
    {
        return BOOST_CURRENT_FUNCTION;
    }
};

BOOST_SYMBOL_VISIBLE inline void core_typeid_lib_id()
{
}

template<class T> mwboost::core::typeinfo core_typeid_< T >::ti_( core_typeid_< T >::name(), &core_typeid_lib_id );

template<class T> struct core_typeid_< T & >: core_typeid_< T >
{
};

template<class T> struct core_typeid_< T const >: core_typeid_< T >
{
};

template<class T> struct core_typeid_< T volatile >: core_typeid_< T >
{
};

template<class T> struct core_typeid_< T const volatile >: core_typeid_< T >
{
};

} // namespace detail

} // namespace mwboost

#define BOOST_CORE_TYPEID(T) (mwboost::detail::core_typeid_<T>::ti_)

#else

#include <boost/core/demangle.hpp>
#include <typeinfo>

namespace mwboost {} namespace boost = mwboost; namespace mwboost
{

namespace core
{

#if defined( BOOST_NO_STD_TYPEINFO )

typedef ::type_info typeinfo;

#else

typedef std::type_info typeinfo;

#endif

inline std::string demangled_name( core::typeinfo const & ti )
{
    return core::demangle( ti.name() );
}

} // namespace core

} // namespace mwboost

#define BOOST_CORE_TYPEID(T) typeid(T)

#endif

#endif  // #ifndef BOOST_CORE_TYPEINFO_HPP_INCLUDED

#if !defined(MW_DISABLE_BOOST_DEFAULT_VISIBILITY)
#  if defined(__GNUC__)
#    if (__GNUC__ == 4 && __GNUC_MINOR__ >= 1) || (__GNUC__ > 4)
       /* The matching "push" is in header_prefix.h */
#      pragma GCC visibility pop
#    endif
#  endif
#endif

#if !defined(MW_ENABLE_BOOST_WARNINGS)
#  if defined(_MSC_VER)
     /* The matching "push" is in header_prefix.h */
#    pragma warning(pop)
#  endif
#endif
