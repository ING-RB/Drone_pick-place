function hcl = xyzline(varargin)
%This undocumented function may be removed in a future release.

%This function is a middle layer between the convenience function: xline, 
%and yline. It returns a handle to a ConstantLine object.

%   Copyright 2018-2023 The MathWorks, Inc.
import matlab.graphics.chart.internal.inputparsingutils.peelFirstArgParent
import matlab.graphics.chart.internal.inputparsingutils.splitPositionalFromPV
import matlab.graphics.chart.internal.inputparsingutils.getParent

    %Separate user's input from 'x' and 'y'
    args = varargin{2};
    axis = varargin{1};

    [parentAxes, args] = peelFirstArgParent(args);
    [posargs, pvpairs] = splitPositionalFromPV(args, 1, true);
    [parentAxes, hasParent] = getParent(parentAxes, pvpairs, 2);
    
    ex = validateData(posargs{1});
    if ~isempty(ex)
        throwAsCaller(ex);
    end
    
    val = posargs{1};
    numVals = numel(val);
    hcl = gobjects(numVals, 1);
    
    % Grab all the arguments that aren't Value.
    args = args(2:end);
    
    % Vectorized Labels 
    labelsAreVectorized = false;

    if ~isempty(args)
        try
            % Putting this in a try block since passing in vectorized
            % Labels in cell array will cause this to throw an unhelpful
            % error to the user. 
            [L, C, M, MSG] = colstyle(args{1});
        catch
            throwAsCaller(MException(message('MATLAB:colstyle:InvalidLinespec')));
        end
        if ~isempty(M)
            w = warning('off', 'backtrace');
            c = onCleanup(@() warning(w));
            warning(message('MATLAB:graphics:constantline:IgnoredMarker'));
        end
        
        if (mod(numel(args),2) == 1 && isempty(MSG))
            % If there's an odd number of inputs afterwards, only the
            % LineSpec was provided
            args = [parseLineStyle(L,C) args(2:end)];
            
        elseif (isempty(MSG))
            % If there's an even number of inputs afterwards, assume both
            % the LineSpec and Label were provided. 
            % Save the vectorized Labels during object creation.
            if (iscell(args{2}) || isstring(args{2})) && numel(args{2}) > 1
                if numel(args{2}) == numVals
                    % Make sure there are the same number of Labels as
                    % there are Values passed in. 
                    labelsAreVectorized = true;
                    labelOfVectors = args{2};
                    args = [parseLineStyle(L,C) args(3:end)];
                elseif numVals == 1
                    args = [parseLineStyle(L,C) 'Label', args(2:end)];
                else
                    throwAsCaller(MException(message('MATLAB:graphics:constantline:LabelsMismatchNumberOfValues')));
                end
            else
                args = [parseLineStyle(L,C) 'Label', args(2:end)];
            end
        end
    end

    if ~hasParent
        parentAxes = gca;
    end

    if isa(parentAxes, 'matlab.graphics.axis.Axes')
        switch axis
            case 'x'
                matlab.graphics.internal.configureAxes(parentAxes,val,parentAxes.YLim(1))
            case 'y'
                matlab.graphics.internal.configureAxes(parentAxes,parentAxes.XLim(1),val)
        end
    end

    % Create ConstantLine object(s). 
    try
        for i = 1:numVals
            if labelsAreVectorized
                if iscell(labelOfVectors{i})
                    % User passes in nested cellstr for labels. 
                    tempArgs = [{'Label'}, labelOfVectors(i), args];
                else
                    tempArgs = [{'Label'}, labelOfVectors{i}, args];
                end
            else
                tempArgs = args;
            end
            hcl(i) = matlab.graphics.chart.decoration.ConstantLine('Parent', parentAxes, 'InterceptAxis', axis, 'Value', val(i), tempArgs{:});
        end
        
    catch e
        throwAsCaller(e);
    end
end

%Helps parse which arguments of linestyle are valid. Ensures to weed out
%the marker property
function addLS = parseLineStyle(L, C) 
    addLS = {};
    if(~isempty(L))
       addLS = [addLS 'LineStyle', L]; 
    end
    
    if(~isempty(C))
        addLS = [addLS 'Color', C];
    end
end

function ex = validateData(data)
    ex = MException.empty;
    if isempty(data)
        ex = MException(message('MATLAB:graphics:constantline:EmptyValueInput'));
    elseif ~isvector(data)
        ex = MException(message('MATLAB:graphics:constantline:MatrixOfValues'));
    elseif ~(isnumeric(data) || isdatetime(data) || iscategorical(data) || isduration(data))
        ex = MException(message('MATLAB:graphics:constantline:InvalidData'));
    elseif isnumeric(data) && ~isreal(data)
        ex = MException(message('MATLAB:graphics:constantline:ComplexValue','Value'));
    end
end