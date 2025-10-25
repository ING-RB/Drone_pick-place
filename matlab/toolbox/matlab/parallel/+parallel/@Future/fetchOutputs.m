%FETCHOUTPUTS Retrieve all Futures outputs
%   [B1,B2,...,Bn] = FETCHOUTPUTS(F) fetches all outputs
%   of parallel.Futures F after first waiting for each element of F
%   to reach state 'finished'.  It is an error if any element of
%   F has NumOutputArguments less than the requested number of
%   outputs.
%
%   When F is a vector of parallel.Futures, each output argument is
%   formed by concatenating the corresponding output arguments from
%   each future in F. It is an error if these outputs cannot be
%   concatenated. In that case, set 'UniformOutput' to false.
%
%   It is an error to call fetchOutputs when F is a vector of
%   parallel.Futures, and some elements of F are
%   parallel.FevalOnAllFutures or parallel.AfterEachFutures.
%
%   [B1,B2,...,Bn] = FETCHOUTPUTS(F, 'UniformOutput', FALSE)
%   requests that the fetchOutputs function combine the outputs
%   into cell arrays B1,B2,...,Bn. The outputs of F can be of
%   any size or type.
%
%   After the call to fetchOutputs, all FevalFutures in F will
%   have the 'Read' property set to TRUE. fetchOutputs will
%   return outputs for all FevalFutures in F regardless of the
%   value of each future's 'Read' property.
%
%   Examples:
%   % make multiple parfeval calls, and fetch all outputs
%   for idx = 1:10
%       % request creation of a row of random numbers
%       F(idx) = parfeval(@rand, 1, 1, 10);
%   end
%   % fetch all outputs of F, value will be 10x10.
%   value = fetchOutputs(F);
%
%   See also parfeval,
%            parallel.FevalFuture.fetchNext.

% Copyright 2013-2021 The MathWorks, Inc.
