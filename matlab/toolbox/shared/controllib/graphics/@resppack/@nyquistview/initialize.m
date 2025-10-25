function initialize(this,Axes)
%INITIALIZE  Initializes @nyquistview graphics.

%   Author(s): P. Gahinet
%   Copyright 1986-2013 The MathWorks, Inc.

% Create Nyquist curves and arrows (Axes = HG axes to which curves are plotted)
[ny,nu] = size(Axes);  % Ny-by-Nu
Curves = repmat(wrfc.createDefaultHandle,[ny,nu]);
PosArrows = repmat(wrfc.createDefaultHandle,[ny,nu]);
NegArrows = repmat(wrfc.createDefaultHandle,[ny,nu]);
for ct=ny*nu:-1:1
   Curves(ct) = handle(line('XData', NaN, 'YData', NaN, ...
      'Parent', Axes(ct), 'Visible', 'off'));
   PosArrows(ct) = handle(patch([NaN NaN NaN],[NaN NaN NaN],'w',...
                    'Parent',Axes(ct),'Visible','off',...
                    'HitTest','off','HandleVisibility','off'));
   NegArrows(ct) = handle(patch([NaN NaN NaN],[NaN NaN NaN],'w',...
                    'Parent',Axes(ct),'Visible','off',...
                    'HitTest','off','HandleVisibility','off'));
end
this.Curves = reshape(Curves,[ny nu]);
this.PosArrows = reshape(PosArrows,[ny nu]);
this.NegArrows = reshape(NegArrows,[ny nu]);
