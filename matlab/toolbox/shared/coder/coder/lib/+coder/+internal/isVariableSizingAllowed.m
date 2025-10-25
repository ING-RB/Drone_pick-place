function tf = isVariableSizingAllowed()
%#codegen

%   Copyright 2023 The MathWorks, Inc.

coder.inline('always');

if coder.target('MATLAB')
	tf = true;
	return;
end

tf = coder.internal.eml_option_eq('VariableSizing', 'Enable');

end
