function setMultipleFigureFlag(option)
% setMultipleFigureFlag maintain state for multiple figures 
%   Used by the deploywed webapps during prewarning for creating 
%   figure and clear the flag after prewarming 

  % check for uifigure calls beyond the first one
  persistent block;
  
  % clear the block value 
  if nargin > 0 && ischar(option) && strcmp(option,'clear')
     block = [];
     return
  end
  
  if ~isempty(block)
    matlab.ui.internal.NotSupportedInWebAppServer('multiwindow apps');
    return
  end
  
  % set the flag to true to block multiple figures
  block = true;
end

