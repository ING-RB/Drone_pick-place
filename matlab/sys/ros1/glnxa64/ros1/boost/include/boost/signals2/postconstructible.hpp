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

// DEPRECATED in favor of adl_postconstruct with deconstruct<T>().
// A simple framework for creating objects with postconstructors.
// The objects must inherit from mwboost::signals2::postconstructible, and
// have their lifetimes managed by
// mwboost::shared_ptr created with the mwboost::signals2::deconstruct_ptr()
// function.
//
// Copyright Frank Mori Hess 2007-2008.
//
// Use, modification and
// distribution is subject to the Boost Software License, Version
// 1.0. (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)

#ifndef BOOST_SIGNALS2_POSTCONSTRUCTIBLE_HPP
#define BOOST_SIGNALS2_POSTCONSTRUCTIBLE_HPP

namespace mwboost {} namespace boost = mwboost; namespace mwboost
{
  template<typename T> class shared_ptr;

  namespace signals2
  {
    namespace postconstructible_adl_barrier
    {
      class postconstructible;
    }
    namespace detail
    {
      void do_postconstruct(const mwboost::signals2::postconstructible_adl_barrier::postconstructible *ptr);
    } // namespace detail

    namespace postconstructible_adl_barrier
    {
      class postconstructible
      {
      public:
        friend void detail::do_postconstruct(const postconstructible *ptr);
        template<typename T>
          friend void adl_postconstruct(const shared_ptr<T> &, postconstructible *p)
        {
          p->postconstruct();
        }
      protected:
        postconstructible() {}
        virtual ~postconstructible() {}
        virtual void postconstruct() = 0;
      };
    } // namespace postconstructible_adl_barrier
    using postconstructible_adl_barrier::postconstructible;

  }
}

#endif // BOOST_SIGNALS2_POSTCONSTRUCTIBLE_HPP

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
