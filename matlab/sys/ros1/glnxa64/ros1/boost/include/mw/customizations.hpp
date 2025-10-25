// Copyright 2021 The MathWorks, Inc.
#ifndef MW_CUSTOMIZATIONS_HPP
#define MW_CUSTOMIZATIONS_HPP

#  pragma once

// MW specific customizations go here.
#if defined __linux__
#define BOOST_UUID_RANDOM_PROVIDER_GETRANDOM_IMPL_GETRANDOM(buf, size, flags) ::syscall(SYS_getrandom,buf,size,flags)
#define MW_BOOST_FILESYSTEM_IMPL_GETRANDOM(buf, size, flags) ::syscall(SYS_getrandom,buf,size,flags)
#endif

#ifdef _WIN32
#if defined(BOOST_USE_MW_CUSTOMIZATIONS) && !defined(BOOST_INTERPROCESS_SHARED_DIR_PATH)
#define BOOST_INTERPROCESS_SHARED_DIR_FUNC
#endif
#endif

#endif