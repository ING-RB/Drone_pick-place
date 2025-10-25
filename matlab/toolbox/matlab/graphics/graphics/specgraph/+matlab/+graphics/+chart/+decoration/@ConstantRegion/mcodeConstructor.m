function mcodeConstructor(hObj, code)
% Generate code to recreate the constant region.

% Copyright 2022 The MathWorks, Inc.

switch hObj.InterceptAxis
    case 'x'
        setConstructorName(code, 'xregion')
    case 'y'
        setConstructorName(code, 'yregion')
end

ignoreProperty(code, 'InterceptAxis');

arg1 = codegen.codeargument('Name', 'value1', 'Value', hObj.Value(1), ...
    'IsParameter', false);
addConstructorArgin(code, arg1);

arg2 = codegen.codeargument('Name', 'value2', 'Value', hObj.Value(2), ...
    'IsParameter', false);
addConstructorArgin(code, arg2);

ignoreProperty(code, 'Value');

generateDefaultPropValueSyntax(code);
end