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

// Boost.Signals2 library

// Copyright Frank Mori Hess 2007-2009.
// Copyright Timmo Stange 2007.
// Copyright Douglas Gregor 2001-2004. Use, modification and
// distribution is subject to the Boost Software License, Version
// 1.0. (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)

// For more information, see http://www.boost.org

#ifndef BOOST_SIGNALS2_PREPROCESSED_SLOT_HPP
#define BOOST_SIGNALS2_PREPROCESSED_SLOT_HPP

#include <boost/preprocessor/repetition.hpp>
#include <boost/signals2/detail/preprocessed_arg_type.hpp>
#include <boost/type_traits/function_traits.hpp>

#ifndef BOOST_SIGNALS2_SLOT_MAX_BINDING_ARGS
#define BOOST_SIGNALS2_SLOT_MAX_BINDING_ARGS 10
#endif


// template<typename Func, typename BindArgT0, typename BindArgT1, ..., typename BindArgTN-1> slotN(...
#define BOOST_SIGNALS2_SLOT_N_BINDING_CONSTRUCTOR(z, n, data) \
  template<typename Func, BOOST_SIGNALS2_PREFIXED_ARGS_TEMPLATE_DECL(n, BindArg)> \
  BOOST_SIGNALS2_SLOT_CLASS_NAME(BOOST_SIGNALS2_NUM_ARGS)( \
    const Func &func, BOOST_SIGNALS2_PREFIXED_FULL_REF_ARGS(n, const BindArg)) \
  { \
    init_slot_function(mwboost::bind(func, BOOST_SIGNALS2_SIGNATURE_ARG_NAMES(n))); \
  }
#define BOOST_SIGNALS2_SLOT_N_BINDING_CONSTRUCTORS \
  BOOST_PP_REPEAT_FROM_TO(1, BOOST_SIGNALS2_SLOT_MAX_BINDING_ARGS, BOOST_SIGNALS2_SLOT_N_BINDING_CONSTRUCTOR, ~)


#define BOOST_PP_ITERATION_LIMITS (0, BOOST_PP_INC(BOOST_SIGNALS2_MAX_ARGS))
#define BOOST_PP_FILENAME_1 <boost/signals2/detail/slot_template.hpp>
#include BOOST_PP_ITERATE()

#undef BOOST_SIGNALS2_SLOT_N_BINDING_CONSTRUCTOR
#undef BOOST_SIGNALS2_SLOT_N_BINDING_CONSTRUCTORS

namespace mwboost {} namespace boost = mwboost; namespace mwboost
{
  namespace signals2
  {
    template<typename Signature,
      typename SlotFunction = mwboost::function<Signature> >
    class slot: public detail::slotN<function_traits<Signature>::arity,
      Signature, SlotFunction>::type
    {
    private:
      typedef typename detail::slotN<mwboost::function_traits<Signature>::arity,
        Signature, SlotFunction>::type base_type;
    public:
      template<typename F>
      slot(const F& f): base_type(f)
      {}
      // bind syntactic sugar
// template<typename F, typename BindArgT0, typename BindArgT1, ..., typename BindArgTn-1> slot(...
#define BOOST_SIGNALS2_SLOT_BINDING_CONSTRUCTOR(z, n, data) \
  template<typename Func, BOOST_SIGNALS2_PREFIXED_ARGS_TEMPLATE_DECL(n, BindArg)> \
    slot(const Func &func, BOOST_SIGNALS2_PREFIXED_FULL_REF_ARGS(n, const BindArg)): \
    base_type(func, BOOST_SIGNALS2_SIGNATURE_ARG_NAMES(n)) \
  {}
      BOOST_PP_REPEAT_FROM_TO(1, BOOST_SIGNALS2_SLOT_MAX_BINDING_ARGS, BOOST_SIGNALS2_SLOT_BINDING_CONSTRUCTOR, ~)
#undef BOOST_SIGNALS2_SLOT_BINDING_CONSTRUCTOR
    };
  } // namespace signals2
}

#endif // BOOST_SIGNALS2_PREPROCESSED_SLOT_HPP

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
