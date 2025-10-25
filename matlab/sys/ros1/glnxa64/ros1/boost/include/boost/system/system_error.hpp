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

#ifndef BOOST_SYSTEM_SYSTEM_ERROR_HPP
#define BOOST_SYSTEM_SYSTEM_ERROR_HPP

// Copyright Beman Dawes 2006
// Copyright Peter Dimov 2021
// Distributed under the Boost Software License, Version 1.0.
// https://www.boost.org/LICENSE_1_0.txt

#include <boost/system/errc.hpp>
#include <boost/system/detail/error_code.hpp>
#include <string>
#include <stdexcept>
#include <cassert>

namespace mwboost {} namespace boost = mwboost; namespace mwboost
{
namespace system
{

class BOOST_SYMBOL_VISIBLE system_error: public std::runtime_error
{
private:

    error_code code_;

public:

    explicit system_error( error_code const & ec ):
        std::runtime_error( ec.what() ), code_( ec ) {}

    system_error( error_code const & ec, std::string const & prefix ):
        std::runtime_error( prefix + ": " + ec.what() ), code_( ec ) {}

    system_error( error_code const & ec, char const * prefix ):
        std::runtime_error( std::string( prefix ) + ": " + ec.what() ), code_( ec ) {}

    system_error( int ev, error_category const & ecat ):
        std::runtime_error( error_code( ev, ecat ).what() ), code_( ev, ecat ) {}

    system_error( int ev, error_category const & ecat, std::string const & prefix ):
        std::runtime_error( prefix + ": " + error_code( ev, ecat ).what() ), code_( ev, ecat ) {}

    system_error( int ev, error_category const & ecat, char const * prefix ):
        std::runtime_error( std::string( prefix ) + ": " + error_code( ev, ecat ).what() ), code_( ev, ecat ) {}

    error_code code() const BOOST_NOEXCEPT
    {
        return code_;
    }
};

} // namespace system
} // namespace mwboost

#endif // BOOST_SYSTEM_SYSTEM_ERROR_HPP

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
