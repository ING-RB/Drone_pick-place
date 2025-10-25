function display(this)
%DISPLAY Display method for @PlotOptions

%  Author(s): C. Buhr
%  Copyright 1986-2011 The MathWorks, Inc.

% Display inputname
InputName = inputname(1);
if isempty(InputName)
   InputName = 'ans';
end
fprintf('\n%s =\n\n',InputName)

if numel(this)>1
   % Array of Plot Options
   s = sprintf('%dx',size(this));
   fprintf('	%s: %s\n\n',class(this),s(1:end-1))
else
   % Single Plot Options
   % Display data
   disp(get(this))
end
