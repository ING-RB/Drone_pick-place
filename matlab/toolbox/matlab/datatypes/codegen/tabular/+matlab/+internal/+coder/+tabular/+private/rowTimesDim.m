classdef (AllowedSubclasses = {?matlab.internal.coder.tabular.private.explicitRowTimesDim, ...
                               ?matlab.internal.coder.tabular.private.implicitRegularRowTimesDim}) ...
                               rowTimesDim < matlab.internal.coder.tabular.private.tabularDimension %#codegen
%ROWTIMESDIM Internal abstract class to represent a timetable's row dimension.

% This class is for internal use only and will change in a
% future release.  Do not use this class.

    %   Copyright 2019-2022 The MathWorks, Inc.
    
    properties (Constant, GetAccess=public)
        propertyNames = {'RowTimes'; 'StartTime'; 'SampleRate'; 'TimeStep'};
        requireLabels = true;
        requireUniqueLabels = false;
        constantLabels = false;
        DuplicateLabelExceptionID = ''; % No exception: requireUniqueLabels is FALSE
        NumDimNamesExeptionID = 'MATLAB:timetable:IncorrectNumberOfRowTimes';
        UnrecognizedLabelExceptionID = ''; % rowTimesDim returns an empty result instead
        UnrecognizedAssignmentLabelExceptionID = ''; % rowTimesDim returns an empty result instead
        NonconstantLabelExceptionID = ''; % rowTimesDim returns an empty result instead
        NonconstantAssignmentLabelExceptionID = ''; % rowTimesDim returns an empty result instead
        IndexOutOfRangeExceptionID = 'MATLAB:table:RowIndexOutOfRange';
        AssignmentOutOfRangeExceptionID = 'MATLAB:table:AssignmentRowIndexOutOfRange';
        InvalidSubscriptsExceptionID = ''; % rowTimesDim throws InvalidRowSubscriptsDatetime/Duration instead
        InvalidLabelExceptionID = '';  % rowTimesDim throws InvalidRowSubscriptsDatetime/Duration instead
        IncorrectNumberOfLabelsExceptionID = 'MATLAB:timetable:IncorrectNumberOfRowTimes';
    end
       
    properties(Dependent)
        hasLabels
    end
    
    properties (Abstract, GetAccess=public, SetAccess=protected)
        startTime    % as datetime or duration
        sampleRate   % in hz
        timeStep     % as duration or calendarDuration
    end
    methods (Abstract)
        % These are effectively set.XXX methods, but implicitRegularRowTimesDim
        % needs setTimeStep and setSampleRate to set each others' properties,
        % and explicitRowTimesDim needs them to return a different class.
        obj = setStartTime(obj,startTime)
        obj = setTimeStep(obj,timeStep)
        obj = setSampleRate(obj,sampleRate)
    end
    
    methods(Abstract, Access = {?matlab.internal.coder.tabular,...
                                ?matlab.internal.coder.tabular.private.rowTimesDim})
        tf = isSpecifiedAsRate(obj);
    end
    
    %===========================================================================
    methods        
        function tf = get.hasLabels(~)
            tf = true;
        end
        
        %-----------------------------------------------------------------------
        
        function tf = isequal(obj1,obj2,varargin)
            % The row times is the only property that really matters for comparison,
            % but the inputs might be different rowTimesDim subclasses with
            % different representations for the row times. Let the subclasses
            % decide how to compare.
            % Compare the first two inputs' row times.
            tf = obj1.areRowTimesEqual(obj2);
            for i = 2:length(varargin)
                % Compare the first input's row times to those of each remaining input.
                tf = tf && obj1.areRowTimesEqual(varargin{i});
            end
        end
        function tf = isequaln(obj1,obj2,varargin)
            % See isequal.
            tf = obj1.areRowTimesEqualn(obj2);
            for i = 2:length(varargin)
                tf = tf && obj1.areRowTimesEqualn(varargin{i});
            end
        end
                
        %-----------------------------------------------------------------------
        function labels = defaultLabels(obj,indices)
            % DEFAULTLABELS Return a vector of default labels of the right kind.
            template = obj.rowTimesTemplate();
            if nargin < 2
                len = obj.length;
            else
                len = length(indices);
            end
            if isa(template,'datetime')
                % We can't use datetime.fromMillis here since it doesn't preserve the
                % default format (i.e. template.fmt == '').
                labels = matlab.internal.coder.datatypes.defaultarrayLike(len,1,'Like',template);
            else
                labels = duration.fromMillis(NaN(len,1),template.Format);
            end
        end
        
        %-----------------------------------------------------------------------
        
        function [indices,numIndices,maxIndex,isLiteralColon,isLabels,updatedObj] ...
                     = subs2inds(obj,subscripts,subsType)
            %SUBS2INDS Convert table subscripts (labels, logical, numeric) to indices.
            if nargin < 3, subsType = obj.subsType.reference; end
            
                % Let the superclass handle the real work.
            if nargout > 5
                [indices,numIndices,maxIndex,isLiteralColon,isLabels,updatedObj] = ...
                    obj.subs2inds@matlab.internal.coder.tabular.private.tabularDimension(subscripts,subsType);
            else
                [indices,numIndices,maxIndex,isLiteralColon,isLabels] = ...
                    obj.subs2inds@matlab.internal.coder.tabular.private.tabularDimension(subscripts,subsType);
            end
        end
    end
    
    methods (Access={?matlab.internal.coder.tabular.private.tabularDimension})
        function obj = makeUniqueForRepeatedIndices(obj,~,~)
            % Row times do not need to be unique
        end
    end
    
    %===========================================================================
    methods (Abstract)
        [tf,dt] = isregular(obj,unit)
        template = rowTimesTemplate(obj)
        rowSubscript = timerange2subs(leftEndPoint,rightEndPoint,intervalType)
        rowtimes = createExtendedRowTimes(obj,len)
    end
    
    %===========================================================================
    methods (Abstract, Access=protected)
        tf = areRowTimesEqual(obj1,obj2)
        tf = areRowTimesEqualn(obj1,obj2)
    end
    
    %===========================================================================
    methods (Static)
        function rowtimes = regularRowTimesFromTimeStep(startTime,timeStep,len,indices)
            % This is correct for both duration and calendarDuration time step,
            % as long as the calendarDuration is "pure", i.e. only one unit.
            if nargin < 4
                steps = (0:len-1)';
            else
                steps = indices - 1; % 1-based -> 0-based
            end
            rowtimes = startTime + steps(:)*timeStep;
            
            % Overwrite the NaN that 0*NaN or 0*Inf for a non-finite time step
            % would put at step == 0.
            if ~isempty(rowtimes)
                if nargin < 4
                    rowtimes(1) = startTime;
                else
                    rowtimes(steps==0) = startTime;
                end
            end
        end

        function rowtimes = regularRowTimesFromSampleRate(startTime,sampleRate,len,indices)
            if nargin < 4
                steps = (0:len-1)';
            else
                steps = indices - 1; % 1-based -> 0-based
            end
            rowtimes = startTime + milliseconds(steps(:))*1000/sampleRate;
            
            % Overwrite the NaN that 0/NaN or 0/0 for a NaN or zero sample rate
            % would put at step == 0.
            if ~isempty(rowtimes)
                if nargin < 4
                    rowtimes(1) = startTime;
                else
                    rowtimes(steps==0) = startTime;
                end
            end
        end
    end
    
    %===========================================================================
    methods (Static, Access=protected)
        function [tf,dt] = isRegularRowTimes(rowTimes)
            % Determine if the specified time vector is regular with respect to
            % some time unit.
            if isa(rowTimes,'duration')
                % durations can only be regular w.r.t. time.
                [tf,dt] = matlab.internal.coder.datetime.isRegularTimeVector(rowTimes,'time');
            elseif length(rowTimes) < 2
                % TODO: datetime not yet supported
                % Let isRegularTimeVector decide the right answer for empty/scalar.
                [tf,dt] = matlab.internal.coder.datetime.isRegularTimeVector(rowTimes,'time');
            else
                % TODO: datetime not yet supported
                % Use t(2)-t(1) as a rough check of the possibilities.
                dt0 = abs(days(diff(rowTimes(1:2))));
                if dt0 < 1
                    % If the first difference is less than 1 (standard) day, the times
                    % are either regular w.r.t. time or not regular, but they can't be
                    % regular w.r.t. (calendar) days or months.
                    [tf,dt] = matlab.internal.coder.datetime.isRegularTimeVector(rowTimes,'time');
                elseif dt0 < 28
                    % If the first difference is less than 28 (standard) days, the
                    % times are either regular w.r.t. (calendar) days or time or not
                    % regular, but they can't be regular w.r.t. months. Start by
                    % checking (calendar) days.
                    %[tf,dt] = matlab.internal.coder.datetime.isRegularTimeVector(rowTimes,'days');
                    tf = false;
                    if ~tf
                        [tf,dt] = matlab.internal.coder.datetime.isRegularTimeVector(rowTimes,'time');
                    end
                else
                    % Otherwise, start by checking months. If there's only two row
                    % times, dt will prefer (e.g.) "1 month" and not "28 days" as
                    % long as it's number of days in the starting month.
                    tf = false;
                    %[tf,dt] = matlab.internal.coder.datetime.isRegularTimeVector(rowTimes,'months');
                    if ~tf
                        %[tf,dt] = matlab.internal.coder.datetime.isRegularTimeVector(rowTimes,'days');
                        if ~tf
                            [tf,dt] = matlab.internal.coder.datetime.isRegularTimeVector(rowTimes,'time');
                        end 
                    end
                end
            end
        end
        
        %-----------------------------------------------------------------------
        function y = orientAs(x)
            % orient as column
            if ~iscolumn(x)
                y = reshape(x,[],1);
            else
                y = x;
            end
        end
    end
end
