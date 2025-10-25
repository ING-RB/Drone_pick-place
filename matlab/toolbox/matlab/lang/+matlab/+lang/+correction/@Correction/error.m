function error(correction, varargin)
    if nargin > 1 && isEmptyText(varargin{1})
       return;
    end
    addCorrection = true;
    try
        me = MException(varargin{:});
    catch
        if ~isscalar(correction) || ~isa(correction, 'matlab.lang.correction.Correction')
            error(message('MATLAB:SuggestionException:MustBeCorrectionScalar'));
        end
        % Check for valid ERROR syntaxes not supported by MException.
        addCorrection = isMessageStructSyntax(varargin) || isMessageArgumentsSyntax(varargin);
        try
            % Return if ERROR function does not throw.
            builtin('error', varargin{:});
            return;
        catch me
        end
    end
    if addCorrection
        me = me.addCorrection(correction);
    end
    throwAsCaller(me);
end

function tf = isEmptyText(arg)
    tf = (ischar(arg) && isempty(arg)) || (isStringScalar(arg) && strlength(arg) < 1);
end

function tf = isMessageArgumentsSyntax(args)
% ERROR(ERRMSG, V1, V2, ...)
    tf = true;
    try
        sprintf(args{:});
    catch
        tf = false;
    end
end

function tf = isMessageStructSyntax(args)
% ERROR(MSGSTRUCT)
    tf = isscalar(args) && isstruct(args{1});
end

%   Copyright 2019 The MathWorks, Inc.
