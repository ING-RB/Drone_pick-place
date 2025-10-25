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
// boost/format/exceptions.hpp 
// ----------------------------------------------------------------------------

//  Copyright Samuel Krempp 2003.
//
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)
//
//
//  See http://www.boost.org/libs/format/ for library home page

// ----------------------------------------------------------------------------

#ifndef BOOST_FORMAT_EXCEPTIONS_HPP
#define BOOST_FORMAT_EXCEPTIONS_HPP


#include <boost/config.hpp>
#include <stdexcept>


namespace mwboost {} namespace boost = mwboost; namespace mwboost {

    namespace io {

// **** exceptions -----------------------------------------------

        class format_error : public std::exception
        {
        public:
            format_error()  {}
            virtual const char *what() const BOOST_NOEXCEPT_OR_NOTHROW BOOST_OVERRIDE {
                return "mwboost::format_error: "
                    "format generic failure";
            }
        };

        class bad_format_string : public format_error
        {
            std::size_t pos_, next_;
        public:
            bad_format_string(std::size_t pos, std::size_t size) 
                : pos_(pos), next_(size) {}
            std::size_t get_pos() const { return pos_; }
            std::size_t get_next() const { return next_; }
            virtual const char *what() const BOOST_NOEXCEPT_OR_NOTHROW BOOST_OVERRIDE {
                return "mwboost::bad_format_string: format-string is ill-formed";
            }
        };

        class too_few_args : public format_error
        {
            std::size_t cur_, expected_;
        public:
            too_few_args(std::size_t cur, std::size_t expected) 
                : cur_(cur), expected_(expected) {}
            std::size_t get_cur() const { return cur_; }
            std::size_t get_expected() const { return expected_; }
            virtual const char *what() const BOOST_NOEXCEPT_OR_NOTHROW BOOST_OVERRIDE {
                return "mwboost::too_few_args: "
                    "format-string referred to more arguments than were passed";
            }
        };

        class too_many_args : public format_error
        {
            std::size_t cur_, expected_;
        public:
            too_many_args(std::size_t cur, std::size_t expected) 
                : cur_(cur), expected_(expected) {}
            std::size_t get_cur() const { return cur_; }
            std::size_t get_expected() const { return expected_; }
            virtual const char *what() const BOOST_NOEXCEPT_OR_NOTHROW BOOST_OVERRIDE {
                return "mwboost::too_many_args: "
                    "format-string referred to fewer arguments than were passed";
            }
        };


        class  out_of_range : public format_error
        {
            int index_, beg_, end_;    // range is [ beg, end [
        public:
            out_of_range(int index, int beg, int end) 
                : index_(index), beg_(beg), end_(end) {}
            int get_index() const { return index_; }
            int get_beg() const { return beg_; }
            int get_end() const { return end_; }
            virtual const char *what() const BOOST_NOEXCEPT_OR_NOTHROW BOOST_OVERRIDE {
                return "mwboost::out_of_range: "
                    "tried to refer to an argument (or item) number which"
                    " is out of range, according to the format string";
            }
        };


    } // namespace io

} // namespace mwboost


#endif // BOOST_FORMAT_EXCEPTIONS_HPP

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
