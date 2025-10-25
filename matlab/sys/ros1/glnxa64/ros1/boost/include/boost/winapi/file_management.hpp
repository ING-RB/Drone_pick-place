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
 * Copyright 2010 Vicente J. Botet Escriba
 * Copyright 2015 Andrey Semashev
 * Copyright 2016 Jorge Lodos
 * Copyright 2017 James E. King, III
 *
 * Distributed under the Boost Software License, Version 1.0.
 * See http://www.boost.org/LICENSE_1_0.txt
 */

#ifndef BOOST_WINAPI_FILE_MANAGEMENT_HPP_INCLUDED_
#define BOOST_WINAPI_FILE_MANAGEMENT_HPP_INCLUDED_

#include <boost/winapi/basic_types.hpp>
#include <boost/winapi/limits.hpp>
#include <boost/winapi/time.hpp>
#include <boost/winapi/overlapped.hpp>
#include <boost/winapi/detail/header.hpp>

#ifdef BOOST_HAS_PRAGMA_ONCE
#pragma once
#endif

/*
 * UWP:
 * API                         SDK 8     SDK 10            _WIN32_WINNT
 * AreFileApisANSI             DESKTOP - DESKTOP | SYSTEM
 * CreateFile                  DESKTOP - DESKTOP | SYSTEM
 * DeleteFile                  APP     - APP     | SYSTEM
 * FindClose                   APP     - APP     | SYSTEM
 * FindFirstFile               DESKTOP > APP     | SYSTEM
 * FindNextFile                DESKTOP > APP     | SYSTEM
 * GetFileAttributes           DESKTOP > APP     | SYSTEM
 * GetFileInformationByHandle  DESKTOP - DESKTOP | SYSTEM
 * GetFileSizeEx               DESKTOP > APP     | SYSTEM
 * LockFile                    DESKTOP - DESKTOP | SYSTEM
 * MoveFileEx                  APP     - APP     | SYSTEM
 * ReadFile                    APP     - APP     | SYSTEM
 * SetEndOfFile                APP     - APP     | SYSTEM
 * SetFilePointer              DESKTOP > APP     | SYSTEM
 * SetFileValidData            DESKTOP - DESKTOP | SYSTEM  >= 0x0501
 * UnlockFile                  DESKTOP - DESKTOP | SYSTEM
 * WriteFile                   APP     - APP     | SYSTEM
 */

#if !defined( BOOST_USE_WINDOWS_H )
extern "C" {

#if BOOST_WINAPI_PARTITION_DESKTOP || BOOST_WINAPI_PARTITION_SYSTEM
#if !defined( BOOST_NO_ANSI_APIS )
BOOST_WINAPI_IMPORT mwboost::winapi::BOOL_ BOOST_WINAPI_WINAPI_CC
AreFileApisANSI(BOOST_WINAPI_DETAIL_VOID);

BOOST_WINAPI_IMPORT mwboost::winapi::HANDLE_ BOOST_WINAPI_WINAPI_CC
CreateFileA(
    mwboost::winapi::LPCSTR_ lpFileName,
    mwboost::winapi::DWORD_ dwDesiredAccess,
    mwboost::winapi::DWORD_ dwShareMode,
    ::_SECURITY_ATTRIBUTES* lpSecurityAttributes,
    mwboost::winapi::DWORD_ dwCreationDisposition,
    mwboost::winapi::DWORD_ dwFlagsAndAttributes,
    mwboost::winapi::HANDLE_ hTemplateFile);

struct _WIN32_FIND_DATAA;
BOOST_WINAPI_IMPORT mwboost::winapi::HANDLE_ BOOST_WINAPI_WINAPI_CC
FindFirstFileA(mwboost::winapi::LPCSTR_ lpFileName, ::_WIN32_FIND_DATAA* lpFindFileData);

BOOST_WINAPI_IMPORT mwboost::winapi::BOOL_ BOOST_WINAPI_WINAPI_CC
FindNextFileA(mwboost::winapi::HANDLE_ hFindFile, ::_WIN32_FIND_DATAA* lpFindFileData);
#endif

BOOST_WINAPI_IMPORT_EXCEPT_WM mwboost::winapi::HANDLE_ BOOST_WINAPI_WINAPI_CC
CreateFileW(
    mwboost::winapi::LPCWSTR_ lpFileName,
    mwboost::winapi::DWORD_ dwDesiredAccess,
    mwboost::winapi::DWORD_ dwShareMode,
    ::_SECURITY_ATTRIBUTES* lpSecurityAttributes,
    mwboost::winapi::DWORD_ dwCreationDisposition,
    mwboost::winapi::DWORD_ dwFlagsAndAttributes,
    mwboost::winapi::HANDLE_ hTemplateFile);

struct _WIN32_FIND_DATAW;
BOOST_WINAPI_IMPORT_EXCEPT_WM mwboost::winapi::HANDLE_ BOOST_WINAPI_WINAPI_CC
FindFirstFileW(mwboost::winapi::LPCWSTR_ lpFileName, ::_WIN32_FIND_DATAW* lpFindFileData);

BOOST_WINAPI_IMPORT_EXCEPT_WM mwboost::winapi::BOOL_ BOOST_WINAPI_WINAPI_CC
FindNextFileW(mwboost::winapi::HANDLE_ hFindFile, ::_WIN32_FIND_DATAW* lpFindFileData);

struct _BY_HANDLE_FILE_INFORMATION;
BOOST_WINAPI_IMPORT_EXCEPT_WM mwboost::winapi::BOOL_ BOOST_WINAPI_WINAPI_CC
GetFileInformationByHandle(
    mwboost::winapi::HANDLE_ hFile,
    ::_BY_HANDLE_FILE_INFORMATION* lpFileInformation);

BOOST_WINAPI_IMPORT mwboost::winapi::BOOL_ BOOST_WINAPI_WINAPI_CC
LockFile(
    mwboost::winapi::HANDLE_ hFile,
    mwboost::winapi::DWORD_ dwFileOffsetLow,
    mwboost::winapi::DWORD_ dwFileOffsetHigh,
    mwboost::winapi::DWORD_ nNumberOfBytesToLockLow,
    mwboost::winapi::DWORD_ nNumberOfBytesToLockHigh);

BOOST_WINAPI_IMPORT_EXCEPT_WM mwboost::winapi::BOOL_ BOOST_WINAPI_WINAPI_CC
LockFileEx(
    mwboost::winapi::HANDLE_ hFile,
    mwboost::winapi::DWORD_ dwFlags,
    mwboost::winapi::DWORD_ dwReserved,
    mwboost::winapi::DWORD_ nNumberOfBytesToLockLow,
    mwboost::winapi::DWORD_ nNumberOfBytesToLockHigh,
    ::_OVERLAPPED* lpOverlapped);

#if BOOST_USE_WINAPI_VERSION >= BOOST_WINAPI_VERSION_WINXP
BOOST_WINAPI_IMPORT mwboost::winapi::BOOL_ BOOST_WINAPI_WINAPI_CC
SetFileValidData(
    mwboost::winapi::HANDLE_ hFile, 
    mwboost::winapi::LONGLONG_ ValidDataLength);
#endif

BOOST_WINAPI_IMPORT mwboost::winapi::BOOL_ BOOST_WINAPI_WINAPI_CC
UnlockFile(
    mwboost::winapi::HANDLE_ hFile,
    mwboost::winapi::DWORD_ dwFileOffsetLow,
    mwboost::winapi::DWORD_ dwFileOffsetHigh,
    mwboost::winapi::DWORD_ nNumberOfBytesToUnlockLow,
    mwboost::winapi::DWORD_ nNumberOfBytesToUnlockHigh);

BOOST_WINAPI_IMPORT_EXCEPT_WM mwboost::winapi::BOOL_ BOOST_WINAPI_WINAPI_CC
UnlockFileEx(
    mwboost::winapi::HANDLE_ hFile,
    mwboost::winapi::DWORD_ dwReserved,
    mwboost::winapi::DWORD_ nNumberOfBytesToUnlockLow,
    mwboost::winapi::DWORD_ nNumberOfBytesToUnlockHigh,
    ::_OVERLAPPED* lpOverlapped);
#endif

#if BOOST_WINAPI_PARTITION_APP || BOOST_WINAPI_PARTITION_SYSTEM
#if !defined( BOOST_NO_ANSI_APIS )
BOOST_WINAPI_IMPORT mwboost::winapi::BOOL_ BOOST_WINAPI_WINAPI_CC
DeleteFileA(mwboost::winapi::LPCSTR_ lpFileName);

BOOST_WINAPI_IMPORT mwboost::winapi::BOOL_ BOOST_WINAPI_WINAPI_CC
MoveFileExA(
    mwboost::winapi::LPCSTR_ lpExistingFileName,
    mwboost::winapi::LPCSTR_ lpNewFileName,
    mwboost::winapi::DWORD_ dwFlags);
#endif

BOOST_WINAPI_IMPORT_EXCEPT_WM mwboost::winapi::BOOL_ BOOST_WINAPI_WINAPI_CC
DeleteFileW(mwboost::winapi::LPCWSTR_ lpFileName);

BOOST_WINAPI_IMPORT_EXCEPT_WM mwboost::winapi::BOOL_ BOOST_WINAPI_WINAPI_CC
FindClose(mwboost::winapi::HANDLE_ hFindFile);

BOOST_WINAPI_IMPORT mwboost::winapi::BOOL_ BOOST_WINAPI_WINAPI_CC
MoveFileExW(
    mwboost::winapi::LPCWSTR_ lpExistingFileName,
    mwboost::winapi::LPCWSTR_ lpNewFileName,
    mwboost::winapi::DWORD_ dwFlags);

BOOST_WINAPI_IMPORT_EXCEPT_WM mwboost::winapi::BOOL_ BOOST_WINAPI_WINAPI_CC
ReadFile(
    mwboost::winapi::HANDLE_ hFile,
    mwboost::winapi::LPVOID_ lpBuffer,
    mwboost::winapi::DWORD_ nNumberOfBytesToRead,
    mwboost::winapi::LPDWORD_ lpNumberOfBytesRead,
    ::_OVERLAPPED* lpOverlapped);

BOOST_WINAPI_IMPORT_EXCEPT_WM mwboost::winapi::BOOL_ BOOST_WINAPI_WINAPI_CC
SetEndOfFile(mwboost::winapi::HANDLE_ hFile);

BOOST_WINAPI_IMPORT_EXCEPT_WM mwboost::winapi::BOOL_ BOOST_WINAPI_WINAPI_CC
WriteFile(
    mwboost::winapi::HANDLE_ hFile,
    mwboost::winapi::LPCVOID_ lpBuffer,
    mwboost::winapi::DWORD_ nNumberOfBytesToWrite,
    mwboost::winapi::LPDWORD_ lpNumberOfBytesWritten,
    ::_OVERLAPPED* lpOverlapped);
#endif // BOOST_WINAPI_PARTITION_APP || BOOST_WINAPI_PARTITION_SYSTEM

#if BOOST_WINAPI_PARTITION_APP_SYSTEM
#if !defined( BOOST_NO_ANSI_APIS )
BOOST_WINAPI_IMPORT mwboost::winapi::DWORD_ BOOST_WINAPI_WINAPI_CC
GetFileAttributesA(mwboost::winapi::LPCSTR_ lpFileName);
#endif

BOOST_WINAPI_IMPORT_EXCEPT_WM mwboost::winapi::DWORD_ BOOST_WINAPI_WINAPI_CC
GetFileAttributesW(mwboost::winapi::LPCWSTR_ lpFileName);

BOOST_WINAPI_IMPORT mwboost::winapi::BOOL_ BOOST_WINAPI_WINAPI_CC
GetFileSizeEx(mwboost::winapi::HANDLE_ hFile, ::_LARGE_INTEGER* lpFileSize);

BOOST_WINAPI_IMPORT_EXCEPT_WM mwboost::winapi::DWORD_ BOOST_WINAPI_WINAPI_CC
SetFilePointer(
    mwboost::winapi::HANDLE_ hFile,
    mwboost::winapi::LONG_ lpDistanceToMove,
    mwboost::winapi::PLONG_ lpDistanceToMoveHigh,
    mwboost::winapi::DWORD_ dwMoveMethod);
#endif // BOOST_WINAPI_PARTITION_APP_SYSTEM

} // extern "C"
#endif // !defined(BOOST_USE_WINDOWS_H)

namespace mwboost {} namespace boost = mwboost; namespace mwboost {
namespace winapi {

#if defined( BOOST_USE_WINDOWS_H )

BOOST_CONSTEXPR_OR_CONST DWORD_ INVALID_FILE_SIZE_ = INVALID_FILE_SIZE;
BOOST_CONSTEXPR_OR_CONST DWORD_ INVALID_SET_FILE_POINTER_ = INVALID_SET_FILE_POINTER;
BOOST_CONSTEXPR_OR_CONST DWORD_ INVALID_FILE_ATTRIBUTES_ = INVALID_FILE_ATTRIBUTES;

BOOST_CONSTEXPR_OR_CONST DWORD_ FILE_ATTRIBUTE_READONLY_ = FILE_ATTRIBUTE_READONLY;
BOOST_CONSTEXPR_OR_CONST DWORD_ FILE_ATTRIBUTE_HIDDEN_ = FILE_ATTRIBUTE_HIDDEN;
BOOST_CONSTEXPR_OR_CONST DWORD_ FILE_ATTRIBUTE_SYSTEM_ = FILE_ATTRIBUTE_SYSTEM;
BOOST_CONSTEXPR_OR_CONST DWORD_ FILE_ATTRIBUTE_DIRECTORY_ = FILE_ATTRIBUTE_DIRECTORY;
BOOST_CONSTEXPR_OR_CONST DWORD_ FILE_ATTRIBUTE_ARCHIVE_ = FILE_ATTRIBUTE_ARCHIVE;
BOOST_CONSTEXPR_OR_CONST DWORD_ FILE_ATTRIBUTE_DEVICE_ = FILE_ATTRIBUTE_DEVICE;
BOOST_CONSTEXPR_OR_CONST DWORD_ FILE_ATTRIBUTE_NORMAL_ = FILE_ATTRIBUTE_NORMAL;
BOOST_CONSTEXPR_OR_CONST DWORD_ FILE_ATTRIBUTE_TEMPORARY_ = FILE_ATTRIBUTE_TEMPORARY;
BOOST_CONSTEXPR_OR_CONST DWORD_ FILE_ATTRIBUTE_SPARSE_FILE_ = FILE_ATTRIBUTE_SPARSE_FILE;
BOOST_CONSTEXPR_OR_CONST DWORD_ FILE_ATTRIBUTE_REPARSE_POINT_ = FILE_ATTRIBUTE_REPARSE_POINT;
BOOST_CONSTEXPR_OR_CONST DWORD_ FILE_ATTRIBUTE_COMPRESSED_ = FILE_ATTRIBUTE_COMPRESSED;
BOOST_CONSTEXPR_OR_CONST DWORD_ FILE_ATTRIBUTE_OFFLINE_ = FILE_ATTRIBUTE_OFFLINE;
BOOST_CONSTEXPR_OR_CONST DWORD_ FILE_ATTRIBUTE_NOT_CONTENT_INDEXED_ = FILE_ATTRIBUTE_NOT_CONTENT_INDEXED;
BOOST_CONSTEXPR_OR_CONST DWORD_ FILE_ATTRIBUTE_ENCRYPTED_ = FILE_ATTRIBUTE_ENCRYPTED;

BOOST_CONSTEXPR_OR_CONST DWORD_ CREATE_NEW_ = CREATE_NEW;
BOOST_CONSTEXPR_OR_CONST DWORD_ CREATE_ALWAYS_ = CREATE_ALWAYS;
BOOST_CONSTEXPR_OR_CONST DWORD_ OPEN_EXISTING_ = OPEN_EXISTING;
BOOST_CONSTEXPR_OR_CONST DWORD_ OPEN_ALWAYS_ = OPEN_ALWAYS;
BOOST_CONSTEXPR_OR_CONST DWORD_ TRUNCATE_EXISTING_ = TRUNCATE_EXISTING;

BOOST_CONSTEXPR_OR_CONST DWORD_ FILE_SHARE_READ_ = FILE_SHARE_READ;
BOOST_CONSTEXPR_OR_CONST DWORD_ FILE_SHARE_WRITE_ = FILE_SHARE_WRITE;
BOOST_CONSTEXPR_OR_CONST DWORD_ FILE_SHARE_DELETE_ = FILE_SHARE_DELETE;

BOOST_CONSTEXPR_OR_CONST DWORD_ FILE_BEGIN_ = FILE_BEGIN;
BOOST_CONSTEXPR_OR_CONST DWORD_ FILE_CURRENT_ = FILE_CURRENT;
BOOST_CONSTEXPR_OR_CONST DWORD_ FILE_END_ = FILE_END;

#else // defined( BOOST_USE_WINDOWS_H )

BOOST_CONSTEXPR_OR_CONST DWORD_ INVALID_FILE_SIZE_ = ((DWORD_)0xFFFFFFFF);
BOOST_CONSTEXPR_OR_CONST DWORD_ INVALID_SET_FILE_POINTER_ = ((DWORD_)-1);
BOOST_CONSTEXPR_OR_CONST DWORD_ INVALID_FILE_ATTRIBUTES_ = ((DWORD_)-1);

BOOST_CONSTEXPR_OR_CONST DWORD_ FILE_ATTRIBUTE_READONLY_ = 0x00000001;
BOOST_CONSTEXPR_OR_CONST DWORD_ FILE_ATTRIBUTE_HIDDEN_ = 0x00000002;
BOOST_CONSTEXPR_OR_CONST DWORD_ FILE_ATTRIBUTE_SYSTEM_ = 0x00000004;
BOOST_CONSTEXPR_OR_CONST DWORD_ FILE_ATTRIBUTE_DIRECTORY_ = 0x00000010;
BOOST_CONSTEXPR_OR_CONST DWORD_ FILE_ATTRIBUTE_ARCHIVE_ = 0x00000020;
BOOST_CONSTEXPR_OR_CONST DWORD_ FILE_ATTRIBUTE_DEVICE_ = 0x00000040;
BOOST_CONSTEXPR_OR_CONST DWORD_ FILE_ATTRIBUTE_NORMAL_ = 0x00000080;
BOOST_CONSTEXPR_OR_CONST DWORD_ FILE_ATTRIBUTE_TEMPORARY_ = 0x00000100;
BOOST_CONSTEXPR_OR_CONST DWORD_ FILE_ATTRIBUTE_SPARSE_FILE_ = 0x00000200;
BOOST_CONSTEXPR_OR_CONST DWORD_ FILE_ATTRIBUTE_REPARSE_POINT_ = 0x00000400;
BOOST_CONSTEXPR_OR_CONST DWORD_ FILE_ATTRIBUTE_COMPRESSED_ = 0x00000800;
BOOST_CONSTEXPR_OR_CONST DWORD_ FILE_ATTRIBUTE_OFFLINE_ = 0x00001000;
BOOST_CONSTEXPR_OR_CONST DWORD_ FILE_ATTRIBUTE_NOT_CONTENT_INDEXED_ = 0x00002000;
BOOST_CONSTEXPR_OR_CONST DWORD_ FILE_ATTRIBUTE_ENCRYPTED_ = 0x00004000;

BOOST_CONSTEXPR_OR_CONST DWORD_ CREATE_NEW_ = 1;
BOOST_CONSTEXPR_OR_CONST DWORD_ CREATE_ALWAYS_ = 2;
BOOST_CONSTEXPR_OR_CONST DWORD_ OPEN_EXISTING_ = 3;
BOOST_CONSTEXPR_OR_CONST DWORD_ OPEN_ALWAYS_ = 4;
BOOST_CONSTEXPR_OR_CONST DWORD_ TRUNCATE_EXISTING_ = 5;

BOOST_CONSTEXPR_OR_CONST DWORD_ FILE_SHARE_READ_ = 0x00000001;
BOOST_CONSTEXPR_OR_CONST DWORD_ FILE_SHARE_WRITE_ = 0x00000002;
BOOST_CONSTEXPR_OR_CONST DWORD_ FILE_SHARE_DELETE_ = 0x00000004;

BOOST_CONSTEXPR_OR_CONST DWORD_ FILE_BEGIN_ = 0;
BOOST_CONSTEXPR_OR_CONST DWORD_ FILE_CURRENT_ = 1;
BOOST_CONSTEXPR_OR_CONST DWORD_ FILE_END_ = 2;

#endif // defined( BOOST_USE_WINDOWS_H )

// Some of these constants are not defined by Windows SDK in MinGW or older MSVC
BOOST_CONSTEXPR_OR_CONST DWORD_ FILE_FLAG_WRITE_THROUGH_ = 0x80000000;
BOOST_CONSTEXPR_OR_CONST DWORD_ FILE_FLAG_OVERLAPPED_ = 0x40000000;
BOOST_CONSTEXPR_OR_CONST DWORD_ FILE_FLAG_NO_BUFFERING_ = 0x20000000;
BOOST_CONSTEXPR_OR_CONST DWORD_ FILE_FLAG_RANDOM_ACCESS_ = 0x10000000;
BOOST_CONSTEXPR_OR_CONST DWORD_ FILE_FLAG_SEQUENTIAL_SCAN_ = 0x08000000;
BOOST_CONSTEXPR_OR_CONST DWORD_ FILE_FLAG_DELETE_ON_CLOSE_ = 0x04000000;
BOOST_CONSTEXPR_OR_CONST DWORD_ FILE_FLAG_BACKUP_SEMANTICS_ = 0x02000000;
BOOST_CONSTEXPR_OR_CONST DWORD_ FILE_FLAG_POSIX_SEMANTICS_ = 0x01000000;
BOOST_CONSTEXPR_OR_CONST DWORD_ FILE_FLAG_SESSION_AWARE_ = 0x00800000;
BOOST_CONSTEXPR_OR_CONST DWORD_ FILE_FLAG_OPEN_REPARSE_POINT_ = 0x00200000;
BOOST_CONSTEXPR_OR_CONST DWORD_ FILE_FLAG_OPEN_NO_RECALL_ = 0x00100000;
BOOST_CONSTEXPR_OR_CONST DWORD_ FILE_FLAG_FIRST_PIPE_INSTANCE_ = 0x00080000;

#if BOOST_USE_WINAPI_VERSION >= BOOST_WINAPI_VERSION_WIN8
BOOST_CONSTEXPR_OR_CONST DWORD_ FILE_FLAG_OPEN_REQUIRING_OPLOCK_ = 0x00040000;
#endif

// This constant is not defined in Windows SDK up until 6.0A
BOOST_CONSTEXPR_OR_CONST DWORD_ FILE_ATTRIBUTE_VIRTUAL_ = 0x00010000;

// These constants are not defined in Windows SDK up until 8.0 and MinGW/MinGW-w64 (as of 2016-02-14).
// They are documented to be supported only since Windows 8/Windows Server 2012
// but defined unconditionally.
BOOST_CONSTEXPR_OR_CONST DWORD_ FILE_ATTRIBUTE_INTEGRITY_STREAM_ = 0x00008000;
BOOST_CONSTEXPR_OR_CONST DWORD_ FILE_ATTRIBUTE_NO_SCRUB_DATA_ = 0x00020000;
// Undocumented
BOOST_CONSTEXPR_OR_CONST DWORD_ FILE_ATTRIBUTE_EA_ = 0x00040000;

#if BOOST_WINAPI_PARTITION_DESKTOP || BOOST_WINAPI_PARTITION_SYSTEM
#if !defined( BOOST_NO_ANSI_APIS )
using ::AreFileApisANSI;

BOOST_FORCEINLINE HANDLE_ CreateFileA(
    LPCSTR_ lpFileName,
    DWORD_ dwDesiredAccess,
    DWORD_ dwShareMode,
    SECURITY_ATTRIBUTES_* lpSecurityAttributes,
    DWORD_ dwCreationDisposition,
    DWORD_ dwFlagsAndAttributes,
    HANDLE_ hTemplateFile)
{
    return ::CreateFileA(
        lpFileName,
        dwDesiredAccess,
        dwShareMode,
        reinterpret_cast< ::_SECURITY_ATTRIBUTES* >(lpSecurityAttributes),
        dwCreationDisposition,
        dwFlagsAndAttributes,
        hTemplateFile);
}

BOOST_FORCEINLINE HANDLE_ create_file(
    LPCSTR_ lpFileName,
    DWORD_ dwDesiredAccess,
    DWORD_ dwShareMode,
    SECURITY_ATTRIBUTES_* lpSecurityAttributes,
    DWORD_ dwCreationDisposition,
    DWORD_ dwFlagsAndAttributes,
    HANDLE_ hTemplateFile)
{
    return ::CreateFileA(
        lpFileName,
        dwDesiredAccess,
        dwShareMode,
        reinterpret_cast< ::_SECURITY_ATTRIBUTES* >(lpSecurityAttributes),
        dwCreationDisposition,
        dwFlagsAndAttributes,
        hTemplateFile);
}

typedef struct BOOST_MAY_ALIAS _WIN32_FIND_DATAA {
    DWORD_ dwFileAttributes;
    FILETIME_ ftCreationTime;
    FILETIME_ ftLastAccessTime;
    FILETIME_ ftLastWriteTime;
    DWORD_ nFileSizeHigh;
    DWORD_ nFileSizeLow;
    DWORD_ dwReserved0;
    DWORD_ dwReserved1;
    CHAR_   cFileName[MAX_PATH_];
    CHAR_   cAlternateFileName[14];
#ifdef _MAC
    DWORD_ dwFileType;
    DWORD_ dwCreatorType;
    WORD_  wFinderFlags;
#endif
} WIN32_FIND_DATAA_, *PWIN32_FIND_DATAA_, *LPWIN32_FIND_DATAA_;

BOOST_FORCEINLINE HANDLE_ FindFirstFileA(LPCSTR_ lpFileName, WIN32_FIND_DATAA_* lpFindFileData)
{
    return ::FindFirstFileA(lpFileName, reinterpret_cast< ::_WIN32_FIND_DATAA* >(lpFindFileData));
}

BOOST_FORCEINLINE HANDLE_ find_first_file(LPCSTR_ lpFileName, WIN32_FIND_DATAA_* lpFindFileData)
{
    return ::FindFirstFileA(lpFileName, reinterpret_cast< ::_WIN32_FIND_DATAA* >(lpFindFileData));
}

BOOST_FORCEINLINE BOOL_ FindNextFileA(HANDLE_ hFindFile, WIN32_FIND_DATAA_* lpFindFileData)
{
    return ::FindNextFileA(hFindFile, reinterpret_cast< ::_WIN32_FIND_DATAA* >(lpFindFileData));
}

BOOST_FORCEINLINE BOOL_ find_next_file(HANDLE_ hFindFile, WIN32_FIND_DATAA_* lpFindFileData)
{
    return ::FindNextFileA(hFindFile, reinterpret_cast< ::_WIN32_FIND_DATAA* >(lpFindFileData));
}

#endif // !defined( BOOST_NO_ANSI_APIS )

BOOST_FORCEINLINE HANDLE_ CreateFileW(
    LPCWSTR_ lpFileName,
    DWORD_ dwDesiredAccess,
    DWORD_ dwShareMode,
    SECURITY_ATTRIBUTES_* lpSecurityAttributes,
    DWORD_ dwCreationDisposition,
    DWORD_ dwFlagsAndAttributes,
    HANDLE_ hTemplateFile)
{
    return ::CreateFileW(
        lpFileName,
        dwDesiredAccess,
        dwShareMode,
        reinterpret_cast< ::_SECURITY_ATTRIBUTES* >(lpSecurityAttributes),
        dwCreationDisposition,
        dwFlagsAndAttributes,
        hTemplateFile);
}

BOOST_FORCEINLINE HANDLE_ create_file(
    LPCWSTR_ lpFileName,
    DWORD_ dwDesiredAccess,
    DWORD_ dwShareMode,
    SECURITY_ATTRIBUTES_* lpSecurityAttributes,
    DWORD_ dwCreationDisposition,
    DWORD_ dwFlagsAndAttributes,
    HANDLE_ hTemplateFile)
{
    return ::CreateFileW(
        lpFileName,
        dwDesiredAccess,
        dwShareMode,
        reinterpret_cast< ::_SECURITY_ATTRIBUTES* >(lpSecurityAttributes),
        dwCreationDisposition,
        dwFlagsAndAttributes,
        hTemplateFile);
}

typedef struct BOOST_MAY_ALIAS _WIN32_FIND_DATAW {
    DWORD_ dwFileAttributes;
    FILETIME_ ftCreationTime;
    FILETIME_ ftLastAccessTime;
    FILETIME_ ftLastWriteTime;
    DWORD_ nFileSizeHigh;
    DWORD_ nFileSizeLow;
    DWORD_ dwReserved0;
    DWORD_ dwReserved1;
    WCHAR_  cFileName[MAX_PATH_];
    WCHAR_  cAlternateFileName[14];
#ifdef _MAC
    DWORD_ dwFileType;
    DWORD_ dwCreatorType;
    WORD_  wFinderFlags;
#endif
} WIN32_FIND_DATAW_, *PWIN32_FIND_DATAW_, *LPWIN32_FIND_DATAW_;

typedef struct BOOST_MAY_ALIAS _BY_HANDLE_FILE_INFORMATION {
    DWORD_ dwFileAttributes;
    FILETIME_ ftCreationTime;
    FILETIME_ ftLastAccessTime;
    FILETIME_ ftLastWriteTime;
    DWORD_ dwVolumeSerialNumber;
    DWORD_ nFileSizeHigh;
    DWORD_ nFileSizeLow;
    DWORD_ nNumberOfLinks;
    DWORD_ nFileIndexHigh;
    DWORD_ nFileIndexLow;
} BY_HANDLE_FILE_INFORMATION_, *PBY_HANDLE_FILE_INFORMATION_, *LPBY_HANDLE_FILE_INFORMATION_;

BOOST_FORCEINLINE HANDLE_ FindFirstFileW(LPCWSTR_ lpFileName, WIN32_FIND_DATAW_* lpFindFileData)
{
    return ::FindFirstFileW(lpFileName, reinterpret_cast< ::_WIN32_FIND_DATAW* >(lpFindFileData));
}

BOOST_FORCEINLINE HANDLE_ find_first_file(LPCWSTR_ lpFileName, WIN32_FIND_DATAW_* lpFindFileData)
{
    return ::FindFirstFileW(lpFileName, reinterpret_cast< ::_WIN32_FIND_DATAW* >(lpFindFileData));
}

BOOST_FORCEINLINE BOOL_ FindNextFileW(HANDLE_ hFindFile, WIN32_FIND_DATAW_* lpFindFileData)
{
    return ::FindNextFileW(hFindFile, reinterpret_cast< ::_WIN32_FIND_DATAW* >(lpFindFileData));
}

BOOST_FORCEINLINE BOOL_ find_next_file(HANDLE_ hFindFile, WIN32_FIND_DATAW_* lpFindFileData)
{
    return ::FindNextFileW(hFindFile, reinterpret_cast< ::_WIN32_FIND_DATAW* >(lpFindFileData));
}

BOOST_FORCEINLINE BOOL_ GetFileInformationByHandle(HANDLE_ h, BY_HANDLE_FILE_INFORMATION_* info)
{
    return ::GetFileInformationByHandle(h, reinterpret_cast< ::_BY_HANDLE_FILE_INFORMATION* >(info));
}

using ::LockFile;

BOOST_FORCEINLINE BOOL_ LockFileEx(
    HANDLE_ hFile,
    DWORD_ dwFlags,
    DWORD_ dwReserved,
    DWORD_ nNumberOfBytesToLockLow,
    DWORD_ nNumberOfBytesToLockHigh,
    OVERLAPPED_* lpOverlapped)
{
    return ::LockFileEx(hFile, dwFlags, dwReserved, nNumberOfBytesToLockLow, nNumberOfBytesToLockHigh, reinterpret_cast< ::_OVERLAPPED* >(lpOverlapped));
}

#if BOOST_USE_WINAPI_VERSION >= BOOST_WINAPI_VERSION_WINXP
using ::SetFileValidData;
#endif

using ::UnlockFile;

BOOST_FORCEINLINE BOOL_ UnlockFileEx(
    HANDLE_ hFile,
    DWORD_ dwReserved,
    DWORD_ nNumberOfBytesToUnlockLow,
    DWORD_ nNumberOfBytesToUnlockHigh,
    OVERLAPPED_* lpOverlapped)
{
    return ::UnlockFileEx(hFile, dwReserved, nNumberOfBytesToUnlockLow, nNumberOfBytesToUnlockHigh, reinterpret_cast< ::_OVERLAPPED* >(lpOverlapped));
}
#endif // BOOST_WINAPI_PARTITION_DESKTOP || BOOST_WINAPI_PARTITION_SYSTEM

#if BOOST_WINAPI_PARTITION_APP || BOOST_WINAPI_PARTITION_SYSTEM
#if !defined( BOOST_NO_ANSI_APIS )
using ::DeleteFileA;

BOOST_FORCEINLINE BOOL_ delete_file(LPCSTR_ lpFileName)
{
    return ::DeleteFileA(lpFileName);
}

using ::MoveFileExA;

BOOST_FORCEINLINE BOOL_ move_file(LPCSTR_ lpExistingFileName, LPCSTR_ lpNewFileName, DWORD_ dwFlags)
{
    return ::MoveFileExA(lpExistingFileName, lpNewFileName, dwFlags);
}

#endif
using ::DeleteFileW;

BOOST_FORCEINLINE BOOL_ delete_file(LPCWSTR_ lpFileName)
{
    return ::DeleteFileW(lpFileName);
}

using ::FindClose;
using ::MoveFileExW;

BOOST_FORCEINLINE BOOL_ move_file(LPCWSTR_ lpExistingFileName, LPCWSTR_ lpNewFileName, DWORD_ dwFlags)
{
    return ::MoveFileExW(lpExistingFileName, lpNewFileName, dwFlags);
}

BOOST_FORCEINLINE BOOL_ ReadFile(
    HANDLE_ hFile,
    LPVOID_ lpBuffer,
    DWORD_ nNumberOfBytesToWrite,
    LPDWORD_ lpNumberOfBytesWritten,
    OVERLAPPED_* lpOverlapped)
{
    return ::ReadFile(hFile, lpBuffer, nNumberOfBytesToWrite, lpNumberOfBytesWritten, reinterpret_cast< ::_OVERLAPPED* >(lpOverlapped));
}

using ::SetEndOfFile;

BOOST_FORCEINLINE BOOL_ WriteFile(
    HANDLE_ hFile,
    LPCVOID_ lpBuffer,
    DWORD_ nNumberOfBytesToWrite,
    LPDWORD_ lpNumberOfBytesWritten,
    OVERLAPPED_* lpOverlapped)
{
    return ::WriteFile(hFile, lpBuffer, nNumberOfBytesToWrite, lpNumberOfBytesWritten, reinterpret_cast< ::_OVERLAPPED* >(lpOverlapped));
}
#endif // BOOST_WINAPI_PARTITION_APP || BOOST_WINAPI_PARTITION_SYSTEM

#if BOOST_WINAPI_PARTITION_APP_SYSTEM
#if !defined( BOOST_NO_ANSI_APIS )
using ::GetFileAttributesA;

BOOST_FORCEINLINE DWORD_ get_file_attributes(LPCSTR_ lpFileName)
{
    return ::GetFileAttributesA(lpFileName);
}
#endif
using ::GetFileAttributesW;

BOOST_FORCEINLINE DWORD_ get_file_attributes(LPCWSTR_ lpFileName)
{
    return ::GetFileAttributesW(lpFileName);
}

BOOST_FORCEINLINE BOOL_ GetFileSizeEx(HANDLE_ hFile, LARGE_INTEGER_* lpFileSize)
{
    return ::GetFileSizeEx(hFile, reinterpret_cast< ::_LARGE_INTEGER* >(lpFileSize));
}

using ::SetFilePointer;
#endif // BOOST_WINAPI_PARTITION_APP_SYSTEM

}
}

#include <boost/winapi/detail/footer.hpp>

#endif // BOOST_WINAPI_FILE_MANAGEMENT_HPP_INCLUDED_

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
