function str = createClassNameForCommandWindow(name)
% This function is undocumented.

%  Copyright 2012-2018 The MathWorks, Inc.

import matlab.unittest.internal.diagnostics.BoldableString;
import matlab.unittest.internal.diagnostics.CommandHyperlinkableString;
import matlab.unittest.internal.getSimpleParentName;

str = BoldableString(CommandHyperlinkableString(getSimpleParentName(name), ['helpPopup ', name]));

% LocalWords:  Hyperlinkable
