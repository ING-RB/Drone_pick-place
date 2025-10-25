function varargout = centerfig(F1,F2)
%CENTERFIG  Position figure F1 centered with respect to figure F2.
%
%   CENTERFIG is used to center a window (F1) with respect to another
%   window (F2) or the root window.  F1 must be a valid MATLAB figure
%   window or Java frame.  F2 must be a valid MATLAB figure window or the
%   root window.
%
%   CENTERFIG(F1,F2) centers figure F1 with respect to figure F2
%
%   CENTERFIG(F1,0)  centers figure F1 with respect to the screen
%
%   CENTERFIG(F1)    centers figure F1 with respect to the screen
%
%   CENTERFIG        centers the current figure with respect to the screen

%   Author(s): A. DiVergilio
%   Copyright 1986-2013 The MathWorks, Inc.

%---Defaults
if nargin<2, F2 = 0; end
if nargin<1, F1 = gcf; end

xy = localPlaceHGFig(F1,F2);


%---Return xy position if requested
if nargout, varargout{1}=xy; end


%%%%%%%%%%%%%%%%%%%
% localPlaceHGFig %
%%%%%%%%%%%%%%%%%%%
function xy = localPlaceHGFig(F1,F2)
% Place HG figure F1 within bounds of HG figure F2 (F2 may be root)

 %---Fieldname of F2 which contains its position
  if F2==0
     Property = 'ScreenSize';
  else
     Property = 'Position';
  end

 %---Get F2 position in pixels
  f2u = get(F2,'Units');
  if ~strcmpi(f2u,'pixels')
     set(F2,'Units','pixels');
     f2p = get(F2,Property);
     set(F2,'Units',f2u);
  else
     f2p = get(F2,Property);
  end

 %---Set F1 position
  f1u = get(F1,'Units');
  if ~strcmpi(f1u,'pixels')
     set(F1,'Units','pixels');
     f1p = get(F1,'Position');
     xy = [f2p(1)+(f2p(3)-f1p(3))/2 f2p(2)+(f2p(4)-f1p(4))/2];
     set(F1,'Position',[xy f1p(3:4)]);
     set(F1,'Units',f1u);
  else
     f1p = get(F1,'Position');
     xy = [f2p(1)+(f2p(3)-f1p(3))/2 f2p(2)+(f2p(4)-f1p(4))/2];
     set(F1,'Position',[xy f1p(3:4)]);
  end
