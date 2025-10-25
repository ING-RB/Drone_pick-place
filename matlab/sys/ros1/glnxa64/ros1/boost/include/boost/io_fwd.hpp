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

/*
Copyright 2002 Daryle Walker

Distributed under the Boost Software License, Version 1.0.
(http://www.boost.org/LICENSE_1_0.txt)
*/
#ifndef BOOST_IO_FWD_HPP
#define BOOST_IO_FWD_HPP

#include <iosfwd>

namespace mwboost {} namespace boost = mwboost; namespace mwboost {
namespace io {

class ios_flags_saver;
class ios_precision_saver;
class ios_width_saver;
class ios_base_all_saver;

template<class Ch, class Tr = std::char_traits<Ch> >
class basic_ios_iostate_saver;

template<class Ch, class Tr = std::char_traits<Ch> >
class basic_ios_exception_saver;

template<class Ch, class Tr = std::char_traits<Ch> >
class basic_ios_tie_saver;

template<class Ch, class Tr = std::char_traits<Ch> >
class basic_ios_rdbuf_saver;

template<class Ch, class Tr = std::char_traits<Ch> >
class basic_ios_fill_saver;

template<class Ch, class Tr = std::char_traits<Ch> >
class basic_ios_locale_saver;

template<class Ch, class Tr = std::char_traits<Ch> >
class basic_ios_all_saver;

typedef basic_ios_iostate_saver<char>      ios_iostate_saver;
typedef basic_ios_iostate_saver<wchar_t>   wios_iostate_saver;
typedef basic_ios_exception_saver<char>    ios_exception_saver;
typedef basic_ios_exception_saver<wchar_t> wios_exception_saver;
typedef basic_ios_tie_saver<char>          ios_tie_saver;
typedef basic_ios_tie_saver<wchar_t>       wios_tie_saver;
typedef basic_ios_rdbuf_saver<char>        ios_rdbuf_saver;
typedef basic_ios_rdbuf_saver<wchar_t>     wios_rdbuf_saver;
typedef basic_ios_fill_saver<char>         ios_fill_saver;
typedef basic_ios_fill_saver<wchar_t>      wios_fill_saver;
typedef basic_ios_locale_saver<char>       ios_locale_saver;
typedef basic_ios_locale_saver<wchar_t>    wios_locale_saver;
typedef basic_ios_all_saver<char>          ios_all_saver;
typedef basic_ios_all_saver<wchar_t>       wios_all_saver;

class ios_iword_saver;
class ios_pword_saver;
class ios_all_word_saver;

} /* io */
} /* boost */

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
