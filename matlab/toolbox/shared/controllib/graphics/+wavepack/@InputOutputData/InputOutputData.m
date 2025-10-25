classdef InputOutputData < handle
   % Class representing input-output data in MATLAB.
   
   %  Copyright 2013-2024 The MathWorks, Inc.
   
   properties(AbortSet)
      %NAME I/O data name
      %
      Name

      TimeUnit (1,1) string {mustBeValidTimeUnit(TimeUnit)} = "seconds"
   end
   
   properties(Dependent, SetObservable)
      %DATA Input output data. 
      %
      %    One of:
      %      - iddata object
      %      - sdo.Experiment object
      Data
   end
   
   properties (Access = protected)
      %DATA_ 
      %
      %    Default storage container for Data
      Data_
      
      %PREVIEW
      %
      %    Storage containter for preview data
      Preview
      
      %GETDATAFCN 
      %
      %    Fcn that generates Data rather than access from Data_
      %    A cell array {Fcn, FcnArg1, FcnArg2, ...}
      DataGetFcn
      
      %SETDATAFCN
      %
      %    Fcn that sets Data to designated place rather than in Data_.
      %    A cell array {Fcn, FcnArg1, FcnArg2, ..., Value_to_be_set}
      DataSetFcn
      
      %ISTIMEDATA
      %
      %    Logical specifying whether I/O data is time domain data or not.
      IsTimeData
      
      %VERSION
      %
      Version_ = 1;
   end

   properties (Dependent)
      InputName
      OutputName
   end
      
   methods (Abstract)
      commit(D)                            % Preview -> Data  transfer
      val  = getInputName(D)               % string vector of input signal names
      val  = getOutputName(D)              % string vector of output signal names
      %GETDATA
      %
      %  data - getData(obj, [getpreview])
      %
      %    Inputs:
      %      getpreview - logical indicating whether to return
      %                   preview data or not, if omitted default
      %                   false is used.
      %
      %    Outputs:
      %      data - the underlying data object encapsulated by obj. 
      data = getData(D, FromPreview)      
      
      %GETSIGNALDATA
      %
      %    signal = getSignalData(obj,[name],[getpreview],[expno])
      %
      %    Inputs:
      %      name       - string or cell array of strings specifying
      %                   name of signal data to get, if omitted or
      %                   set to [], the entire collection of signals is
      %                   returned
      %      getpreview - logical indicating whether to return
      %                   preview data or not, if omitted default
      %                   false is used
      %      expno      - Return the slice of data corresponding to chosen
      %                   experiment number. For IDDATA use. Default: 1
      %
      %    Outputs:
      %     signal - timeseries array or frd array, one entry for each
      %              requested signal name, if no signal name input
      %              was specified the entire signal collection is returned
      signal = getSignalData(D,name,FromPreview,varargin)   
      
      %SETSIGNALDATA
      %
      %    setSignalData(obj,name,signal,[setpreview],[expno])
      %
      %    Inputs:
      %      name       - string specifying name of signal to set
      %      signal     - timeseries or frd data for named signal
      %      setpreview - logical indicating whether to set the
      %                   preview data or not, if omitted the default
      %                   false is used
      %      expno      - for multiexperiment data, the partocular
      %                   experiment index where the update must be
      %                   applied. Default: 1.
      %
      setSignalData(D,name,data,ApplyToPreview,varargin)
   end
   
   methods
      function D = InputOutputData(Data)
         %INPUTOUTPUTDATA Construct InputOutputData object
         %
         %    The InputOutputData class is abstract, constructor called by 
         %    subclasses.
         ni           = nargin;
         D.Name       = 'data';
         D.IsTimeData = true;
         D.Preview    = [];
         if ni>0
            D.Data_ = Data;
         end
      end
      
      function Value = get.Data(D)
         % GET method for Data property.
         Fcn = D.DataGetFcn;
         if ~isempty(Fcn)
            Value = feval(Fcn{:});
         else
            Value = D.Data_;
         end
      end

      function Value = get.InputName(D)
         Value = getInputName(D);
      end

      function Value = get.OutputName(D)
         Value = getOutputName(D);
      end
      
      function set.Data(D, Value)
         % SET method for Data property.
         % Value must not change IO size.
         setData_(D, Value);
      end
      
      function resetData(D,data,ApplyToPreview,varargin)
            %RESETDATA
            %
            %    resetData(obj,data,[resetpreview],[expno])
            %
            %    Inputs:
            %      data         - new data, must by iddata or sdo.experiment
            %      resetpreview - logical indicating whether to reset the
            %                     preview data or the true data, if omitted
            %                     the default false is used
            %      expno        - Experiment to set the data to. Default 1.
            
            if nargin < 3
                ApplyToPreview = false;
            end
            
            if ApplyToPreview
                D.Preview = data;
            else
                D.Data = data;
            end
      end
      
      function iosize = getIOSize(D)
         %GETIOSIZE Get the number of input/output signals in the data
         %
         %    sz = getIOSize(obj)
         %
         %    Outputs:
         %      sz - array with [nIn, nOut]
         
         iosize = getIOSize(D.Data);
      end
      
      function [ny, nu] = iosize(D)
         % for chart use
         sz = getIOSize(D);
         if nargout==1
            ny = sz;
         else
            ny = sz(1);
            nu = sz(2);
         end
      end

      function val = getDefaultTimeUnit(~)
         %GETDEFAULTTIMEUNIT
         %
         %    Get the preferred units for plotting time domain data.
         %
         %    val = getDefaultTimeUnit(obj)
         %
         %    Outputs:
         %      val - string with time units
         %
         
         val = 'seconds';
      end
      
      function val = getDefaultFrequencyUnit(~)
         %GETDEFAULTFREQUECYUNIT
         %
         %    Get the preferred units for plotting frequency domain data.
         %
         %    val = getDefaultFrequencyUnit(obj)
         %
         %    Outputs:
         %      val = string with frequency units
         
         % Default: rad/timeunit
         val = 'rad/TimeUnit';
      end

      function ISB = getDefaultISB(~)
         ISB = 'foh';
      end

      function n = getNumExp(~)
         n = 1;
      end

      function D = getPlotSource(D, varargin)
         % no-op
      end

      function D = getModelData(D, varargin)
         % no-op
      end

      function boo = isTimeVarying(~)
         boo = false;
      end

      function [InputNames,OutputNames] = mrgios(varargin)
         %MRGIOS  Compiles master I/O name list from I/Os of individual datasets.
         %
         %   [INPUTNAMES,OUTPUTNAMES] = MRGIOS(D1,D2,...) returns I/O names
         %   for the minimal axes grid containing all the datasets D1, D2,...
         nsys = length(varargin);
         if nsys==1
            % Single dataset
            sys = varargin{1};
            InputNames = sys.InputName;
            OutputNames = sys.OutputName;
         else
            % Merge name
            InputNameList = cell(1,nsys);
            OutputNameList = cell(1,nsys);
            for ct=1:nsys
               sys = varargin{ct};
               InputNameList{ct} = sys.InputName;
               OutputNameList{ct} = sys.OutputName;
            end

            % Merge names
            InputNames = unique(InputNameList,'stable');
            OutputNames = unique(OutputNameList,'stable');
         end
      end
         
      function [mag,phase,w,FocusInfo] = freqresp(this,~,UsePreview)
         % Frequency response for plotting
         frStruct = getFRDSignals(this,UsePreview);
         N = numel(frStruct);
         mag = cell(N,1);
         phase = cell(N,1);
         w = cell(N,1);
         Ts = cell(N,1);
         Focus = [Inf -Inf];
         for ct = 1:N
            % Each signal is an @frd with 1 or more outputs, 1 input
            sig = frStruct{ct};
            TimeUnits = sig.TimeUnit;
            Fac = funitconv(sig.FrequencyUnit,'rad/s',TimeUnits);
            [mag_,phase_,w_,FocusInfo] = localfreqresp(sig);
            phase_(~isfinite(mag_) | mag_==0) = NaN;  % phase of 0 or Inf undefined
            w{ct} = w_*Fac;
            mag{ct} = mag_;
            phase{ct} = phase_;
            Focus_ = FocusInfo.Focus*Fac;
            Focus = [min(Focus(1), min(Focus_)), max(Focus(2), max(Focus_))];
            FocusInfo.Focus = Focus;
            Ts{ct} = sig.Ts*tunitconv(TimeUnits,'seconds');
         end
      end
   
      function boo = isreal(D)
         boo = true;
      end

      function Ts = getTs(varargin)
         %GETTS
         % Ts = getTs(obj,ksig,kexp)
         % Inputs:
         %     ksig: signal number in the order (outputs, inputs)
         %     kexp: experiment number
         % Output: sample time. NaN if irregularly sampled
         Ts = NaN;
      end

      function boo = isstatic(~)
         boo = false;
      end
   end

   methods(Hidden)
      function obj = createPlotSource(D)
         obj = iodatapack.IODataSource(D);
      end
   end
   
   methods (Access = protected)
      function setData_(D, Value)
         % Default set method implementation for "Data" property.
         Fcn = D.DataSetFcn;
         if ~isempty(Fcn)
            feval(Fcn{:},Value);
         else
            D.Data_ = Value;
         end
      end
   end
   
end

%--------------------------------------------------------------------------
function mustBeValidTimeUnit(timeUnit)
validTimeUnits = controllibutils.utGetValidTimeUnits;
validatestring(timeUnit,validTimeUnits(:,1));
end

%--------------------------------------------------------------------------
function [mag,ph,w,FocusInfo] = localfreqresp(sig)

w = sig.Frequency;
%w = w(w>=0,:);
Focus = [w(find(w>=0,1)), max(w)];
h = sig.Response; % N-by-SigDim matrix

mag = abs(h);
ph = angle(h);
ph(~isfinite(mag)) = NaN;
ph = unwrap(ph,[],1);

[w,is] = sort(w);
mag = mag(is,:);
ph = ph(is,:);

FocusInfo = localSetFreqFocus(Focus);

end

%--------------------------------------------------------------------------
function FocusInfo = localSetFreqFocus(focus)
% Creates focus information consumed by frequency response functions.

if focus(1)>focus(2)
   % No data in [w(1),w(end)]: use arbitrary focus
   focus = [.1 1];
   soft = true;
else
   if focus(1)==focus(2)
      % single data point: focus around it
      df = 10^.5;
      focus = [focus(1)/df,focus(1)*df];
   end
   soft = false;
end
FocusInfo = struct('Focus',focus,'DynRange',focus,'Soft',soft);
end