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

//////////////////////////////////////////////////////////////////////////////
//
// (C) Copyright Ion Gaztanaga 2005-2012. Distributed under the Boost
// Software License, Version 1.0. (See accompanying file
// LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
//
// See http://www.boost.org/libs/interprocess for documentation.
//
//////////////////////////////////////////////////////////////////////////////

#ifndef BOOST_INTERPROCESS_FWD_HPP
#define BOOST_INTERPROCESS_FWD_HPP

#ifndef BOOST_CONFIG_HPP
#  include <boost/config.hpp>
#endif
#ifndef BOOST_CSTDINT_HPP
#  include <boost/cstdint.hpp>
#endif
#
#if defined(BOOST_HAS_PRAGMA_ONCE)
#  pragma once
#endif

#include <boost/interprocess/detail/std_fwd.hpp>

//! \file
//! This header file forward declares the basic interprocess types:
//!   - mwboost::interprocess::offset_ptr;
//!   - mwboost::interprocess::permissions;
//!   - mwboost::interprocess::mapped_region;
//!   - mwboost::interprocess::file_mapping;
//!   - mwboost::interprocess::shared_memory_object;
//!   - mwboost::interprocess::windows_shared_memory;
//!   - mwboost::interprocess::xsi_shared_memory;
//!
//! The following synchronization mechanisms and locks:
//!   - mwboost::interprocess::null_mutex;
//!   - mwboost::interprocess::interprocess_mutex;
//!   - mwboost::interprocess::interprocess_recursive_mutex;
//!   - mwboost::interprocess::interprocess_semaphore;
//!   - mwboost::interprocess::named_mutex;
//!   - mwboost::interprocess::named_recursive_mutex;
//!   - mwboost::interprocess::named_semaphore;
//!   - mwboost::interprocess::interprocess_sharable_mutex;
//!   - mwboost::interprocess::interprocess_condition;
//!   - mwboost::interprocess::scoped_lock;
//!   - mwboost::interprocess::sharable_lock;
//!   - mwboost::interprocess::upgradable_lock;
//!
//! The following mutex families:
//!   - mwboost::interprocess::mutex_family;
//!   - mwboost::interprocess::null_mutex_family;
//!
//! The following allocators:
//!   - mwboost::interprocess::allocator;
//!   - mwboost::interprocess::node_allocator;
//!   - mwboost::interprocess::private_node_allocator;
//!   - mwboost::interprocess::cached_node_allocator;
//!   - mwboost::interprocess::adaptive_pool;
//!   - mwboost::interprocess::private_adaptive_pool;
//!   - mwboost::interprocess::cached_adaptive_pool;
//!
//! The following allocation algorithms:
//!   - mwboost::interprocess::simple_seq_fit;
//!   - mwboost::interprocess::rbtree_best_fit;
//!
//! The following index types:
//!   - mwboost::interprocess::flat_map_index;
//!   - mwboost::interprocess::iset_index;
//!   - mwboost::interprocess::iunordered_set_index;
//!   - mwboost::interprocess::map_index;
//!   - mwboost::interprocess::null_index;
//!   - mwboost::interprocess::unordered_map_index;
//!
//! The following managed memory types:
//!   - mwboost::interprocess::segment_manager;
//!   - mwboost::interprocess::basic_managed_external_buffer
//!   - mwboost::interprocess::managed_external_buffer
//!   - mwboost::interprocess::wmanaged_external_buffer
//!   - mwboost::interprocess::basic_managed_shared_memory
//!   - mwboost::interprocess::managed_shared_memory
//!   - mwboost::interprocess::wmanaged_shared_memory
//!   - mwboost::interprocess::basic_managed_windows_shared_memory
//!   - mwboost::interprocess::managed_windows_shared_memory
//!   - mwboost::interprocess::wmanaged_windows_shared_memory
//!   - mwboost::interprocess::basic_managed_xsi_shared_memory
//!   - mwboost::interprocess::managed_xsi_shared_memory
//!   - mwboost::interprocess::wmanaged_xsi_shared_memory
//!   - mwboost::interprocess::fixed_managed_shared_memory
//!   - mwboost::interprocess::wfixed_managed_shared_memory
//!   - mwboost::interprocess::basic_managed_heap_memory
//!   - mwboost::interprocess::managed_heap_memory
//!   - mwboost::interprocess::wmanaged_heap_memory
//!   - mwboost::interprocess::basic_managed_mapped_file
//!   - mwboost::interprocess::managed_mapped_file
//!   - mwboost::interprocess::wmanaged_mapped_file
//!
//! The following exception types:
//!   - mwboost::interprocess::interprocess_exception
//!   - mwboost::interprocess::lock_exception
//!   - mwboost::interprocess::bad_alloc
//!
//! The following stream types:
//!   - mwboost::interprocess::basic_bufferbuf
//!   - mwboost::interprocess::basic_ibufferstream
//!   - mwboost::interprocess::basic_obufferstream
//!   - mwboost::interprocess::basic_bufferstream
//!   - mwboost::interprocess::basic_vectorbuf
//!   - mwboost::interprocess::basic_ivectorstream
//!   - mwboost::interprocess::basic_ovectorstream
//!   - mwboost::interprocess::basic_vectorstream
//!
//! The following smart pointer types:
//!   - mwboost::interprocess::scoped_ptr
//!   - mwboost::interprocess::intrusive_ptr
//!   - mwboost::interprocess::shared_ptr
//!   - mwboost::interprocess::weak_ptr
//!
//! The following interprocess communication types:
//!   - mwboost::interprocess::message_queue_t;
//!   - mwboost::interprocess::message_queue;

#include <boost/interprocess/detail/config_begin.hpp>
#include <boost/interprocess/detail/workaround.hpp>

#if !defined(BOOST_INTERPROCESS_DOXYGEN_INVOKED)

#include <cstddef>

//////////////////////////////////////////////////////////////////////////////
//                        Standard predeclarations
//////////////////////////////////////////////////////////////////////////////

namespace mwboost {} namespace boost = mwboost; namespace mwboost{  namespace intrusive{ }  }
namespace mwboost {} namespace boost = mwboost; namespace mwboost{  namespace interprocess{ namespace bi = mwboost::intrusive; }  }

namespace mwboost {} namespace boost = mwboost; namespace mwboost { namespace interprocess {

//////////////////////////////////////////////////////////////////////////////
//                            permissions
//////////////////////////////////////////////////////////////////////////////

class permissions;

//////////////////////////////////////////////////////////////////////////////
//                            shared_memory
//////////////////////////////////////////////////////////////////////////////

class shared_memory_object;

#if defined (BOOST_INTERPROCESS_WINDOWS)
class windows_shared_memory;
#endif   //#if defined (BOOST_INTERPROCESS_WINDOWS)

#if defined(BOOST_INTERPROCESS_XSI_SHARED_MEMORY_OBJECTS)
class xsi_shared_memory;
#endif   //#if defined (BOOST_INTERPROCESS_WINDOWS)

//////////////////////////////////////////////////////////////////////////////
//              file mapping / mapped region
//////////////////////////////////////////////////////////////////////////////

class file_mapping;
class mapped_region;

//////////////////////////////////////////////////////////////////////////////
//                               Mutexes
//////////////////////////////////////////////////////////////////////////////

class null_mutex;

class interprocess_mutex;
class interprocess_recursive_mutex;

class named_mutex;
class named_recursive_mutex;

class interprocess_semaphore;
class named_semaphore;

//////////////////////////////////////////////////////////////////////////////
//                         Mutex families
//////////////////////////////////////////////////////////////////////////////

struct mutex_family;
struct null_mutex_family;

//////////////////////////////////////////////////////////////////////////////
//                   Other synchronization classes
//////////////////////////////////////////////////////////////////////////////

class interprocess_sharable_mutex;
class interprocess_condition;

//////////////////////////////////////////////////////////////////////////////
//                              Locks
//////////////////////////////////////////////////////////////////////////////

template <class Mutex>
class scoped_lock;

template <class SharableMutex>
class sharable_lock;

template <class UpgradableMutex>
class upgradable_lock;

//////////////////////////////////////////////////////////////////////////////
//                      STL compatible allocators
//////////////////////////////////////////////////////////////////////////////

template<class T, class SegmentManager>
class allocator;

template<class T, class SegmentManager, std::size_t NodesPerBlock = 64>
class node_allocator;

template<class T, class SegmentManager, std::size_t NodesPerBlock = 64>
class private_node_allocator;

template<class T, class SegmentManager, std::size_t NodesPerBlock = 64>
class cached_node_allocator;

template< class T, class SegmentManager, std::size_t NodesPerBlock = 64
        , std::size_t MaxFreeBlocks = 2, unsigned char OverheadPercent = 5 >
class adaptive_pool;

template< class T, class SegmentManager, std::size_t NodesPerBlock = 64
        , std::size_t MaxFreeBlocks = 2, unsigned char OverheadPercent = 5 >
class private_adaptive_pool;

template< class T, class SegmentManager, std::size_t NodesPerBlock = 64
        , std::size_t MaxFreeBlocks = 2, unsigned char OverheadPercent = 5 >
class cached_adaptive_pool;


//////////////////////////////////////////////////////////////////////////////
//                            offset_ptr
//////////////////////////////////////////////////////////////////////////////

static const std::size_t offset_type_alignment = 0;

#if !defined(BOOST_INTERPROCESS_DOXYGEN_INVOKED)
#  ifdef BOOST_HAS_INTPTR_T
      using ::mwboost::uintptr_t;
#  else
      typedef std::size_t uintptr_t;
#  endif
#endif

template < class T, class DifferenceType = std::ptrdiff_t
         , class OffsetType = uintptr_t, std::size_t Alignment = offset_type_alignment>
class offset_ptr;

//////////////////////////////////////////////////////////////////////////////
//                    Memory allocation algorithms
//////////////////////////////////////////////////////////////////////////////

//Single segment memory allocation algorithms
template<class MutexFamily, class VoidMutex = offset_ptr<void> >
class simple_seq_fit;

template<class MutexFamily, class VoidMutex = offset_ptr<void>, std::size_t MemAlignment = 0>
class rbtree_best_fit;

//////////////////////////////////////////////////////////////////////////////
//                         Index Types
//////////////////////////////////////////////////////////////////////////////

template<class IndexConfig> class flat_map_index;
template<class IndexConfig> class iset_index;
template<class IndexConfig> class iunordered_set_index;
template<class IndexConfig> class map_index;
template<class IndexConfig> class null_index;
template<class IndexConfig> class unordered_map_index;

//////////////////////////////////////////////////////////////////////////////
//                         Segment manager
//////////////////////////////////////////////////////////////////////////////

template <class CharType
         ,class MemoryAlgorithm
         ,template<class IndexConfig> class IndexType>
class segment_manager;

//////////////////////////////////////////////////////////////////////////////
//                  External buffer managed memory classes
//////////////////////////////////////////////////////////////////////////////

template <class CharType
         ,class MemoryAlgorithm
         ,template<class IndexConfig> class IndexType>
class basic_managed_external_buffer;

typedef basic_managed_external_buffer
   <char
   ,rbtree_best_fit<null_mutex_family>
   ,iset_index>
managed_external_buffer;

typedef basic_managed_external_buffer
   <wchar_t
   ,rbtree_best_fit<null_mutex_family>
   ,iset_index>
wmanaged_external_buffer;

//////////////////////////////////////////////////////////////////////////////
//                      managed memory classes
//////////////////////////////////////////////////////////////////////////////

template <class CharType
         ,class MemoryAlgorithm
         ,template<class IndexConfig> class IndexType>
class basic_managed_shared_memory;

typedef basic_managed_shared_memory
   <char
   ,rbtree_best_fit<mutex_family>
   ,iset_index>
managed_shared_memory;

typedef basic_managed_shared_memory
   <wchar_t
   ,rbtree_best_fit<mutex_family>
   ,iset_index>
wmanaged_shared_memory;


//////////////////////////////////////////////////////////////////////////////
//                      Windows shared memory managed memory classes
//////////////////////////////////////////////////////////////////////////////

#if defined (BOOST_INTERPROCESS_WINDOWS)

template <class CharType
         ,class MemoryAlgorithm
         ,template<class IndexConfig> class IndexType>
class basic_managed_windows_shared_memory;

typedef basic_managed_windows_shared_memory
   <char
   ,rbtree_best_fit<mutex_family>
   ,iset_index>
managed_windows_shared_memory;

typedef basic_managed_windows_shared_memory
   <wchar_t
   ,rbtree_best_fit<mutex_family>
   ,iset_index>
wmanaged_windows_shared_memory;

#endif   //#if defined (BOOST_INTERPROCESS_WINDOWS)

#if defined(BOOST_INTERPROCESS_XSI_SHARED_MEMORY_OBJECTS)

template <class CharType
         ,class MemoryAlgorithm
         ,template<class IndexConfig> class IndexType>
class basic_managed_xsi_shared_memory;

typedef basic_managed_xsi_shared_memory
   <char
   ,rbtree_best_fit<mutex_family>
   ,iset_index>
managed_xsi_shared_memory;

typedef basic_managed_xsi_shared_memory
   <wchar_t
   ,rbtree_best_fit<mutex_family>
   ,iset_index>
wmanaged_xsi_shared_memory;

#endif //#if defined(BOOST_INTERPROCESS_XSI_SHARED_MEMORY_OBJECTS)

//////////////////////////////////////////////////////////////////////////////
//                      Fixed address shared memory
//////////////////////////////////////////////////////////////////////////////

typedef basic_managed_shared_memory
   <char
   ,rbtree_best_fit<mutex_family, void*>
   ,iset_index>
fixed_managed_shared_memory;

typedef basic_managed_shared_memory
   <wchar_t
   ,rbtree_best_fit<mutex_family, void*>
   ,iset_index>
wfixed_managed_shared_memory;

//////////////////////////////////////////////////////////////////////////////
//                      Heap memory managed memory classes
//////////////////////////////////////////////////////////////////////////////

template
   <class CharType
   ,class MemoryAlgorithm
   ,template<class IndexConfig> class IndexType>
class basic_managed_heap_memory;

typedef basic_managed_heap_memory
   <char
   ,rbtree_best_fit<null_mutex_family>
   ,iset_index>
managed_heap_memory;

typedef basic_managed_heap_memory
   <wchar_t
   ,rbtree_best_fit<null_mutex_family>
   ,iset_index>
wmanaged_heap_memory;

//////////////////////////////////////////////////////////////////////////////
//                         Mapped file managed memory classes
//////////////////////////////////////////////////////////////////////////////

template
   <class CharType
   ,class MemoryAlgorithm
   ,template<class IndexConfig> class IndexType>
class basic_managed_mapped_file;

typedef basic_managed_mapped_file
   <char
   ,rbtree_best_fit<mutex_family>
   ,iset_index>
managed_mapped_file;

typedef basic_managed_mapped_file
   <wchar_t
   ,rbtree_best_fit<mutex_family>
   ,iset_index>
wmanaged_mapped_file;

//////////////////////////////////////////////////////////////////////////////
//                            Exceptions
//////////////////////////////////////////////////////////////////////////////

class interprocess_exception;
class lock_exception;
class bad_alloc;

//////////////////////////////////////////////////////////////////////////////
//                            Bufferstream
//////////////////////////////////////////////////////////////////////////////

//bufferstream
template <class CharT
         ,class CharTraits = std::char_traits<CharT> >
class basic_bufferbuf;

template <class CharT
         ,class CharTraits = std::char_traits<CharT> >
class basic_ibufferstream;

template <class CharT
         ,class CharTraits = std::char_traits<CharT> >
class basic_obufferstream;

template <class CharT
         ,class CharTraits = std::char_traits<CharT> >
class basic_bufferstream;

//////////////////////////////////////////////////////////////////////////////
//                            Vectorstream
//////////////////////////////////////////////////////////////////////////////

template <class CharVector
         ,class CharTraits = std::char_traits<typename CharVector::value_type> >
class basic_vectorbuf;

template <class CharVector
         ,class CharTraits = std::char_traits<typename CharVector::value_type> >
class basic_ivectorstream;

template <class CharVector
         ,class CharTraits = std::char_traits<typename CharVector::value_type> >
class basic_ovectorstream;

template <class CharVector
         ,class CharTraits = std::char_traits<typename CharVector::value_type> >
class basic_vectorstream;

//////////////////////////////////////////////////////////////////////////////
//                             Smart pointers
//////////////////////////////////////////////////////////////////////////////

template<class T, class Deleter>
class scoped_ptr;

template<class T, class VoidPointer>
class intrusive_ptr;

template<class T, class VoidAllocator, class Deleter>
class shared_ptr;

template<class T, class VoidAllocator, class Deleter>
class weak_ptr;

//////////////////////////////////////////////////////////////////////////////
//                                  IPC
//////////////////////////////////////////////////////////////////////////////

template<class VoidPointer>
class message_queue_t;

typedef message_queue_t<offset_ptr<void> > message_queue;

}}  //namespace mwboost {} namespace boost = mwboost; namespace mwboost { namespace interprocess {

#endif   //#if !defined(BOOST_INTERPROCESS_DOXYGEN_INVOKED)

#include <boost/interprocess/detail/config_end.hpp>

#endif //#ifndef BOOST_INTERPROCESS_FWD_HPP

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
