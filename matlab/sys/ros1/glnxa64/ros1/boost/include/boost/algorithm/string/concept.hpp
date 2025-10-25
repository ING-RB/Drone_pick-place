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

//  Boost string_algo library concept.hpp header file  ---------------------------//

//  Copyright Pavol Droba 2002-2003.
//
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

//  See http://www.boost.org/ for updates, documentation, and revision history.

#ifndef BOOST_STRING_CONCEPT_HPP
#define BOOST_STRING_CONCEPT_HPP

#include <boost/concept_check.hpp>
#include <boost/range/iterator_range_core.hpp>
#include <boost/range/begin.hpp>
#include <boost/range/end.hpp>

/*! \file 
    Defines concepts used in string_algo library
*/

namespace mwboost {} namespace boost = mwboost; namespace mwboost {
    namespace algorithm {

        //! Finder concept
        /*!
            Defines the Finder concept. Finder is a functor which selects
            an arbitrary part of a string. Search is performed on
            the range specified by starting and ending iterators.

            Result of the find operation must be convertible to iterator_range.
        */
        template<typename FinderT, typename IteratorT>
        struct FinderConcept
        {
        private:
            typedef iterator_range<IteratorT> range;
        public:
            void constraints()
            {
                // Operation
                r=(*pF)(i,i);
            }
        private:
            range r;
            IteratorT i;
            FinderT* pF;    
        }; // Finder_concept

        
        //! Formatter concept
        /*!
            Defines the Formatter concept. Formatter is a functor, which
            takes a result from a finder operation and transforms it
            in a specific way.

            Result must be a container supported by container_traits, 
            or a reference to it.
        */
        template<typename FormatterT, typename FinderT, typename IteratorT>
        struct FormatterConcept
        {
        public:
            void constraints()
            {
                // Operation
                ::mwboost::begin((*pFo)( (*pF)(i,i) ));
                ::mwboost::end((*pFo)( (*pF)(i,i) ));
            }
        private:
            IteratorT i;
            FinderT* pF;
            FormatterT *pFo;
        }; // FormatterConcept;

    } // namespace algorithm
} // namespace mwboost




#endif  // BOOST_STRING_CONCEPT_HPP

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
