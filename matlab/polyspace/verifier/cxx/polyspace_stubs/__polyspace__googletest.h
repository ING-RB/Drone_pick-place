/* Copyright 2022 The MathWorks, Inc. */

/*
 * This file defines a helper macro and a set of supporting constructs used to
 * stub intelligently some Google Test assertions.
 * This helper macro is used in macro_to_deactivate_googletest.txt.
 *
 * Please use only C++98 constructs in this file.
 */

#ifndef __POLYSPACE__GOOGLETEST_H
#define __POLYSPACE__GOOGLETEST_H

#include <iosfwd>
#include <cstring> // for ASSERT_STREQ() and ASSERT_STRNE()
#include <cmath>   // for ASSERT_NEAR()

namespace polyspace { namespace gtest {

// Stub version of ::testing::Message class.
typedef std::ostream DummyMessage;
extern DummyMessage& dummyMessage;

// Stub version of ::testing::internal::AssertHelper that uses the same operator trick (see below).
struct DummyAssertHelper {
    void operator=(const DummyMessage&);
};

}} // namespace polyspace::gtest

// Return from calling function if `cond` is false.
// Use the same tricks as gtest assertions: the switch statement avoids an ambiguity on dangling
// else and allows to end the macro by an expression contrary to the `do { ... } while (0)` trick.
// Ending on an expression allows to support both `ASSERT_*()` and `ASSERT_*(...) << "boum"`
// cases.  The operator= trick in DummyAssertHelper allows to end the macro on a return statement
// optionally followed by a call to operator<<.
#define __POLYSPACE_GTEST_ASSERT_HELPER(cond) \
    switch (0) \
        default: \
        case 0: \
            if (!(cond)) \
                return ::polyspace::gtest::DummyAssertHelper() = ::polyspace::gtest::dummyMessage

#endif  /* __POLYSPACE__GOOGLETEST_H */
