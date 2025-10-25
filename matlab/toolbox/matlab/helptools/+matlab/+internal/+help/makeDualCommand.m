function dualCommand = makeDualCommand(command, varargin)
    args = string(varargin);
    if command == "help"
        args(end+1) = '-displayBanner';
    end
    
    if contains(command,'.') || anyInvalidDualArguments(args)
        args = join(cellfun(@mat2str, args, 'UniformOutput', false), ", ");
        dualCommand = sprintf('%s(%s)', command, args{1});
    else
        dualCommand = char(join([command, args], " "));
    end
end

function b = anyInvalidDualArguments(args)
    persistent invalidStart;
    persistent invalidContains;
    persistent requiredContains;
    if isempty(invalidStart)
        invalidStart     = "(";
        invalidContains  = whitespacePattern | "'" | '"' | "," | ";" | "%";
        requiredContains = alphanumericsPattern;
    end
    b = any(args.startsWith(invalidStart) | args.contains(invalidContains) | ~args.contains(requiredContains));
end

%   Copyright 2007-2023 The MathWorks, Inc.
