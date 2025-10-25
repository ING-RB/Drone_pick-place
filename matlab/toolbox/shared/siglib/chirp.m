function y = chirp(t,varargin)
%CHIRP Swept-frequency cosine generator
%   Y = CHIRP(T) generates samples of a swept-frequency signal at the time 
%   instances defined in array T. By default, the instantaneous frequency
%   at time 0 is 0, and the instantaneous frequency one second later is 100
%   Hz.    
%
%   Y = CHIRP(T,F0,T1,F1) generates samples of a linear swept-frequency
%   signal at the time instances defined in array T. The instantaneous 
%   frequency at time 0 is F0 Hz. The instantaneous frequency F1 is 
%   achieved at time T1.
%
%   Y = CHIRP(T,F0,T1,F1,method) specifies alternate sweep methods.
%   Available methods are "linear", "quadratic", and "logarithmic"; the
%   default is "linear". For a logarithmic sweep, F0 must be greater than
%   or equal to 1e-6 Hz, which is also the default value.
%
%   Y = CHIRP(T,F0,T1,F1,method,PHI) specifies an initial phase PHI in 
%   degrees. By default, PHI = 0.
%
%   Y = CHIRP(T,FO,T1,F1,"quadratic",PHI,"concave") generates samples of a
%   quadratic swept-frequency chirp signal whose spectrogram is a parabola 
%   with its concavity in the positive frequency axis.
%
%   Y = CHIRP(T,FO,T1,F1,"quadratic",PHI,"convex") generates samples of a
%   quadratic swept-frequency signal whose spectrogram is a parabola with
%   its convexity in the positive frequency axis.
%   
%   Y = CHIRP(...,sigtype) specifies sigtype as "real" or "complex"; the 
%   default is "real". When sigtype is set to "real", CHIRP generates real  
%   chirp signals. When set to "complex", CHIRP generates complex chirp 
%   signals. 
%
%   Example: Compute the spectrogram of a linear chirp.
%     t = 0:0.001:2;                    % 2 s at 1 kHz sample rate
%     y = chirp(t,0,1,150);             % Start at DC, cross 150 Hz at 
%                                       % t = 1 s
%     spectrogram(y,256,250,256,1E3);   % Display the spectrogram
%
%   Example: Compute the spectrogram of a quadratic chirp.
%     t = -2:0.001:2;                   % +/-2 s at 1 kHz sample rate
%     y = chirp(t,100,1,200,"quadratic");       % Start at 100 Hz, cross 200 Hz at
%                                       % t = 1 s
%     spectrogram(y,128,120,128,1E3);   % Display the spectrogram
%
%   Example: Compute the spectrogram of a convex quadratic chirp
%     t = 0:0.001:1;                    % 1 s at 1 kHz sample rate
%     fo = 25;                          % Start at 25 Hz,
%     f1 = 100;                         % go up to 100 Hz
%     y = chirp(t,fo,1,f1,"quadratic",[],"convex");
%     spectrogram(y,256,200,256,1000);  % Display the spectrogram.
%
%   Example: Compute the spectrogram of a concave quadratic chirp
%     t = 0:0.001:1;                    % 1 s at 1 kHz sample rate
%     fo = 100;                         % Start at 100 Hz,
%     f1 = 25;                          % go down to 25 Hz
%     y = chirp(t,fo,1,f1,"quadratic",[],"concave");
%     spectrogram(y,256,200,256,1000);  % Display the spectrogram.
%
%   Example: Compute the spectrogram of a logarithmic chirp
%     t = 0:0.001:10;                   % 10 s at 1 kHz sample rate
%     fo = 10;                          % Start at 10 Hz,
%     f1 = 400;                         % go up to 400 Hz
%     y = chirp(t,fo,10,f1,"logarithmic");
%     spectrogram(y,256,200,256,1000);  % Display the spectrogram
%
%   Example: Compute a complex-valued linear chirp
%     t = 0:0.001:2;                    % 2 s at 1 kHz sample rate
%     fo = -50;                         % Start at -50 Hz,
%     t1 = 1;
%     f1 = 200;                         % cross 200 Hz at t = 1 s
%     y = chirp(t,fo,t1,f1,"complex"); 
%     spectrogram(y,256,200,256,1000,"centered"); % Display the spectrogram
%
%   See also GAUSPULS, SAWTOOTH, SINC, SQUARE.

%   Copyright 1988-2023 The MathWorks, Inc.

%   References:
%   [1] Agilent 33220A 20 MHz Function/Arbitrary Waveform Generator
%       Users Guide, Agilent Technologies, March 2002, pg 298

%#codegen

narginchk(1,8);
validateattributes(t,{'double','single'},{'real','finite'},'chirp','t',1);
dtProto = ones(1,1,"like",t); % data type prototype

% Parse inputs
params = internal.chirp.ChirpParser(dtProto,varargin{:});

f0 = params.f0;
t1 = params.t1;
f1 = params.f1;
phi = params.phi;
isOutputComplex = params.isOutputComplex;
CONST = params.CONST;

% Initializing output variable
y = coder.nullcopy(zeros(size(t),"like",params.outputDataType));

% Computing the signal according to method
switch params.sweepMethod
    case 'polynomial'
        % Polynomial chirp
        y = cos(CONST.cast2Pi*polyval(polyint(f0),t));
        
    case 'linear'
        % Linear chirp
        y = calculateChirp(t,f0,f1,t1,CONST.cast1,phi,isOutputComplex,CONST);
        
    case 'quadratic'
        % Compute the quadratic chirp output based on quadtype
        
        % Compute the quadratic chirp (upsweep or downsweep) for
        % complex or concave modes.
        
        % For the default 'concave-upsweep' and 'convex-downsweep' modes
        % call calculateChirp without any changes to the input parameters.
        % For the forced 'convex-upsweep' and 'concave-downsweep' call
        % calculateChirp with f0 and f1 swapped and t = fliplr(-t)
        
        % For 'convex-upsweep' and 'concave-downsweep' modes
        f0 = params.f0;
        f1 = params.f1;
        quadtype = params.quadraticType;
        if ((f0(1) < f1) && strcmp(quadtype,'convex') || ((f0(1) > f1) && strcmp(quadtype,'concave')))
            t = fliplr(-t);
            f0temp = f1;
            f1temp = f0(1);
        else
            f0temp = f0(1);
            f1temp = f1;
        end
        y = calculateChirp(t,f0temp,f1temp,t1,CONST.cast2,phi,isOutputComplex,CONST);
        
    case 'logarithmic'
        % Logarithmic chirp
        tempVector = (f1/f0).^(t./t1);
        instPhi = (t1/log(f1/f0)*f0)*(tempVector-CONST.cast1);
        if (isOutputComplex)
            y = exp(CONST.cast1I*CONST.cast2Pi*phi/CONST.cast360).*complex(cos(CONST.cast2Pi*instPhi),-cos(CONST.cast2Pi*(instPhi+CONST.cast0p25)));
        else
            y = cos(CONST.cast2Pi*(instPhi+phi/CONST.cast360));
        end
end

end

%---------------------------------------------------------------------------
function yvalue = calculateChirp(t,f0,f1,t1,p,phi,isComplex,CONST)
% General function to compute beta and y for both linear and quadratic
% modes. p is the polynomial order (1 for linear and 2 for quadratic)
coder.internal.prefer_const(isComplex);
coder.noImplicitExpansionInFunction; % To prevent implicit expansion branch for h1

beta = (f1-f0).*(t1.^(-p));

x1 = beta./(CONST.cast1+p)*(t.^(CONST.cast1+p))+f0*t;
if (isComplex)
    yvalue = exp(CONST.cast1I*CONST.cast2Pi*phi/CONST.cast360).*complex(cos(CONST.cast2Pi*(x1)),-cos(CONST.cast2Pi*(x1+CONST.cast0p25)));
else
    yvalue = cos(CONST.cast2Pi*(x1+phi/CONST.cast360));
end

end

% [EOF] chirp.m

% LocalWords:  FO fo Agilent quadtype upsweep downsweep PARSEOPTARGS siglib