function r = plot(this,w,varargin)
%PLOT  Adds data to a spectrum plot.
%
%   R = PLOT(PLOT,W,M) adds the spectrum data (W,M) to the Spectrum plot
%   PLOT.  W is the frequency vector, and M is the magnitude arrays (the
%   size of their first dimension must match the number of frequencies).
%   The added response is drawn immediately.
%
%   R = PLOT(BODEPLOT,W,M,'Property1',Value1,...) further specifies
%   data properties such as units. See the @magphasedata class for a list
%   of valid properties.
%
%   R = PLOT(BODEPLOT,...,'nodraw') defers drawing.  An explicit call to
%   DRAW is then required to show the new response.  This option is useful
%   to render multiple responses all at once.

%  Copyright 2011 The MathWorks, Inc.

ni = nargin;
if ni<3
   ctrlMsgUtils.error('Controllib:general:ThreeOrMoreInputsRequired', ...
      'resppack.noisespectrumplot/plot','resppack.noisespectrumplot/plot');
end

% Look for 'nodraw' flag
nargs = length(varargin);
varargin(strcmpi(varargin,'nodraw')) = [];
DrawFlag = (length(varargin)==nargs);

% Check data
% Frequency
if ~isreal(w)
   ctrlMsgUtils.error('Controllib:plots:Plot1','resppack.noisespectrumplot/plot')
end
w = w(:);
nf = length(w);
% Complex frequency response
m = varargin{1};
varargin = varargin(2:end);
if numel(m)==nf
   m = m(:);
end
% Size checking
if size(m,1)~=nf && size(m,3)==nf
   % Accept frequency-last format
   m = permute(m,[3 1 2]);
end
[nf2,ny,nu] = size(m);
if nf2~=nf
   ctrlMsgUtils.error('Controllib:plots:Plot2','plot(NOISESPECTRUMPLOT,W,M)','W','M')
elseif ~isreal(m)
   ctrlMsgUtils.error('Controllib:plots:Plot3','plot(NOISESPECTRUMPLOT,W,M)','M')
end

% Create new response
try
   r = this.addresponse(1:ny,1:nu,1);
catch ME
   throw(ME)
end

% Store data and set properties
r.Data.Frequency = w;
r.Data.Magnitude = m;
if nf>0
   r.Data.Focus = [w(1) w(end)];
end
if ~isempty(varargin)
   set(r.Data,varargin{:})
end

% Draw new response
if DrawFlag
   draw(r)
end
