function tf = isMLXFile(file)
%

% Copyright 2022 The MathWorks, Inc.

    arguments
        file {mustBeTextScalar}
    end

    if ~isfile(file)
        tf = false;
        return
    end

    import comparisons.internal.opc.getCoreProperties
    props = comparisons.internal.opc.getCoreProperties(file);
    tf = ~isempty(props) ...
        && strcmp(props.ContentType, 'application/vnd.mathworks.matlab.code');
end
