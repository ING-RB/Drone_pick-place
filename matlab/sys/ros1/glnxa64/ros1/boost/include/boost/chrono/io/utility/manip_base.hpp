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

//  boost/chrono/utility/manip_base.hpp  ------------------------------------------------------------//

//  Copyright 2011 Vicente J. Botet Escriba

//  Distributed under the Boost Software License, Version 1.0. (See accompanying
//  file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)

//  See http://www.boost.org/libs/chrono for documentation.

#ifndef BOOST_CHRONO_UTILITY_MANIP_BASE_PTR_HPP
#define BOOST_CHRONO_UTILITY_MANIP_BASE_PTR_HPP

#include <ios>

/**
 *

 */

namespace mwboost {} namespace boost = mwboost; namespace mwboost
{
  namespace chrono
  {

    /**
     * manip is a manipulator mixin class following the CRTP.
     * @tparam Final the derived from manip and final type
     *
     * @Example
     * @code

    class mendl: public manip<mendl>
    {
    public:
      explicit mendl(size_t how_many) :
        count(how_many) {}
      template <typename out_stream>
      void operator()(out_stream &out) const
      {
        for (size_t line = 0; line < count; ++line)
        {
          out.put(out.widen('\n'));
        }
        out.flush();
      }
    private:
      size_t count;
    };

     * @codeend
     */
    template <typename Final>
    class manip
    {
    public:
      /**
       *
       * @param ios the io stream or ios_base.
       * @Effects calls to the manipulator final functor.
       */
      //template <typename out_stream>
      void operator()(std::ios_base &ios) const
      {
        (*static_cast<const Final *> (this))(ios);
      }
    };

    /**
     * @c manip stream inserter
     * @param out the io stream or ios_base.
     * @param op the manipulator instance.
     * @Effects if @c out is good calls to the manipulator functor @op.
     * @return @c out
     */
    template <typename out_stream, typename manip_type>
    out_stream &operator<<(out_stream &out, const manip<manip_type> &op)
    {
      if (out.good())
        op(out);
      return out;
    }

    /**
     * @c manip stream extractor
     * @param in the io stream or ios_base.
     * @param op  the manipulator instance.
     * @Effects if @c in is good calls to the manipulator functor @op.
     * @return @c in
     */
    template <typename in_stream, typename manip_type>
    in_stream &operator>>(in_stream &in, const manip<manip_type> &op)
    {
      if (in.good())
        op(in);
      return in;
    }

  } // namespace chrono
} // namespace mwboost

#endif // header

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
