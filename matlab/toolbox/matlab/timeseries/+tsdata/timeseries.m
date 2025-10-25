classdef (CaseInsensitiveProperties,TruncatedProperties) timeseries < matlab.mixin.SetGet & matlab.mixin.Copyable
%tsdata.timeseries class
%    tsdata.timeseries properties:
%       tsValue - Property is of type 'MATLAB array'  
%       UserData - Property is of type 'MATLAB array'  
%       DataChangeEventsEnabled - Property is of type 'bool'  
%       Name - Property is of type 'ustring'  
%       Version - Property is of type 'double'  
%       Data - Property is of type 'MATLAB array'  
%       DataInfo - Property is of type 'MATLAB array'  
%       Time - Property is of type 'MATLAB array'  
%       TimeInfo - Property is of type 'MATLAB array'  
%       Quality - Property is of type 'MATLAB array'  
%       QualityInfo - Property is of type 'MATLAB array'  
%       IsTimeFirst - Property is of type 'bool'  
%       Events - Property is of type 'MATLAB array'  
%       TreatNaNasMissing - Property is of type 'bool'  
%       Length - Property is of type 'MATLAB array'  
%
%    tsdata.timeseries methods:
%       fireDataChangeEvent -  Fire datachange event
%       isempty -  Evaluate to TRUE for empty time series objects
%       loadobj -  Overloaded load command
%       plot -  Plot time series data
%       size -  Return the size of a time series.
%       var -  Return the variance of the values in time series data.


properties (SetObservable)
    %TSVALUE Property is of type 'MATLAB array' 
    tsValue = [];
    %USERDATA Property is of type 'MATLAB array' 
    UserData = [];
    %DATACHANGEEVENTSENABLED Property is of type 'bool' 
    DataChangeEventsEnabled = true;
    %VERSION Property is of type 'double' 
    Version = 0;
end

properties (Transient, SetObservable)
    %NAME Property is of type 'ustring' 
    Name = '';
    %DATA Property is of type 'MATLAB array' 
    Data = [];
    %DATAINFO Property is of type 'MATLAB array' 
    DataInfo = [];
    %TIME Property is of type 'MATLAB array' 
    Time = [];
    %TIMEINFO Property is of type 'MATLAB array' 
    TimeInfo = [];
    %QUALITY Property is of type 'MATLAB array' 
    Quality = [];
    %QUALITYINFO Property is of type 'MATLAB array' 
    QualityInfo = [];
    %ISTIMEFIRST Property is of type 'bool' 
    IsTimeFirst = false;
    %EVENTS Property is of type 'MATLAB array' 
    Events = [];
    %TREATNANASMISSING Property is of type 'bool' 
    TreatNaNasMissing = false;
    %LENGTH Property is of type 'MATLAB array' 
    Length = [];
end


events 
    datachange
end  % events

    methods  % constructor block
        function h = timeseries(varargin)
            if nargin==1 && isa(varargin{1},'timeseries')
                h.tsValue = varargin{1};
            elseif nargin==1 && isa(varargin{1},'tsdata.timeseries')
                h.tsValue = varargin{1}.tsValue;
            else
                h.tsValue = timeseries(varargin{:});
            end
            h.Name = h.tsValue.Name;

        end  % timeseries      
    end  % constructor block

    methods 
        function value = get.UserData(obj)
            value = obj.getInternalProp(obj,'UserData');
        end

        function set.UserData(obj,value)
            obj.UserData =  obj.setInternalProp(value,'UserData');
        end

        function set.DataChangeEventsEnabled(obj,value)
            % DataType = 'bool'
            validateattributes(value,{'numeric','logical'}, {'scalar','nonnan'},'','DataChangeEventsEnabled')
            value = logical(value); %  convert to logical
            obj.DataChangeEventsEnabled = value;
        end

        function value = get.Name(obj)
            value = obj.getInternalProp(obj,'Name');
        end

        function set.Name(obj,value)
            obj.Name =  obj.setInternalProp(value,'Name');
        end

        function set.Version(obj,value)
            % DataType = 'double'
            validateattributes(value,{'numeric'}, {'scalar'},'','Version')
            value = double(value); %  convert to double
            obj.Version = value;
        end

        function value = get.Data(obj)
            value = obj.getInternalProp(obj,'Data');
        end

        function set.Data(obj,value)
            obj.Data =  obj.setInternalProp(value,'Data');
        end

        function value = get.DataInfo(obj)
            value = obj.getInternalProp(obj,'DataInfo');
        end

        function set.DataInfo(obj,value)
            obj.DataInfo =  obj.setInternalProp(value,'DataInfo');
        end

        function value = get.Time(obj)
            value = obj.getInternalProp(obj,'Time');
        end

        function set.Time(obj,value)
            obj.Time =  obj.setInternalProp(value,'Time');
        end

        function value = get.TimeInfo(obj)
            value = obj.getInternalProp(obj,'TimeInfo');
        end

        function set.TimeInfo(obj,value)
            obj.TimeInfo =  obj.setInternalProp(value,'TimeInfo');
        end

        function value = get.Quality(obj)
            value = obj.getInternalProp(obj,'Quality');
        end

        function set.Quality(obj,value)
            obj.Quality =  obj.setInternalProp(value,'Quality');
        end

        function value = get.QualityInfo(obj)
            value = obj.getInternalProp(obj,'QualityInfo');
        end

        function set.QualityInfo(obj,value)
            obj.QualityInfo =  obj.setInternalProp(value,'QualityInfo');
        end

        function value = get.IsTimeFirst(obj)
            value = obj.getInternalProp(obj,'IsTimeFirst');
        end

        function set.IsTimeFirst(obj,value)
            % DataType = 'bool'
            validateattributes(value,{'numeric','logical'}, {'scalar','nonnan'},'','IsTimeFirst')
            value = logical(value); %  convert to logical
            obj.IsTimeFirst =  obj.setInternalProp(value,'IsTimeFirst');
        end

        function value = get.Events(obj)
            value = obj.getInternalProp(obj,'Events');
        end

        function set.Events(obj,value)
            obj.Events =  obj.setInternalProp(value,'Events');
        end

        function value = get.TreatNaNasMissing(obj)
            value = obj.getInternalProp(obj,'TreatNaNasMissing');
        end

        function set.TreatNaNasMissing(obj,value)
            % DataType = 'bool'
            validateattributes(value,{'numeric','logical'}, {'scalar','nonnan'},'','TreatNaNasMissing')
            value = logical(value); %  convert to logical
            obj.TreatNaNasMissing =  obj.setInternalProp(value,'TreatNaNasMissing');            
        end

        function value = get.Length(obj)
            value = obj.getInternalProp(obj,'Length');
        end

        function set.Length(obj,value)
            obj.Length =  obj.setInternalProp(value,'Length');
        end

    end   % set and get functions 

    methods  % public methods

        function fireDataChangeEvent(h,varargin)
            if h.DataChangeEventsEnabled
                if nargin>=2
                    h.notify('datachange',varargin{1});
                else % Must include the source in the dataChangeEvent
                    h.notify('datachange',tsdata.dataChangeEvent([],[]));
                end
            end
        end  % fireDataChangeEvent
       
        function boo = isempty(this)
            boo = (isempty(this.tsValue) || this.tsValue.Length==0);
        end  % isempty
       
        function varargout = plot(h,varargin)
            if nargout>0
                [varargout{1:nargout}] = plot(h.tsValue,varargin{:});
            else
                plot(h.tsValue,varargin{:});
            end
        end  % plot

        function s = size(this,varargin)

            narginchk(1,2);

            if builtin('isempty',this)
                s = [0 0];
                return
            end

            % Find the size vector
            s = [this.TimeInfo.Length 1];


            % Deal with additional args
            if nargin>=2
                if varargin{1}<=numel(s)
                    s = s(varargin{1});
                else
                    s = 1;
                end
            end

        end  % size
       
        function out = var(this,varargin)
            if nargin==1
                out = utStatCalculation(this.tsValue,'var');
            else
                if isempty(varargin)
                    out = utStatCalculation(this.tsValue,'var');
                else
                    out = utStatCalculation(this.tsValue,'var',varargin{:});
                end
            end
        end  % var
       
end  % public methods 


    methods (Hidden) 

        function addevent(h,e,varargin)
            h.tsValue = addevent(h.tsValue,e,varargin{:});
            h.fireDataChangeEvent(tsdata.dataChangeEvent('addevent',[]));
        end  % addevent

        function addsample(this,varargin)
            cacheTimes = this.tsValue.Time;
            this.tsValue = addsample(this.tsValue,varargin{:});
            [~,I] = setdiff(this.tsValue.Time,cacheTimes);
            this.fireDataChangeEvent(tsdata.dataChangeEvent('addsample',I));
        end  % addsample
       
        % function hout = copy(h)
        %     hout = tsdata.timeseries;
        %     hout.TsValue = h.tsValue;
        %     hout.Name = h.Name;
        %     hout.DataChangeEventsEnabled = h.DataChangeEventsEnabled;
        % end  % copy
       
        function ctranspose(this)
            this.tsValue = ctranspose(this.tsValue);
            this.fireDataChangeEvent(tsdata.dataChangeEvent('ctranspose',[]));
        end  % ctranspose
       
        function delevent(this,event,varargin)
            this.tsValue = delevent(this.tsValue,event,varargin{:});
            this.fireDataChangeEvent(tsdata.dataChangeEvent('delevent',[]));
        end  % delevent
       
        function delsample(this,method,value)
            cacheTimes = this.tsValue.Time;
            this.tsValue = delsample(this.tsValue,method,value);
            [~,I] = setdiff(cacheTimes,this.tsValue.Time);
            this.fireDataChangeEvent(tsdata.dataChangeEvent('delsample',I));
        end  % delsample
       
        function detrend(this,type,varargin)%
            this.tsValue = detrend(this.tsValue,type,varargin{:});
            this.fireDataChangeEvent(tsdata.dataChangeEvent('detrend',[]));
        end  % detrend
       
        function display(this)
            if builtin('isempty',this) || ~isvalid(this)
                return
            end
            display(this.tsValue);
        end  % display

        function filter(this,n,d,varargin)
            this.tsValue = filter(this.tsValue,n,d,varargin{:});
            this.fireDataChangeEvent(tsdata.dataChangeEvent('filter',[]));
        end  % filter
       
        function Value = get(ts,Property)
            CharProp = ischar(Property);
            if CharProp,
                Property = {Property};
            elseif ~iscellstr(Property)
                error(message('MATLAB:tsdata:timeseries:get:invPropName'))
            end
       
            % Loop over each queried property
            Nq = numel(Property);
            Value = cell(1,Nq);
            for i=1:Nq,
                % Find match for k-th property name and get corresponding value
                % RE: a) Must include all properties to detect multiple hits
                %     b) Limit comparison to first 7 chars (because of iodelaymatrix)
                try
                    Value{i} = ts.tsValue.(Property{i});
                catch me
                    rethrow(me)
                end
            end
       
            % Strip cell header if PROPERTY was a string
            if CharProp,
                Value = Value{1};
            end
       end  % get       
        
       function outtimes = getAbsTime(this)
           outtimes = getabstime(this.tsValue);
       end  % getAbsTime

        
       function propVal = getInternalProp(h,eventData,propName)
           % Use get rather than . reference for speed
           if numel(h.tsValue)>0
               propVal = get(h.tsValue,propName);
           else
               propVal = h.findprop(propName).FactoryValue;
           end
       end  % getInternalProp       
        
       function out = getInterpMethod(this)
           out = getinterpmethod(this.tsValue);
       end  % getInterpMethod
       
        
       function [SampleSize,varargout] = getdatasamplesize(this)%
           [SampleSize,varargout] = getdatasamplesize(this.tsValue);
       end  % getdatasamplesize
       
        
       function out = getqualitydesc(this)
           out = getqualitydesc(this.tsValue);
       end  % getqualitydesc
       
       
       function ts = getsampleusingtime(this,StartTime,varargin)
           ts = tsdata.timeseries;
           ts.TsValue = getsampleusingtime(this.tsValue,StartTime,varargin{:});
       end  % getsampleusingtime
             
       function ts = gettsafteratevent(this,event,varargin)
           ts = tsdata.timeseries;
           ts = gettsafteratevent(this.tsValue,event,varargin{:});
       end  % gettsafteratevent
             
       function ts = gettsafterevent(this,event,varargin)
           ts = this.copy;
           ts.TsValue = gettsafterevent(this.Tsvalue,event,varargin{:});
       end  % gettsafterevent
           
       function ts = gettsatevent(this,event,varargin)
           ts = this.copy;
           ts.TsValue = gettsatevent(this.Tsvalue,event,varargin{:});
       end  % gettsatevent
 
       function ts = gettsbeforeatevent(this,event,varargin)
           ts = this.copy;
           ts.TsValue = gettsbeforeatevent(this.Tsvalue,event,varargin{:});
       end  % gettsbeforeatevent

       function ts = gettsbeforeevent(this,event,varargin)
           ts = this.copy;
           ts.TsValue = gettsbeforeevent(this.Tsvalue,event,varargin{:});
       end  % gettsbeforeevent
          
       function ts = gettsbetweenevents(this,event1,event2,varargin)
           ts = this.copy;
           ts.TsValue = gettsbetweenevents(this.Tsvalue,event1,event2,varargin{:});
       end  % gettsbetweenevents
       
       function idealfilter(this,intervals,type,varargin)%
           this.tsValue = idealfilter(this.tsValue,intervals,type,varargin{:});
           this.fireDataChangeEvent(tsdata.dataChangeEvent('idealfilter',[]));
       end  % idealfilter
           
       function init(this,varargin)
           this.tsValue = init(this.tsValue,varargin{:});
           this.fireDataChangeEvent(tsdata.dataChangeEvent('init',[]));
       end  % init
         
       function out = iqr(this,varargin)%
           out = iqr(this.tsValue,varargin{:});
       end  % iqr
       
       function iseq = isequalwithequalnans(this,ts2)%
           iseq = isequalwithequalnans(this.tsValue,ts2);
       end  % isequalwithequalnans
     
       function tsout = ldivide(ts1, ts2, varargin)
           if isnumeric(ts2)
               tsout = copy(ts1);
               tsout.TsValue = ldivide(ts1.tsValue,ts2,varargin{:});
           elseif isnumeric(ts1)
               tsout = copy(ts2);
               tsout.TsValue = ldivide(ts1,ts2.TsValue,varargin{:});
           else
               tsout = ts1.copy;
               tsout.TsValue = ldivide(ts1.TsValue, ts2.TsValue, varargin{:});
           end
       end  % ldivide
       
       function l = length(this)
           if isempty(this.tsValue)
               l = 0;
           else
               l = this.tsValue.Length;
           end
       end  % length  
        
       function out = max(this,varargin)%
           out = max(this.tsValue,varargin{:});
       end  % max
              
       function out = mean(this,varargin)%
       %
       
       
       out = mean(this.tsValue,varargin{:});
       
       
       
       
       end  % mean
       
        
       function out = median(this,varargin)%
       %
       
       
       out = median(this.tsValue,varargin{:});
       
       
       
       
       end  % median
       
        
       function merge(ts1,ts2,method,varargin)
       %
       
       
       [ts1.tsValue,ts2.TsValue] = synchronize(ts1.tsValue,ts2.TsValue,method,varargin{:});
       ts1.fireDataChangeEvent(tsdata.dataChangeEvent('merge',[]));
       ts2.fireDataChangeEvent(tsdata.dataChangeEvent('merge',[]));
       
       
       
       
       end  % merge
       
        
       function out = min(this,varargin)%
       %
       
       
       out = min(this.tsValue,varargin{:});
       
       
       
       
       end  % min
       
        
       function tsout = minus(ts1, ts2, varargin)
       %
       
       
       if isnumeric(ts2)
           tsout = copy(ts1);
           tsout.TsValue = minus(ts1.tsValue,ts2,varargin{:});
       elseif isnumeric(ts1)
           tsout = copy(ts2);
           tsout.TsValue = minus(ts1,ts2.TsValue,varargin{:});
       else
           tsout = copy(ts1);
           tsout.TsValue = minus(ts1.tsValue,ts2.TsValue,varargin{:});
       end
       end  % minus
       
        
       function tsout = mldivide(ts1, ts2, varargin)
       %
       
       
       if isnumeric(ts2)
           tsout = copy(ts1);
           tsout.TsValue = mldivide(ts1.tsValue,ts2,varargin{:});
       elseif isnumeric(ts1)
           tsout = copy(ts2);
           tsout.TsValue = mldivide(ts1,ts2.TsValue,varargin{:});
       else    
           tsout = ts1.copy;
           tsout.TsValue = mldivide(ts1.TsValue,ts2.TsValue,varargin{:});
       end
       
       
       
       
       end  % mldivide
       
        
       function tsout = mrdivide(ts1, ts2, varargin)
       %
       
       
       if isnumeric(ts2)
           tsout = copy(ts1);
           tsout.TsValue = mrdivide(ts1.tsValue,ts2,varargin{:});
       elseif isnumeric(ts1)
           tsout = copy(ts2);
           tsout.TsValue = mrdivide(ts1,ts2.TsValue,varargin{:});
       else    
           tsout = ts1.copy;
           tsout.TsValue = mrdivide(ts1.TsValue,ts2.TsValue,varargin{:});
       end
       
       
       
       
       end  % mrdivide
       
        
       function tsout = mtimes(ts1, ts2, varargin)
       %
       
       
       if isnumeric(ts2)
           tsout = copy(ts1);
           tsout.TsValue = mtimes(ts1.tsValue,ts2,varargin{:});
       elseif isnumeric(ts1)
           tsout = copy(ts2);
           tsout.TsValue = mtimes(ts1,ts2.TsValue,varargin{:});
       else
           tsout = copy(ts1);
           tsout.TsValue = mtimes(ts1.tsValue,ts2.TsValue,varargin{:});
       end
       end  % mtimes
       
        
       function tsout = plus(ts1, ts2, varargin)
       %
       
       
       if isnumeric(ts2)
           tsout = copy(ts1);
           tsout.TsValue = plus(ts1.tsValue,ts2,varargin{:});
       elseif isnumeric(ts1)
           tsout = copy(ts2);
           tsout.TsValue = plus(ts1,ts2.TsValue,varargin{:});    
       else
           tsout = copy(ts1);
           tsout.TsValue = plus(ts1.tsValue,ts2.TsValue,varargin{:});
       end
       
       
       
       
       end  % plus
       
        
       function tsout = rdivide(ts1, ts2, varargin)
       %
       
       
       if isnumeric(ts2)
           tsout = copy(ts1);
           tsout.TsValue = rdivide(ts1.tsValue,ts2,varargin{:});;
       elseif isnumeric(ts1)
           tsout = copy(ts2);
           tsout.TsValue = rdivide(ts1,ts2.TsValue,varargin{:});      
       else
           tsout = copy(ts1);
           tsout.TsValue = rdivide(ts1.tsValue,ts2.TsValue,varargin{:});
       end
       end  % rdivide
       
        
       function resample(this,timevec,varargin)
       %
       
       
       this.tsValue = resample(this.tsValue,timevec,varargin{:});
       this.fireDataChangeEvent(tsdata.dataChangeEvent('resample',[]));
       
       
       
       end  % resample
       
        
       function I = select(this,rule,varargin)
       %
       
       
       if nargin > 1
           rule = convertStringsToChars(rule);
       end
       
       h = this.tsValue;
       
       %% Initialize and restrict to 2d arrays
       data = h.data;
       if h.IsTimeFirst && ndims(data)>2
           error(message('MATLAB:tsdata:timeseries:select:nodims'))
       elseif ~h.IsTimeFirst && (ndims(data)>4 || (ndims(data)==3 && size(data,2)>1))
           error(message('MATLAB:tsdata:timeseries:select:nodims'))
       end
       rule = lower(rule);
       
       %% Parse input args
       cols = [];
       switch rule
           case 'outliers'
               if nargin<4
                   error(message('MATLAB:tsdata:timeseries:select:noWinlengthAndConfLevel'))
               end
               % default value can be 10% of the length of data
               winlength = varargin{1};
               % default value can be 95, which mean 95%
               conf = varargin{2};
               if nargin>=5
                   cols = varargin{3};
               end
           case 'flatlines'
               if nargin<3
                  error(message('MATLAB:tsdata:timeseries:select:noWinLength'))
               end
               winlength = varargin{1};
               if nargin>=4
                   cols = varargin{3};
               end        
           otherwise
                  error(message('MATLAB:tsdata:timeseries:select:arginv'));
       end
       
       %% Initialize the columns
       if isempty(cols)
           if h.IsTimeFirst
               cols = 1:size(data,2);
               data = data(:,cols);
           else
               cols = 1:size(data,1);
               data = squeeze(data(cols,1,:))';
           end
       end
       
       
       %% Initialize output
       if h.IsTimeFirst
           I = false(h.TimeInfo.Length,length(cols));
       else
           I = false(length(cols),h.TimeInfo.Length);
       end
               
       switch lower(rule)
           case 'outliers'
               confconst = sqrt(2)*erfinv(2*conf/100-1);
               erfconst = .5/(sqrt(2)*erfinv(.5));
               for row=1:h.TimeInfo.Length
                   L = min(max(row-floor(winlength/2),1),h.TimeInfo.Length-winlength);
                   U = L+winlength;
                   I(row,:) = localoutlier(data(L:U,cols),confconst,erfconst,data(row,:));
               end
           case 'flatlines'
               % Insert infs at the start and end to ensure we detect flatlines
               % which occur at the start and end
               dX = diff(diff([inf*ones(1,length(cols));data;inf*ones(1,length(cols))])==0);
               % Find indices of leading and trailing edges of constant periods
               for col=1:length(cols)
                  I1 = find(dX(:,col)==1);
                  I2 = find(dX(:,col)==-1);
                  for row=1:size(I1,1)
                     % If the constant period is longer than the window length set
                     % all the corresponding indices to excluded
                       I(I1(row):I2(row),col) = ...
                               (I2(row)-I1(row)+1>=winlength);
                  end
               end
           otherwise
                  error(message('MATLAB:tsdata:timeseries:select:arginv'));
               
       end
       end  % select
       
       

        
       function set(h,varargin)
       %
       
       
       for k=1:floor((nargin-1)/2)
           if ~strcmpi(varargin{2*k-1},'tsvalue')
               h.tsValue = set(h.tsValue,varargin{2*k-1},varargin{2*k});
           else
               h.tsValue = varargin{2*k};
           end
       end
       
       
       
       
       
       end  % set
       
        
       function setAbsTime(this,timeArray,varargin)
       %
       
       
       this.tsValue = setabstime(this.tsValue,timeArray,varargin{:});
       this.fireDataChangeEvent(tsdata.dataChangeEvent('setAbsTime',[]));
       
       
       
       end  % setAbsTime
       
        
       function propVal = setInternalProp(h,eventData,propName)
           % Bypass using susref for performance
           if numel(h.tsValue)>0 % Do not use isempty here - it is overridden
               h.tsValue.(propName) = eventData;
               %h.TsValue.BeingBuilt = false;
           end

           % Fire a datachange event even though the new property value has not yet
           % been assigned. It's ok because property values will be read from
           % tsValue, which is up to date
           h.fireDataChangeEvent(tsdata.dataChangeEvent(propName,[]));
           propVal = eventData;

       end  % setInternalProp
       
        
       function setInterpMethod(this,varargin)
       %
       
       
       this.tsValue = setinterpmethod(this.tsValue,varargin{:});
       this.fireDataChangeEvent(tsdata.dataChangeEvent('setInterpMethod',[]));
       
       
       
       end  % setInterpMethod
       
        
       function out = std(this,varargin)%
       %
       
       
       out = std(this.tsValue,varargin{:});
       
       
       
       
       end  % std
       
        
       function out = sum(this,varargin)%
       %
       
       
       out = sum(this.tsValue,varargin{:});
       
       
       
       
       end  % sum
       
        
       function synchronize(ts1,ts2,method,varargin)
       %
       
       
       [ts1.tsValue,ts2.TsValue] = synchronize(ts1.tsValue,ts2.TsValue,method,varargin{:});
       ts1.fireDataChangeEvent(tsdata.dataChangeEvent('synchronize',[]));
       ts2.fireDataChangeEvent(tsdata.dataChangeEvent('synchronize',[]));
       
       
       
       end  % synchronize
       
        
       function tsout = times(ts1, ts2, varargin)
       %
       
       
       if isnumeric(ts2)
           tsout = copy(ts1);
           tsout.TsValue = times(ts1.tsValue,ts2,varargin{:});
       elseif isnumeric(ts1)
           tsout = copy(ts2);
           tsout.TsValue = times(ts1,ts2.TsValue,varargin{:}); 
       else
           tsout = copy(ts1);
           tsout.TsValue = times(ts1.tsValue,ts2.TsValue,varargin{:});
       end
       end  % times
       
        
       function transpose(this)
       %
       
       
       this.tsValue = transpose(this.tsValue);
       this.fireDataChangeEvent(tsdata.dataChangeEvent('transpose',[]));
       
       
       
       
       end  % transpose
       
        
       function [boo, offending_name] = utChkforSlashInName(h)
       %
       
       
       [boo, offending_name] = utChkforSlashInName(h.tsValue);
       
       end  % utChkforSlashInName
       
end  % possibly private or hidden 


    methods (Static) % static methods
        
       function h = loadobj(s)
       % LOADOBJ  Overloaded load command
       
       
       % When attempting to load sp2 time series objects, reconstruct the time
       % series (for Sys Bio)
       if isstruct(s)
           h = tsdata.timeseries;
           h.tsValue = localLoadObj(s);
       elseif isa(s,'tsdata.timeseries')
           h = s;
       else 
           h = [];
       end
       end  % loadobj
       
       

end  % static methods 

end  % classdef

function h = localLoadObj(s)
h = timeseries;
% Get the data, time and quality
for k=1:length(s.Data_)
    switch s.Data_(k).LoadedData.Variable.Name
        case 'Data'
            data = s.Data_(k).LoadedData.Data;
            interpObj = [];
            if ishandle(s.Data_(k).LoadedData.MetaData) || isobject(s.Data_(k).LoadedData.MetaData)
                dataunits = s.Data_(k).LoadedData.MetaData.Units;
                datauserdata = s.Data_(k).LoadedData.MetaData.UserData;
                if ~isempty(s.Data_(k).LoadedData.MetaData.Interpolation) && ...
                        ishandle(s.Data_(k).LoadedData.MetaData.Interpolation)
                    interpObj = s.Data_(k).LoadedData.MetaData.Interpolation;
                end
            else
                dataunits = '';
                datauserdata = [];
            end
            isTimeFirst = s.Data_(k).LoadedData.GridFirst;
        case 'Time'
            time = s.Data_(k).LoadedData.Data;
            if isempty(time)
                time = s.Data_(2).LoadedData.MetaData.getData;
            end
            try
                timeunits = s.Data_(k).LoadedData.MetaData.Units;
            catch %#ok<CTCH>
                timeunits = 'seconds';
            end
            try
                startdate = s.Data_(k).LoadedData.MetaData.StartDate;
            catch %#ok<CTCH>
                startdate = '';
            end
        case 'Quality'
            try
                qual = s.Data_(k).LoadedData.Data;
                qualInfoCodes = s.Data_(k).LoadedData.MetaData.Code;
                qualInfoDesr = s.Data_(k).LoadedData.MetaData.Description;
            catch %#ok<CTCH>
                qual = [];
                qualInfoCodes = [];
                qualInfoDesr = {};
            end
    end
end

% Initialize the object
if isempty(data) && ~isempty(time)
    if isTimeFirst
        data = zeros(length(time),0);
    else
        data = zeros(0,length(time));
    end
end
h = init(h,data,time,qual,'Name',s.Name,'IsTimeFirst',isTimeFirst);

% DataInfo: units & userdata
dataInfo = h.DataInfo;
dataInfo.Units = dataunits;
dataInfo.UserData = datauserdata;
if ~isempty(interpObj)
    dataInfo.Interpolation = interpObj;
end
h.dataInfo = dataInfo;
% TimeInfo: units and StartDate
timeInfo = h.TimeInfo;
timeInfo.Units = timeunits;
timeInfo.StartDate = startdate;
h.TimeInfo = timeInfo;
% Qualityinfo: code and description
qualInfo = h.QualityInfo;
qualInfo.Code = qualInfoCodes;
qualInfo.Description = qualInfoDesr;
h.QualityInfo = qualInfo;
% Events
if isfield(s,'Events')
    h.Events = s.Events;
end
% Instance props from 2006a 2006b
% Any fieldnames which do not correspond to timeseries
% properties (except Grid_,InstancePropValues_,
% InstancePropNames are instance properties). Add them as
% a struct in the UserData property.
cTimeSeries = ?timeseries;
instanceProps = setdiff(fields(s),cellfun(@(x) {x.Name},cTimeSeries.Properties));
instanceProps = setdiff(instanceProps,{'Grid_','InstancePropNames_',...
    'InstancePropValues_'});
if ~isempty(instanceProps)
    for k=1:length(instanceProps)
        h.UserData.(instanceProps{k}) = s.(instanceProps{k});
    end
end

% The fieldnames InstancePropNames_ and
% InstancePropValues_ represent 2006a,b instance props.
% Add them to the instance props stored in the UserData
if isfield(s,'InstancePropNames_') && ~isempty(s.InstancePropNames_)
    for k=1:min(length(s.InstancePropNames_),length(s.InstancePropValues_))
        h.UserData.(s.InstancePropNames_{k}) = s.InstancePropValues_{k};
    end
end
end  % localLoadObj



function idx = localoutlier(x,confconst,erfconst,thisx)

%% Local function to estimate the whether the observation thisx (row)
%% falls outside the confidence band defined by confconst for the
%% dataset defined by x. Note that each observation of x is a row.

med = median(x);

%% TO DO: Better estimates of iqr
%% TO DO: Add iqr calc, can we do this more efficiently recursively?
if size(x,1)<4
    sigma = std(x);
else % Robust estimate of sigma from iqr
    [xsort, I] = sort(x);
    sigma = erfconst*(xsort(ceil(3*size(x,1)/4),:)-xsort(floor(size(x,1)/4),:));
end
idx = (thisx>med+confconst*sigma | thisx<med-confconst*sigma);
end  % localoutlier


