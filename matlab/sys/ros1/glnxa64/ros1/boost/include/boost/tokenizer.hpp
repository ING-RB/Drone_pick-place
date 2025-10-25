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

// Boost tokenizer.hpp  -----------------------------------------------------//

// (c) Copyright Jeremy Siek and John R. Bandela 2001. 

// Distributed under the Boost Software License, Version 1.0. (See
// accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)

// See http://www.boost.org/libs/tokenizer for documenation

// Revision History:
// 03 Jul 2003   John Bandela
//      Converted to new iterator adapter
// 02 Feb 2002   Jeremy Siek
//      Removed tabs and a little cleanup.

#ifndef BOOST_TOKENIZER_JRB070303_HPP_
#define BOOST_TOKENIZER_JRB070303_HPP_

#include <boost/token_iterator.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost {

  
  //===========================================================================
  // A container-view of a tokenized "sequence"
  template <
    typename TokenizerFunc = char_delimiters_separator<char>, 
    typename Iterator = std::string::const_iterator,
    typename Type = std::string
  >
  class tokenizer {
  private:
    typedef token_iterator_generator<TokenizerFunc,Iterator,Type> TGen;
        
    // It seems that MSVC does not like the unqualified use of iterator,
    // Thus we use iter internally when it is used unqualified and
    // the users of this class will always qualify iterator.     
    typedef typename TGen::type iter;
    
  public:
    
    typedef iter iterator;
    typedef iter const_iterator;
    typedef Type value_type;
    typedef value_type& reference;
    typedef const value_type& const_reference;
    typedef value_type* pointer;
    typedef const pointer const_pointer;
    typedef void size_type;
    typedef void difference_type;

    tokenizer(Iterator first, Iterator last,
              const TokenizerFunc& f = TokenizerFunc()) 
      : first_(first), last_(last), f_(f) { }
        
    template <typename Container>
    tokenizer(const Container& c)
      : first_(c.begin()), last_(c.end()), f_() { }
    
    template <typename Container>
    tokenizer(const Container& c,const TokenizerFunc& f)
      : first_(c.begin()), last_(c.end()), f_(f) { }
    
    void assign(Iterator first, Iterator last){
      first_ = first;
      last_ = last;
    }
    
    void assign(Iterator first, Iterator last, const TokenizerFunc& f){
      assign(first,last);
      f_ = f;
    }
    
    template <typename Container>
    void assign(const Container& c){
      assign(c.begin(),c.end());
    }
    
    
    template <typename Container>
    void assign(const Container& c, const TokenizerFunc& f){
      assign(c.begin(),c.end(),f);
    }
    
    iter begin() const { return iter(f_,first_,last_); }
    iter end() const { return iter(f_,last_,last_); }
        
  private:
    Iterator first_;
    Iterator last_;
    TokenizerFunc f_;
  };


} // namespace mwboost

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
