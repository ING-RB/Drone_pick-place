/* Copyright 2024 The MathWorks, Inc. */

#include <vector>
#include <string>
#include <iostream>
#include <fstream>
#include <sstream>
#include <cstdlib>
#include <regex>
#include <unordered_map>

/*
   print_arm_neon
   --------------
   This utility prints the contents of 'arm_neon.inc' files as C/C++ declarations that
   can be added to polyspace/verifier/extensions/armclang/tmw_builtins/armclang_neon.h.

   To compile, place this source source file and your latest and greatest arm_neon.inc file
   in the same directory. Then run the executable:
     $ g++ print_arm_neon.cpp -o print_arm_neon
     $ ./print_arm_neon > my_neon.h
   Edit the end of my_neon.h (see below), then
     $ p4 edit <sb>/matlab/polyspace/verifier/extensions/armclang/tmw_builtins/armclang_neon.h
     $ mv my_neon.h <sb>/matlab/polyspace/verifier/extensions/armclang/tmw_builtins/armclang_neon.h

   If a built-in signature cannot be parsed, a type code must be added to typeMap below.

   ARM Neon description files declare built-ins with macros BUILTIN and TARGET_BUILTIN
   (don't know the difference). Their first argument is the built-in name, and the second
   a signature. Each signature is a sequence of type codes, the first for the return type
   and the other ones for the arguments. The map below lists the type codes I have found
   so far (Xcode 15.1.0). Basically, they are composed from

    - optional vector specifier: V followed by a number: the number of elements in the vector
    - optional sign (S for signed, U for unsigned, sometimes US for unsigned?, I for signed?)
    - base type:
        c:    char (int8_t)
        s:    short (int16_t)
        i:    int (int32_t)
        Wi:   "wide" int, i.e. long long (int64_t)
        LLLi: "long long long" int (int128_t)
        d:    double (float64_t)
        f:    float (float32_t)
        h:    half float (float16_t)
        y:    alternative half float (bfloat_t)
        v:    void (can be followed by C for const)
    - optional '*' to declare pointer type
*/

// Do not use std::{unordered_,}map because the longer type codes must be matched first!
std::vector<std::pair<std::string, std::string>> typeMap {
  // Vectors with base type 'c': char = int8_t
  {"V8Sc",   "int8x8_t"}, // vector of 8 signed int
  {"V8Uc",   "uint8x8_t"},
  {"V8USc",  "uint8x8_t"},
  {"V16Sc",  "int8x16_t"},
  {"V16USc", "uint8x16_t"},
  {"V16Uc",  "uint8x16_t"},
  // Vectors with base type 's': short = int16_t
  {"V2s",    "int16x2_t"},
  {"V4s",    "int16x4_t"},
  {"V4Us",   "uint16x4_t"},
  {"V8s",    "int16x8_t"},
  {"V8Us",   "uint16x8_t"},
  // Vectors with base type 'i': int = int32_t
  {"V2i",    "int32x2_t"},
  {"V2Ui",   "uint32x2_t"},
  {"V4i",    "int32x4_t"},
  {"V4Ui",   "uint32x4_t"},
  // Vectors with base type 'Wi': "wide" int = long long = int64_t
  {"V1Wi",   "int64x1_t"},
  {"V2Wi",   "int64x2_t"},
  {"V2UWi",  "uint64x2_t"},
  // Vectors with base type 'f': float = float32_t
  {"V2f",    "float32x2_t"},
  {"V4f",    "float32x4_t"},
  // Vectors with base type 'd': double = float64_t
  {"V1d",    "float64x1_t"},
  {"V2d",    "float64x2_t"},
  {"V4d",    "float64x4_t"},
  // Vectors with base type 'h': float16_t
  {"V4h",    "float16x4_t"},
  {"V8h",    "float16x8_t"},
  // Vectors with base type 'y': bfloat16_t
  {"V4y",    "bfloat16x4_t"},
  {"V8y",    "bfloat16x8_t"},

  {"Wi",     "signed long long"}, // int64_t
  {"UWi",    "unsigned long long"}, // uint64_t
  {"ULLLi",  "uint128_t"}, // I suppose because of "p128" in names, for "unsigned long long long int"
  {"LLLi",   "int128_t"}, // Or SLLLi? For "signed long long long int"
  {"Sc",     "signed char"},
  {"Uc",     "unsigned char"},
  {"c",      "char"},
  {"Ui",     "unsigned int"},
  {"Ii",     "signed int"}, // int32_t
  {"i",      "int"},
  {"Ss",     "signed short"},
  {"Us",     "unsigned short"},
  {"s",      "short"},
  {"f",      "float32_t"}, // float
  {"d",      "float64_t"}, // double
  {"h",      "float16_t"},
  {"y",      "bfloat16_t"},
  {"vC*",    "const void*"},
  {"v*",     "void*"},
  {"v",      "void"},
};

struct Line {
  std::string text;
  std::string builtin;
};

struct Neon {
  std::vector<Line> contents;
  std::unordered_map<std::string, size_t> line;
};

Neon newNeon;

typedef std::string::size_type pos_t;

static pos_t print_type(std::stringstream &ss, const std::string &sig, pos_t idx, pos_t end) {
  // Not the most efficient way to parse out a type from the signature, but we must ensure
  // that longer types are matched before shorter ones to avoid matching e.g. the "i" in "V4i".
  for (auto &p : typeMap) {
    std::string &cand = p.first;
    if (sig.compare(idx, cand.length(), cand) == 0) {
      ss << p.second;
      return idx + cand.length();
    }
  }
  std::cerr << "Did not match beginning of " << sig.substr(idx) << ", please add to table.\n";
  exit(1);
}

static void print_builtin(const std::string &name, const std::string &sig) {
  pos_t idx = 0;
  std::stringstream ss;
  ss << "PST_LINK_C ";
  idx = print_type(ss, sig, idx, sig.length());
  ss << " " << name << "(";
  std::string sep = "";
  while (idx != sig.length()) {
    ss << sep;
    idx = print_type(ss, sig, idx, sig.length());
    sep = ", ";
  }
  ss << ");";

  newNeon.line[name] = newNeon.contents.size();
  newNeon.contents.push_back({ss.str(), name});
}

static void read_armclang_neon(Neon *neon, const std::string &fname) {
  try {
    std::ifstream f;
    std::string line;
    std::string prefix{"PST_LINK_C"};
    f.open(fname, std::ifstream::in);
    while (std::getline(f, line)) {
      std::string builtin;
      // Store all lines sequentially, noting the lines that declare a built-in.
      // In our syntax extensions built-in headers they always begin with PST_LINK_C.
      std::regex re{"__builtin[a-z0-9_]*"};
      if (line.compare(0, prefix.length(), prefix) == 0) {
        std::smatch match;
        std::regex_search(line, match, re);
        if (match.size() == 1) {
          builtin = match[0];
          neon->line[builtin] = neon->contents.size();
        }
      }
      neon->contents.push_back({line, builtin});
    }
    f.close();
  } catch (const std::exception &e) {
    std::cerr << "An error occurred: " << e.what() << "\n";
    exit(1);
  }
}

#define TARGET_BUILTIN(name, sig, ...) print_builtin(#name, sig);
#define BUILTIN(name, sig, ...) print_builtin(#name, sig);

#define GET_NEON_BUILTINS
#undef GET_NEON_OVERLOAD_CHECK

int main(int argc, char **argv) {
  if (argc > 2) {
    std::cerr << "Usage: print_arm_neon [full path to armclang_neon.h]\n";
    return 1;
  }
  Neon neon;
  if (argc > 1) {
    read_armclang_neon(&neon, argv[1]);
  }

#include "arm_neon.inc"

  if (neon.contents.size() > 0) {
    /*
       An existing armclang_neon.h has just been read. For each built-in that is
       also in the arm_neon.inc, output the newly created declaration, otherwise
       write out the original declaration. Clear new declarations from 'neon' after
       they have been written.

       Print the declarations that were not in the existing armclang.h at the end.
       It means that you will have to edit the result a bit to move #endifs and
       comments around near the end of the file.
    */
    for (auto &line : neon.contents) {
      bool replaced = false;
      if (!line.builtin.empty()) {
        auto it = newNeon.line.find(line.builtin);
        if (it != newNeon.line.end()) {
          // A built-in in the existing armclang_neon.h occurs in arm_neon.inc.
          auto idx = it->second;
          std::cout << newNeon.contents[idx].text << "\n";
          newNeon.contents[idx].text.clear();
          replaced = true;
        }
      }
      if (!replaced) {
        std::cout << line.text << "\n";
      }
    }
  }
  for (auto &line : newNeon.contents) {
    if (!line.text.empty()) {
      std::cout << line.text << "\n";
    }
  }
  return 0;
}
