function r = plot(this,hsv,varargin)
%PLOT  Adds data to a response plot.
%
%   R = PLOT(HSVPLOT,HSV) adds the Hankel singular value data HSV
%   to the pole/zero plot HSVPLOT.  The response is drawn immediately.
%
%   R = PLOT(HSVPLOT,HSV,'nodraw') defers drawing.  An explicit 
%   call to DRAW is then required to show the new response.  This 
%   option is useful to render multiple responses all at once.

%  Copyright 1986-2014 The MathWorks, Inc.
narginchk(2,3)

% Check data
if ~isvector(hsv) || ~isreal(hsv) || any(hsv<0)
    ctrlMsgUtils.error('Controllib:plots:Plot4','resppack.hsvplot/plot')
end
hsv = hsv(:);

% Create new response
try
   r = this.addresponse;
catch ME
   throw(ME)
end

% Store data and set properties
r.Data.HSV = hsv;

% Draw new response
if nargin<3
   draw(r)
end