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

// Copyright (C) 2001-2003
// William E. Kempf
// Copyright (C) 2007-9 Anthony Williams
// (C) Copyright 2011-2012 Vicente J. Botet Escriba
//
//  Distributed under the Boost Software License, Version 1.0. (See accompanying
//  file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)

#ifndef BOOST_THREAD_EXCEPTIONS_PDM070801_H
#define BOOST_THREAD_EXCEPTIONS_PDM070801_H

#include <boost/thread/detail/config.hpp>

//  pdm: Sorry, but this class is used all over the place & I end up
//       with recursive headers if I don't separate it
//  wek: Not sure why recursive headers would cause compilation problems
//       given the include guards, but regardless it makes sense to
//       seperate this out any way.

#include <string>
#include <stdexcept>
#include <boost/system/system_error.hpp>
#include <boost/system/error_code.hpp>


#include <boost/config/abi_prefix.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost
{

#if defined BOOST_THREAD_PROVIDES_INTERRUPTIONS
    class BOOST_SYMBOL_VISIBLE thread_interrupted
    {};
#endif

    class BOOST_SYMBOL_VISIBLE thread_exception:
        public system::system_error
        //public std::exception
    {
          typedef system::system_error base_type;
    public:
        thread_exception()
          : base_type(0,system::generic_category())
        {}

        thread_exception(int sys_error_code)
          : base_type(sys_error_code, system::generic_category())
        {}

        thread_exception( int ev, const char * what_arg )
        : base_type(system::error_code(ev, system::generic_category()), what_arg)
        {
        }
        thread_exception( int ev, const std::string & what_arg )
        : base_type(system::error_code(ev, system::generic_category()), what_arg)
        {
        }

        ~thread_exception() BOOST_NOEXCEPT_OR_NOTHROW
        {}


        int native_error() const
        {
            return code().value();
        }

    };

    class BOOST_SYMBOL_VISIBLE condition_error:
        public system::system_error
        //public std::exception
    {
          typedef system::system_error base_type;
    public:
          condition_error()
          : base_type(system::error_code(0, system::generic_category()), "Condition error")
          {}
          condition_error( int ev )
          : base_type(system::error_code(ev, system::generic_category()), "Condition error")
          {
          }
          condition_error( int ev, const char * what_arg )
          : base_type(system::error_code(ev, system::generic_category()), what_arg)
          {
          }
          condition_error( int ev, const std::string & what_arg )
          : base_type(system::error_code(ev, system::generic_category()), what_arg)
          {
          }
    };


    class BOOST_SYMBOL_VISIBLE lock_error:
        public thread_exception
    {
          typedef thread_exception base_type;
    public:
        lock_error()
        : base_type(0, "mwboost::lock_error")
        {}

        lock_error( int ev )
        : base_type(ev, "mwboost::lock_error")
        {
        }
        lock_error( int ev, const char * what_arg )
        : base_type(ev, what_arg)
        {
        }
        lock_error( int ev, const std::string & what_arg )
        : base_type(ev, what_arg)
        {
        }

        ~lock_error() BOOST_NOEXCEPT_OR_NOTHROW
        {}

    };

    class BOOST_SYMBOL_VISIBLE thread_resource_error:
        public thread_exception
    {
          typedef thread_exception base_type;
    public:
          thread_resource_error()
          : base_type(static_cast<int>(system::errc::resource_unavailable_try_again), "mwboost::thread_resource_error")
          {}

          thread_resource_error( int ev )
          : base_type(ev, "mwboost::thread_resource_error")
          {
          }
          thread_resource_error( int ev, const char * what_arg )
          : base_type(ev, what_arg)
          {
          }
          thread_resource_error( int ev, const std::string & what_arg )
          : base_type(ev, what_arg)
          {
          }


        ~thread_resource_error() BOOST_NOEXCEPT_OR_NOTHROW
        {}

    };

    class BOOST_SYMBOL_VISIBLE unsupported_thread_option:
        public thread_exception
    {
          typedef thread_exception base_type;
    public:
          unsupported_thread_option()
          : base_type(static_cast<int>(system::errc::invalid_argument), "mwboost::unsupported_thread_option")
          {}

          unsupported_thread_option( int ev )
          : base_type(ev, "mwboost::unsupported_thread_option")
          {
          }
          unsupported_thread_option( int ev, const char * what_arg )
          : base_type(ev, what_arg)
          {
          }
          unsupported_thread_option( int ev, const std::string & what_arg )
          : base_type(ev, what_arg)
          {
          }

    };

    class BOOST_SYMBOL_VISIBLE invalid_thread_argument:
        public thread_exception
    {
          typedef thread_exception base_type;
    public:
        invalid_thread_argument()
        : base_type(static_cast<int>(system::errc::invalid_argument), "mwboost::invalid_thread_argument")
        {}

        invalid_thread_argument( int ev )
        : base_type(ev, "mwboost::invalid_thread_argument")
        {
        }
        invalid_thread_argument( int ev, const char * what_arg )
        : base_type(ev, what_arg)
        {
        }
        invalid_thread_argument( int ev, const std::string & what_arg )
        : base_type(ev, what_arg)
        {
        }

    };

    class BOOST_SYMBOL_VISIBLE thread_permission_error:
        public thread_exception
    {
          typedef thread_exception base_type;
    public:
          thread_permission_error()
          : base_type(static_cast<int>(system::errc::permission_denied), "mwboost::thread_permission_error")
          {}

          thread_permission_error( int ev )
          : base_type(ev, "mwboost::thread_permission_error")
          {
          }
          thread_permission_error( int ev, const char * what_arg )
          : base_type(ev, what_arg)
          {
          }
          thread_permission_error( int ev, const std::string & what_arg )
          : base_type(ev, what_arg)
          {
          }

    };

} // namespace mwboost

#include <boost/config/abi_suffix.hpp>

#endif

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
