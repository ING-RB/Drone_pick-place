classdef (Sealed) withtol < matlab.internal.coder.tabular.private.subscripter  %#codegen
%WITHTOL Timetable row subscripting by time with tolerance.
%   S = WITHTOL(ROWTIMES,TOL) creates a subscript to select rows of a
%   timetable. S selects all rows whose times match a time in ROWTIMES
%   within the tolerance specified by TOL. ROWTIMES is a datetime or
%   duration vector, depending on the timetable that S will be used to
%   subscript into. ROWTIMES may also be a cell array of date/time
%   character vectors or string array as accepted by DATETIME or DURATION.
%   TOL is a non-negative tolerance specified as a duration.
%
%   Examples:
%
%   % Select the numeric variables in a timetable.
%   time = hours(1:10)' + seconds(randn(10,1));
%   tt = array2timetable(randn(10,3),'RowTimes',time)
%   wt = withtol(hours(3:8),seconds(5))
%   ttNumeric = tt(wt,:)
%
%   See also TIMERANGE, VARTYPE.

%   Copyright 2019-2023 The MathWorks, Inc.
    
    properties(Access='protected')
        subscriptTimes = NaT; % sorted datetime/duration vector used for matching
        tol = duration(NaN,0,0); % scalar duration for matching tolerance
    end
    
    properties(Access='private')
        matchTimeZone  = false;
    end
    
    methods
        % Constructor adds an extra, unused input so error handling catches
        % the common mistake of passing in a timetable as a leading input.
        % Otherwise, front-end would throw "Too many input arguments".        
        function obj = withtol(subscriptTimes,tol,~)
            
            if nargin==0
                return;
            end
            
            % common error: withtol(tt,subscriptTimes,tol)
            coder.internal.errorIf(istabular(subscriptTimes), ... 
                'MATLAB:withtol:TabularInput');
            
            % Enforce 2-input in other cases
            narginchk(2,2);
                        
            % Make sure that subscriptTimes are datetime/duration, and tol is duration
            % character vector or a cell array of character vectors are
            % not supported 
            coder.internal.errorIf(matlab.internal.coder.datatypes.isText(subscriptTimes), ...
                'MATLAB:withtol:TextInputsNotSupported');      
            % not enforcing shape - will be indiscriminately columnize below
            coder.internal.assert(isa(subscriptTimes, 'datetime') || ...
                isa(subscriptTimes, 'duration'), 'MATLAB:timetable:InvalidTimes');

            % text is not supported
            coder.internal.errorIf(matlab.internal.coder.datatypes.isScalarText(tol), ...
                'MATLAB:withtol:TextInputsNotSupported'); 

            % check for not-less-than rather than greater-than-or-equal, so
            % NaNs won't throw
            coder.internal.assert(coder.internal.isConst(size(tol)) && isscalar(tol) ...
                && isa(tol, 'duration') && ~(tol < 0), 'MATLAB:withtol:InvalidTolerance');

            % Forbid the case when tolerance exceeds the smallest half-interval in 
            % subscript times (which might result in duplicated data)
            % Do the math in doubles for now due to lack of some math
            % support in duration
            if numel(subscriptTimes) > 1
                maxTol = min(diff(unique(reshape(subscriptTimes,[],1)))/2);
                coder.internal.errorIf(tol >= maxTol, 'MATLAB:withtol:LargeToleranceCodegen');
            end
            
            obj.subscriptTimes = subscriptTimes(:); % columnize the times
            obj.tol = tol; % scalar duration
        end
    end
    
    methods(Access={?matlab.internal.coder.timerange, ?matlab.internal.coder.withtol, ...
            ?matlab.internal.coder.tabular.private.tabularDimension, ...
            ?matlab.internal.coder.tabular})
        % The getSubscripts method is called by timetable subscripting to find the
        % indices of the times (if any) along that dimension that match the given
        % times within the given tolerance
        function subs = getSubscripts(obj,subscripter)
            % Only timetable subscripting is supported. WITHTOL is used in a
            % non-timetable context if subscripter is not a rowTimesDim
            coder.internal.assert(isa(subscripter,'matlab.internal.coder.tabular.private.rowTimesDim'), ...
                'MATLAB:withtol:InvalidSubscripter');
            
            rowTimes  = subscripter.labels;
            subsTimes = obj.subscriptTimes;
            coder.internal.assert(isequal(class(rowTimes),class(subsTimes)), ...
                'MATLAB:withtol:MismatchRowTimesType', class(rowTimes), class(subsTimes));
            
            % Make a list of rowTimes that match each of subscriptTimes. timetable
            % rowTimes is always a column vector, and subscriptTimes is columnized at
            % construction. Thus subscripts return should also always be a column
            % vector.
            locs = timesubs2inds(subsTimes,rowTimes,obj.tol); % dispatch to datetime or duration
            
            % Each row of locs says which subscript (1st col) matched which row of the
            % timetable (2nd col), with zero in 2nd col indicating no match for that subscript.
            % Unlike rowTimesDim, withtol's caller doesn't care what the original subscripts were,
            % only which rows of the timetable were matched, so we can throw away the 1st col.
            % And withtol does not create new rows, so we can throw away non-matches.
            subs = locs(:,2); % timetable row indices
            subs = subs(subs>0); % remove non-matches.
        end
    end
    
    methods(Hidden, Static)
        function out = matlabCodegenFromRedirected(wt)
            out = withtol(wt.subscriptTimes, wt.tol);
        end
        
        function out = matlabCodegenToRedirected(wt)
            out = matlab.internal.coder.withtol(wt.subscriptTimes, wt.tol);
        end
    end
    
    methods(Hidden, Static)
        function name = matlabCodegenUserReadableName
            % Make this look like a withtol (not the redirected withtol) in the codegen report
            name = 'withtol';
        end
    end
end
