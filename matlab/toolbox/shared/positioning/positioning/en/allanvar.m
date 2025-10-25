%ALLANVAR Allan variance.
%   [Y, TAU] = ALLANVAR(OMEGA) returns the Allan variance Y of the vector
%   OMEGA at each octave TAU = (1, 2, ..., 2^floor(log2((N-1)/2))). N
%   is the number of elements in OMEGA. If OMEGA is a matrix, ALLANVAR
%   operates over the columns of OMEGA.
%   
%   [Y, TAU] = ALLANVAR(OMEGA, M) returns the Allan variance Y of the
%   vector OMEGA at TAU = M. M is a vector with ascending integer values (0
%   < m < (N-1)/2). N is the number of elements in OMEGA.
%   
%   [Y, TAU] = ALLANVAR(OMEGA, PTSTR) returns the Allan variance Y of
%   the values in OMEGA at the values specified by PTSTR. PTSTR is the 
%   point specification string 'octave' or 'decade'. TAU is the following: 
%       PTSTR       | TAU
%       'octave'    | [2^0, 2^1, ..., 2^floor(log2((N-1)/2))]
%       'decade'    | [10^0, 10^1, ..., 10^floor(log10((N-1)/2))]
%   N is the number of elements in OMEGA.
%   
%   [Y, TAU] = ALLANVAR(..., FS) specifies the sampling rate FS in Hz. The 
%   default value is 1.
%
%   Example:
%       % Calculate Allan deviation of random process.
%       numSamples = 1e6;
%       Fs = 100;
%       nStd = 1e-3;
%       kStd = 1e-7;
%       nNoise = nStd .* randn(numSamples, 1);
%       kNoise = kStd .* cumsum(randn(numSamples, 1));
%       omega = nNoise + kNoise;
%       [avar, tau] = allanvar(omega, 'octave', Fs);
%       
%       loglog(tau, sqrt(avar))
%       xlabel('Averaging Time (\tau)')
%       ylabel('\sigma')
%       title('Allan Deviation')
%       grid on
%
%   See also VAR.

 
%   Copyright 2018-2019 The MathWorks, Inc.

