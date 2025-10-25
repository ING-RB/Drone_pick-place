classdef (CaseInsensitiveProperties,TruncatedProperties) abstracttimemetadata
    properties
        %UNITS Property is of type 'TimeUnits enumeration: {'weeks','days','hours','minutes','seconds','milliseconds','microseconds','nanoseconds'}'
        Units = 'seconds';
        %USERDATA Property is of type 'MATLAB array'
        UserData = [];
    end
    methods
        function obj = set.Units(obj,value)
            % Enumerated DataType = 'TimeUnits enumeration: {'weeks','days','hours','minutes','seconds','milliseconds','microseconds','nanoseconds'}'
            value = validatestring(value,{'weeks','days','hours','minutes','seconds','milliseconds','microseconds','nanoseconds'},'','Units');
            obj.Units = value;
        end
    end   % set and get functions

    methods  % public methods
        %----------------------------------------
        function Value = get(h,varargin)
            Value = uttsget(h,varargin{:});
        end  % get

        %----------------------------------------
        function Out = set(h,varargin)
            ni = nargin;
            no = nargout;
            if ~isa(h,'tsdata.abstracttimemetadata'),
                % Call built-in SET. Handles calls like set(gcf,'user',ss)
                builtin('set',h,varargin{:});
                return
            elseif no && ni>2,
                error(message('MATLAB:tsdata:abstracttimemetadata:set:invSyntax'));
            end

            % Get public properties and their assignable values
            if ni<=2,
                AllProps = fieldnames(h);
                PropNames = fieldnames(struct(h));
                PropValues = struct2cell(struct(h));
                AsgnValues = tspvformat(PropValues(1:length(PropNames)));
            else
                % Add obsolete property Td
                AllProps = fieldnames(h);
            end


            % Handle read-only cases
            if ni==1,
                % SET(H) or S = SET(H)
                if no,
                    Out = cell2struct(AsgnValues,AllProps,1);
                else
                    disp(tspvformat(AllProps,AsgnValues))
                end
            elseif ni==2,
                % SET(H,'Property') or STR = SET(H,'Property')
                % Return admissible property value(s)
                try
                    [Property,imatch] = tspnmatch(varargin{1},AllProps,10);
                    if no,
                        Out = AsgnValues{imatch};
                    else
                        disp(AsgnValues{imatch})
                    end
                catch me
                    rethrow(me)
                end

            else
                % SET(H,'Prop1',Value1, ...)
                ename = inputname(1);
                if isempty(ename),
                    error(message('MATLAB:tsdata:abstracttimemetadata:set:badVar'))
                elseif rem(ni-1,2)~=0,
                    error(message('MATLAB:tsdata:abstracttimemetadata:set:invPropValPairs'))
                end

                % Match specified property names against list of public properties and
                % set property values at object level
                % RE: a) Include all properties to appropriately detect multiple matches
                %     b) Limit comparison to first 10 chars (because of qualityinfo)
                try
                    for i=1:2:ni-1,
                        varargin{i} = tspnmatch(varargin{i},AllProps,10);
                        h.(tspnmatch(varargin{i},AllProps,10)) = varargin{i+1};
                    end
                catch me
                    rethrow(me)
                end

                % Assign ts in caller's workspace
                assignin('caller',ename,h)
            end
        end  % set

    end  % public methods

    methods (Hidden) % possibly private or hidden
        %----------------------------------------
        function dispmsg = getTimeStr(timeInfo)
            %% Generates a string describing the time vector

            %% Create the current time vector string
            if ~isempty(timeInfo.StartDate)
                if tsIsDateFormat(timeInfo.Format)
                    try
                        startstr = datestr(datenum(timeInfo.StartDate,timeInfo.Format)+timeInfo.Start*tsunitconv('days',...
                            timeInfo.Units),timeInfo.Format);
                        endstr = datestr(datenum(timeInfo.StartDate,timeInfo.Format)+timeInfo.End*tsunitconv('days',...
                            timeInfo.Units),timeInfo.Format);
                    catch me
                        startstr = datestr(datenum(timeInfo.StartDate)+timeInfo.Start*tsunitconv('days',...
                            timeInfo.Units));
                        endstr = datestr(datenum(timeInfo.StartDate)+timeInfo.End*tsunitconv('days',...
                            timeInfo.Units));
                    end
                else
                    startstr = datestr(datenum(timeInfo.StartDate)+timeInfo.Start*tsunitconv('days',...
                        timeInfo.Units),'dd-mmm-yyyy HH:MM:SS');
                    endstr = datestr(datenum(timeInfo.StartDate)+timeInfo.End*tsunitconv('days',...
                        timeInfo.Units),'dd-mmm-yyyy HH:MM:SS');
                end
                dispmsg = sprintf(getString(message('MATLAB:tsdata:abstracttimemetadata:getTimeStr:CurrentTime',startstr,endstr)));
            else
                if isnan(timeInfo.Increment)
                    dispmsg = getString(message('MATLAB:tsdata:abstracttimemetadata:getTimeStr:CurrentTimeNonuniform',...
                        sprintf('%.4g',timeInfo.Start),sprintf('%.4g',timeInfo.End),timeInfo.Units));
                else
                    dispmsg = getString(message('MATLAB:tsdata:abstracttimemetadata:getTimeStr:CurrentTimeUniform',...
                        sprintf('%.4g',timeInfo.Start),sprintf('%.4g',timeInfo.End),timeInfo.Units));
                end
            end
        end  % getTimeStr

        function [ts1timevec, ts2timevec, outprops, outtrans] = ...
                timemerge(timeInfo1, timeInfo2, time1, time2)

            % Get available units. TO DO: Restore enumeration
            %myEnumHandle = findtype('TimeUnits');
            %availableUnits = myEnumHandle.Strings;
            availableUnits = {'seconds','minutes','hours','days','weeks'};

            % Convert time units to the smaller units and get new time vectors
            outunits = availableUnits{max(find(strcmp(timeInfo1.Units,availableUnits)), ...
                find(strcmp(timeInfo2.Units,availableUnits)))};
            unitconv1 = localUnitConv(outunits,timeInfo1.Units);
            unitconv2 = localUnitConv(outunits,timeInfo2.Units);
            ts1timevec = unitconv1*time1;
            ts2timevec = unitconv2*time2;

            % If time vectors are both absolute then convert them to the output units
            % and apply the converted difference between the startdates
            ref = '';
            delta = 0;
            deltaTS = [];
            if ~isempty(timeInfo1.Startdate) && ~isempty(timeInfo2.Startdate)
                delta = localUnitConv(outunits,'days')*...
                    (datenum(timeInfo1.Startdate)-datenum(timeInfo2.Startdate));
                if delta>0
                    ref = timeInfo2.Startdate;
                    ts1timevec = ts1timevec+delta;
                    deltaTS = 1;
                else
                    ref = timeInfo1.Startdate;
                    delta = -delta;
                    ts2timevec = ts2timevec+delta;
                    deltaTS = 2;
                end
            else
                if ~(isempty(timeInfo1.StartDate) || ~isempty(timeInfo2.StartDate))
                    warning(message('MATLAB:tsdata:abstracttimemetadata:timemerge:mismatchTimeVecs'))
                end
            end

            % Merge time formats
            outformat = '';
            if strcmp(timeInfo1.Format,timeInfo2.Format)
                outformat = timeInfo1.Format;
            end

            outprops = struct('ref',ref,'outformat',outformat,'outunits',outunits);
            outtrans = struct('delta',delta,'deltaTS', deltaTS,'scale',{{unitconv1,unitconv2}});
        end  % timemerge
    end 

end  % classdef

function convFactor = localUnitConv(outunits,inunits)

convFactor = 1; % Return 1 if error or unknown units
try %#ok<TRYNC>
    % Get available units
    %myEnumHandle = findtype('TimeUnits');
    %availableUnits = myEnumHandle.Strings;
    availableUnits = {'seconds','minutes','hours','days','weeks'};

    % Factors are based on {'weeks', 'days', 'hours', 'minutes', 'seconds',
    % 'milliseconds', 'microseconds', 'nanoseconds'}
    factors = [604800 86400 3600 60 1 1e-3 1e-6 1e-9];
    indIn = find(strcmp(inunits,availableUnits));
    if isempty(indIn)
        return
    end
    factIn = factors(indIn);
    indOut = find(strcmp(outunits,availableUnits));
    if isempty(indOut)
        return
    end
    factOut = factors(indOut);
    convFactor = factIn/factOut;
end
end  % localUnitConv

    
