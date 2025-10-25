function controlIdentLaunchDocPage(filterType)
%controlIdentLaunchDocPage Launch the doc for filter defined by filterType.
%
% The page depends on the available toolboxes. These blocks are available both
% in control and ident.

%   Copyright 2016-2024 The MathWorks, Inc.

if ~isempty(ver('control')) && license('test','Control_Toolbox')
   prod = 'control';
else
   prod = 'ident';
end
switch filterType
   case 'EKF'
      helpview(prod, 'ctrl_ekf_block');
   case 'UKF'
      helpview(prod, 'ctrl_ukf_block');
   case 'PF'
      helpview(prod, 'ctrl_pf_block');
   otherwise
      assert(false, 'Help topic not found.');
end
end
