%MUSTBEBLOCK Check that value is valid content for a block template hole
%
%   MUSTBEBLOCK(A,holeId) issues an error if A is not a character array,
%   string, DOM object or HoleReporter whose HoleId property is equal to
%   holeId.
%
%   MUSTBEBLOCK(A,holeId, true) is equivalent to MUSTBEBLOCK(A,holeId)
%
%   MUSTBEBLOCK(A,holeId, false) is equivalent to MUSTBEBLOCK(A,holeId)
%   if A is a single value. Otherwise, it issues an error if A is not
%   an N-element array of size 1xN or Nx1 or if invoking
%   MUSTBEBLOCK(item, holeId, false) on any item in the array causes
%   an error.

 
%   Copyright 2017 The MathWorks, Inc.

