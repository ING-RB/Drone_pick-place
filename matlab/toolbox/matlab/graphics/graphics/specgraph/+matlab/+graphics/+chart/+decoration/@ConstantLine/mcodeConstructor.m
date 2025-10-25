function mcodeConstructor(hObj, code)
% Generate code to recreate the constant line.

% Copyright 2018 The MathWorks, Inc.

switch hObj.InterceptAxis
    case 'x'
        setConstructorName(code, 'xline')
    case 'y'
        setConstructorName(code, 'yline')
end

ignoreProperty(code, 'InterceptAxis');

arg = codegen.codeargument('Name', 'value', 'Value', hObj.Value, ...
    'IsParameter', false);
addConstructorArgin(code, arg);

ignoreProperty(code, 'Value');

generateDefaultPropValueSyntax(code);
end


