function M = movsum(A,k,varargin)
% Syntax:
%     M = movsum(A,k)
%     M = movsum(A,[kb kf])
%     M = movsum(___,nanflag)
%     M = movsum(___,Name=Value)
%
%     Name-Value Arguments:
%         DataVariables
%         EndPoints
%         RelaceValues
%         SamplePoints
%
% For more information, see documentation

%   Copyright 2024-2025 The MathWorks, Inc.

if ~isduration(k) && ~istabular(A)
    try
        M = matlab.internal.math.movsum(A,k,varargin{:});
    catch ME
        if matches(ME.identifier,["MATLAB:movfun:SamplePointsInvalidDatatype" "MATLAB:movfun:wrongWindowLength"])
            % Error conditions not handled by the builtin: non-time k with
            % time sample points and datetime k
            for ii = 1:(numel(varargin) - 1)
                if matlab.internal.math.checkInputName(varargin{ii},"SamplePoints")
                    sp = varargin{ii+1};
                    if isdatetime(sp)
                        error(message('MATLAB:movfun:winsizeNotDuration','datetime'));
                    elseif isduration(sp)
                        if isequal(ME.identifier,"MATLAB:movfun:wrongWindowLength")
                            throw(ME);
                        end
                        error(message('MATLAB:movfun:winsizeNotDuration','duration'));
                    end
                end
            end
        end
        throw(ME);
    end
else
    hasBiasOption = false;
    omitNaNByDefault = false;
    M = matlab.internal.math.applyMovFun("movsum", @matlab.internal.math.movsumInternal, hasBiasOption, omitNaNByDefault, A, k, varargin{:});
end