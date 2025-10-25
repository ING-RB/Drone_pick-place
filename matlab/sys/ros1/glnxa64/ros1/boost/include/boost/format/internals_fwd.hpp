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

// ----------------------------------------------------------------------------
// internals_fwd.hpp :  forward declarations, for internal headers
// ----------------------------------------------------------------------------

//  Copyright Samuel Krempp 2003. Use, modification, and distribution are
//  subject to the Boost Software License, Version 1.0. (See accompanying
//  file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)

//  See http://www.boost.org/libs/format for library home page

// ----------------------------------------------------------------------------

#ifndef BOOST_FORMAT_INTERNAL_FWD_HPP
#define BOOST_FORMAT_INTERNAL_FWD_HPP

#include <boost/format/format_fwd.hpp>
#include <boost/config.hpp>


namespace mwboost {} namespace boost = mwboost; namespace mwboost {
namespace io {

namespace detail {
  template<class Ch, class Tr> struct stream_format_state;
    template<class Ch, class Tr, class Alloc> struct format_item;


  // these functions were intended as methods, 
  // but MSVC have problems with template member functions :
  // defined in format_implementation.hpp :
    template<class Ch, class Tr, class Alloc, class T> 
    basic_format<Ch, Tr, Alloc>&  
    modify_item_body (basic_format<Ch, Tr, Alloc>& self, 
                      int itemN, T manipulator);

    template<class Ch, class Tr, class Alloc, class T> 
    basic_format<Ch, Tr, Alloc>&  
    bind_arg_body (basic_format<Ch, Tr, Alloc>& self,
                   int argN, const T& val);

    // in internals.hpp :
    template<class Ch, class Tr, class T> 
    void apply_manip_body (stream_format_state<Ch, Tr>& self,
                           T manipulator);

    // argument feeding (defined in feed_args.hpp ) :
    template<class Ch, class Tr, class Alloc, class T> 
    void distribute (basic_format<Ch,Tr, Alloc>& self, T x);

    template<class Ch, class Tr, class Alloc, class T> 
    basic_format<Ch, Tr, Alloc>& 
    feed (basic_format<Ch,Tr, Alloc>& self, T x);

    template<class Ch, class Tr, class Alloc, class T> 
    basic_format<Ch, Tr, Alloc>& 
    feed_impl (basic_format<Ch,Tr, Alloc>& self, T x);
 
} // namespace detail

} // namespace io
} // namespace mwboost


#endif //  BOOST_FORMAT_INTERNAL_FWD_HPP

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
