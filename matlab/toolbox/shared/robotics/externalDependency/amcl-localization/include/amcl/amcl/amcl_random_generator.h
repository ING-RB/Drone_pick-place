/**
* @file random_generator.h
* 
* Linear congruential random number generator 
* similar to drand48.
*
* Copyright 2015-2019 The MathWorks, Inc.
*/

#ifndef AMCL_RANDOM_GENERATOR_H
#define AMCL_RANDOM_GENERATOR_H

#ifdef __cplusplus
extern "C" {
#endif

	/** 
	* @brief Linear congruential random number generator
	*
	* This function generates random numbers that are similar 
	* to drand48 function on Linux. This function returns values
	* between [0.0 1.0). The seed can be changed
	* using the setLinCongSeed function.
	*
	* @return double random number between [0.0 1.0)
	*/
	double linCongRand(void);

	/** 
	* @brief Set seed for random number generator
	*
	* This function sets seed for linCongRand function and 
	* resets the uniform distribution.
	*
	* @param seed unsigned int. Seed for random number generator.
	*/
	void setLinCongSeed(unsigned int seed);


#ifdef __cplusplus
}
#endif

#endif