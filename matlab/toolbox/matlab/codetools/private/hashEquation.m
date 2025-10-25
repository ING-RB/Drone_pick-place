function s = hashEquation(a)
% HASHEQUATION  Converts an arbitrary string into one suitable for a filename.
%   HASHEQUATION(A) returns a string usitable for a filename.

% Matthew J. Simoneau
% Copyright 1984-2013 The MathWorks, Inc. 

if isempty(a)
    a = ' ';
end

% Get the SHA256 hash of the string as 4 UINT64s.
h = matlab.internal.crypto.SecureDigester("SHA256").computeDigest(a);
q = typecast(h,'uint64');

% Use the zero-padded base 10 representation of the first UINT64.
t = sprintf('%lu',q(1));
nmax = numel(sprintf('%lu',intmax('uint64')));
s = ['eq' repmat('0',1,nmax-numel(t)) t];
