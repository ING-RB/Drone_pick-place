classdef (StrictDefaults)DigitalIO < matlab.System
    %DigitalIO Set or get the logical state of a digital pin
    %
    
    % Copyright 2015-2021 The MathWorks, Inc.
    
    %#codegen
    %#ok<*EMCA>
    
    properties (Hidden)
        Hw
    end
    
    properties (Hidden,Nontunable)
    
     %handle to deploy and connect to IO server   
     DeployAndConnectHandle        
     %digitalIOClient
     dIOClient     
     %numeric pin for IO
     PinInternalIO 
     %variable to store Connected IO status
     IsIOEnable = false;
     
    end
    
    properties (Constant, Hidden)
        DirectionSet = matlab.system.StringSet({'input','output'});
    end
    
    properties (Abstract,Nontunable)
        % Pin Pin
        Pin
    end
    
    properties (Nontunable)
        % Direction
        Direction = 'input'
    end
    
    properties (Dependent, Hidden)
        DirectionEnum
    end

    properties (Access = protected)
        MW_DIGITALIO_HANDLE;
    end
    
    methods
        function obj = DigitalIO(varargin)
            coder.allowpcode('plain');
            setProperties(obj,nargin,varargin{:});
        end
        

        function ret = get.DirectionEnum(obj)
            if isequal(obj.Direction,'input')
                ret = SVDTypes.MW_Input;
            else
                ret = SVDTypes.MW_Output;
            end
        end
        
        function open(obj)
            if coder.target('Rtw')
                % Close digital I/O device 
                % void MW_digitalIO_open(uint32_T pin, uint8_T direction)
                coder.cinclude('MW_digitalIO.h');
                obj.MW_DIGITALIO_HANDLE = coder.opaque('MW_Handle_Type','HeaderFile','MW_SVD.h');
                if isnumeric(obj.Pin)
                    obj.MW_DIGITALIO_HANDLE = coder.ceval('MW_digitalIO_open',obj.Pin,obj.DirectionEnum);
                else
                    pinname = coder.opaque('uint32_T', obj.Pin);
                    obj.MW_DIGITALIO_HANDLE = coder.ceval('MW_digitalIO_open',pinname,obj.DirectionEnum);
                end
            else
                obj.MW_DIGITALIO_HANDLE = coder.nullcopy(0);
                % Place simulation setup code here
                if isempty(obj.Pin)
                    error('svd:svd:EmptyPin', ...
                        ['The property Pin is not defined. You must set Pin ',...
                        'to a valid value.'])
                end
                %simulation setup code
                if coder.target('MATLAB')
                    
                    %simulinkIO code         
                    obj.IsIOEnable = matlabshared.svd.internal.isSimulinkIoEnabled;
                    if obj.IsIOEnable
                        %handle to deploy and connect to IO server
                        obj.DeployAndConnectHandle=matlabshared.ioclient.DeployAndConnectHandle;
                        %get a connected IOclient object   
                        obj.DeployAndConnectHandle.getConnectedIOClient();

                        obj.dIOClient = matlabshared.ioclient.peripherals.DigitalIO;
                        %get the hardware name
                        hardwareName=lower(strrep(obj.DeployAndConnectHandle.BoardName,' ','')); 
                        
                        if(isnumeric(obj.Pin))
                            obj.PinInternalIO =uint32(obj.Pin);
                        else
                            %check whether Pin is not a string of numeric value.
                            if(isempty(str2num(obj.Pin)))
                                %list of Psuedo pin values available
                                [~,enumPinValues]=enumeration(['codertarget.simulinkIO.',hardwareName,'.pinInterface']);
                                %validate the Psuedo Pin
                                if(any(strcmp(enumPinValues,obj.Pin)))
                                    %convert to numeric Pin value
                                    obj.PinInternalIO  = uint32(codertarget.simulinkIO.(hardwareName).pinInterface.(obj.Pin));
                                else
                                    throwAsCaller(MException(message('svd:svd:PinNotFound',obj.Pin,'Digital IO')));
                                end                         
                            else
                                validateattributes(str2double(obj.Pin),{'numeric'},{'nonnegative','integer','scalar','real'},'','Digital Pin');                               
                                try
                                    codertarget.simulinkIO.(hardwareName).pinInterface(str2double(obj.Pin));
                                catch
                                    throwAsCaller(MException(message('svd:svd:PinNotFound',obj.Pin,'Digital IO')));
                                end
                                obj.PinInternalIO =uint32(str2double(obj.Pin));                             
                            end
                        end                     
                        
                        
                        try
                            if (obj.Direction == "output")
                                status=obj.dIOClient.configureDigitalPinInternal(obj.DeployAndConnectHandle.IoProtocol,obj.PinInternalIO ,'DigitalOutput');
                            else
                                status=obj.dIOClient.configureDigitalPinInternal(obj.DeployAndConnectHandle.IoProtocol,obj.PinInternalIO ,'DigitalInput');
                            end                       
                            
                        catch
                            throwAsCaller(MException(message('svd:svd:ConfigurePinFailedReconnect',obj.Pin,'Digital Input/Output')));
                        end
                        
                        if(status)
                            throwAsCaller(MException(message('svd:svd:ConfigurePinFailedPinConflict',obj.Pin,'Digital Input/Output')));
                        end   

                    end
                end
                
            end
        end
        
        function writeDigitalPin(obj,u)
            if coder.target('Rtw')
                % Read logical state of the pin 
                % void MW_digitalIO_write(uint32_T pin, boolean_T value)
                coder.ceval('MW_digitalIO_write',obj.MW_DIGITALIO_HANDLE,logical(u));
            else
                if coder.target('MATLAB')
                    if obj.IsIOEnable
                        % Place simulation setup code here
                        % configure pin and write to it                   
                        obj.dIOClient.writeDigitalPinInternal(obj.DeployAndConnectHandle.IoProtocol,obj.PinInternalIO ,u);
                    else
                        %do nothing
                    end
                end
            end
        end
        
        function y = readDigitalPin(obj)
            y = coder.nullcopy(false);
            if coder.target('Rtw')
                % Read logical state of the pin 
                % boolean_T MW_digitalIO_read(uint32_T pin)
                
                y = coder.ceval('MW_digitalIO_read',obj.MW_DIGITALIO_HANDLE);
            else
                if coder.target('MATLAB')
                    if obj.IsIOEnable
                        % Place simulation setup code here
                        % configure pin and read from it                       
                        y = logical(obj.dIOClient.readDigitalPinInternal(obj.DeployAndConnectHandle.IoProtocol,obj.PinInternalIO ));
                    else
                        %do nothing
                    end
                end
            end
        end
        
        function close(obj)
            if coder.target('Rtw')
                % Close digital I/O device 
                % void MW_digitalIO_close(uint32_T pin)
                coder.ceval('MW_digitalIO_close',obj.MW_DIGITALIO_HANDLE);
            else
                if coder.target('MATLAB')
                    if obj.IsIOEnable
                        % Place simulation close code here
                        % delete the client object                        
                        obj.dIOClient.unconfigureDigitalPinInternal(obj.DeployAndConnectHandle.IoProtocol,obj.PinInternalIO );
                        obj.DeployAndConnectHandle.deleteConnectedIOClient;
                    else
                        %do nothing
                    end
                end
            end
        end
    end
    
    %% Run-time methods
    methods (Access=protected)
        function setupImpl(obj)
            open(obj);
        end
        
        function varargout = stepImpl(obj,varargin)         
            
            if obj.DirectionEnum == SVDTypes.MW_Input
                varargout{1} = readDigitalPin(obj);
            else
                writeDigitalPin(obj,varargin{1});
            end
        end
        
        function releaseImpl(obj)
            close(obj);
        end
    end
    
    %% Define input/output dimensions
    methods (Access=protected)  
        function num = getNumInputsImpl(obj)
            if obj.DirectionEnum == SVDTypes.MW_Input
                num = 0;
            else
                num = 1;
            end
        end
        
        function num = getNumOutputsImpl(obj)
            if obj.DirectionEnum == SVDTypes.MW_Input
                num = 1;
            else
                num = 0;
            end
        end
    end
    
    %% Input properties
    methods (Access=protected)
        
        
        function validateInputsImpl(obj,varargin)
            if ~coder.target('Rtw')
                % Run this always in Simulation
                if obj.DirectionEnum == SVDTypes.MW_Output
                    validateattributes(varargin{1},{'logical','numeric'},...
                        {'scalar','binary'},'','input');
                end
            end
        end
    end
    
    %% Output properties
    methods (Access=protected)
        
        function varargout = isOutputFixedSizeImpl(~,~)
            varargout{1} = true;
        end
        
        
        function varargout = isOutputComplexImpl(~)
            varargout{1} = false;
        end
        
        function varargout = getOutputSizeImpl(~)
            varargout{1} = [1,1];
        end
        
        function varargout = getOutputDataTypeImpl(obj)
            if obj.DirectionEnum == SVDTypes.MW_Input
                varargout{1} = 'logical';
            end
        end
    end
    
    methods (Static, Access=protected)
        function simMode = getSimulateUsingImpl(~)
            simMode = 'Interpreted execution';
        end
        
        function isVisible = showSimulateUsingImpl
            isVisible = false;
        end
    end
    
    methods(Static, Access=protected)
        function header = getHeaderImpl()
            header = matlab.system.display.Header(mfilename('class'),...
                'ShowSourceLink', false, ...
                'Title','Digital Read/Write', ...
                'Text', [['Read or write the logical state of a digital input pin.' newline newline] ...
                'Do not assign the same Pin number to multiple blocks within a model.']);
        end
        
        function [groups, PropertyList] = getPropertyGroupsImpl
            % Pin Pin
            PinProp = matlab.system.display.internal.Property('Pin', 'Description', 'svd:svd:PinPrompt');
            % Direction
            DirectionProp = matlab.system.display.internal.Property('Direction', 'Description', 'svd:svd:DirectionPrompt');
           
            % Property list
            PropertyListOut = {PinProp, DirectionProp};

            % Create mask display
            Group = matlab.system.display.Section(...
                'PropertyList',PropertyListOut);
            
            groups = Group;

            % Output property list if requested
            if nargout > 1
                PropertyList = PropertyListOut;
            end
        end
    end
end

%% Local functions
%[EOF]
