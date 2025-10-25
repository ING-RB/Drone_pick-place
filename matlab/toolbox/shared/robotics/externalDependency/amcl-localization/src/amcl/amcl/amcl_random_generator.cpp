//  Copyright 2015-2019 The MathWorks, Inc.

#include "amcl_random_generator.h"
#include <cstdint>
#include <random>

/// Using constants from drand48 function
#ifdef _WIN32
static std::linear_congruential_engine<uint64_t, static_cast<uint64_t>(25214903917), 11, static_cast<uint64_t>(281474976710656)> generator(0);
#else
// GCC compiler does not support unsigned long long type in linear_congruential_engine.
static std::minstd_rand0 generator(0);
#endif

/// Uniform distribution between [0.0 1.0)
static std::uniform_real_distribution<double> distribution(0.0, 1.0);

/// Reproduce behavior of drand48 function in Linux
double linCongRand(void) 
{			    
	return distribution(generator);
}

/// Reset seed and distribution for random number generator
void setLinCongSeed(unsigned int seed)
{
	generator.seed(seed);
	distribution.reset();
}