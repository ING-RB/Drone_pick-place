classdef SVDGenerator < handle
    %SVDGENERATOR Simulink virtual device generator.

%   Copyright 2015-2023 The MathWorks, Inc.
    
    properties
        HwConstructor
        Name
        DeviceClass  = 'Digital Read'
        Logo         = 'Generic'
        SourceFiles  = {}
        SourcePaths  = {}
        IncludeFiles = {}
        IncludePaths = {}
        Libraries    = {}
        LinkerFlags  = {}
        Defines      = {}
        EnableViewPinMapButton = false
        ViewPinMapOpenFcn
        ViewPinMapCloseFcn
    end
    
    properties (Constant)
        SupportedPropertyDataTypes = {'numeric','string'};
        %SupportedPropertyDataTypes = {'numeric','string','stringedit'};
    end
    
    properties (Access = private, Dependent)
        SVDDevice
        SVDHeaderFile
    end
    
    %properties(Access = private, Constant)
    properties(Hidden, Constant)
        AvailableDeviceClasses = { ...
            'Digital Read', ...
            'Digital Write', ...
            'Analog Input', ...
            'PWM Output', ...
            'I2C Master Read', ...
            'I2C Master Write', ...
            'I2C Slave Read', ...
            'I2C Slave Write', ...
            'SPI Register Read', ...
            'SPI Register Write', ...
            'SPI Master Transfer', ...
            'SCI Read', ...
            'SCI Write'};
    end
    
    %% Public interface
    methods 
        function obj = SVDGenerator(varargin)
            % Support name-value pair arguments
            p = inputParser;
            addParameter(p,'HwConstructor','');
            addParameter(p,'Name','');
            addParameter(p,'DeviceClass','Digital Read');
            addParameter(p,'Logo','Generic');
            addParameter(p,'SourceFiles',{});
            addParameter(p,'SourcePaths',{});
            addParameter(p,'IncludeFiles',{});
            addParameter(p,'IncludePaths',{});
            addParameter(p,'Libraries',{});
            addParameter(p,'LinkerFlags',{});
            addParameter(p,'Defines',{});
            addParameter(p,'EnableViewPinMapButton',false);
            addParameter(p,'ViewPinMapOpenFcn','');
            addParameter(p,'ViewPinMapCloseFcn','');
            parse(p,varargin{:});
            
            % Set object properties
            obj.HwConstructor = p.Results.HwConstructor;
            obj.Name          = p.Results.Name;
            obj.DeviceClass   = p.Results.DeviceClass;
            obj.Logo          = p.Results.Logo;
            obj.SourceFiles   = p.Results.SourceFiles;
            obj.SourcePaths   = p.Results.SourcePaths;
            obj.IncludeFiles  = p.Results.IncludeFiles;
            obj.IncludePaths  = p.Results.IncludePaths;
            obj.Libraries     = p.Results.Libraries;
            obj.LinkerFlags   = p.Results.LinkerFlags;
            obj.Defines       = p.Results.Defines;
            obj.EnableViewPinMapButton       = p.Results.EnableViewPinMapButton;
            obj.ViewPinMapOpenFcn  = p.Results.ViewPinMapOpenFcn;
            obj.ViewPinMapCloseFcn = p.Results.ViewPinMapCloseFcn;
        end
    end
    
    %% Set and get methods
    methods    
        function set.HwConstructor(obj,value)
            validateattributes(value, {'char'}, {}, ...
                '', 'HwConstructor');
            obj.HwConstructor = value;
        end
        
        function set.Logo(obj,value)
            validateattributes(value, {'char'}, {'nonempty', 'row'}, ...
                '', 'Logo');
            obj.Logo = value;
        end
        
        function set.DeviceClass(obj,value)
            value = validatestring(value,obj.AvailableDeviceClasses);
            obj.DeviceClass = value;
        end
        
        function set.SourceFiles(obj,value)
            if ~iscell(value)
                error('svd:svd:InputIsNotCellString', ...
                    'Input must be a cell array of strings.');
            end
            obj.SourceFiles = value;
        end
        
        function set.SourcePaths(obj,value)
            if ~iscell(value)
                error('svd:svd:InputIsNotCellString', ...
                    'Input must be a cell array of strings.');
            end
            obj.SourcePaths = value;
        end
        
        function set.IncludeFiles(obj,value)
            if ~iscell(value)
                error('svd:svd:InputIsNotCellString', ...
                    'Input must be a cell array of strings.');
            end
            obj.IncludeFiles = value;
        end
        
        function set.IncludePaths(obj,value)
            if ~iscell(value)
                error('svd:svd:InputIsNotCellString', ...
                    'Input must be a cell array of strings.');
            end
            obj.IncludePaths = value;
        end
        
        function set.Libraries(obj,value)
            if ~iscell(value)
                error('svd:svd:InputIsNotCellString', ...
                    'Input must be a cell array of strings.');
            end
            obj.Libraries = value;
        end
        
        function set.LinkerFlags(obj,value)
            if ~iscell(value)
                error('svd:svd:InputIsNotCellString', ...
                    'Input must be a cell array of strings.');
            end
            obj.LinkerFlags = value;
        end
        
        function set.Defines(obj,value)
            if ~iscell(value)
                error('svd:svd:InputIsNotCellString', ...
                    'Input must be a cell array of strings.');
            end
            obj.Defines = value;
        end
        
        function set.EnableViewPinMapButton(obj,value)
            validateattributes(value,{'numeric','logical'},{'scalar','binary'},'','EnableViewPinMapButton');
            obj.EnableViewPinMapButton = value;
        end
        
        function set.ViewPinMapOpenFcn(obj,value)
            if ~isempty(value)
                validateattributes(value, {'char'}, {'nonempty', 'row'}, ...
                    '', 'ViewPinMapOpenFcn');
            end
            obj.ViewPinMapOpenFcn = strtrim(value);
        end
        
        function set.ViewPinMapCloseFcn(obj,value)
            if ~isempty(value)
                validateattributes(value, {'char'}, {'nonempty', 'row'}, ...
                    '', 'ViewPinMapCloseFcn');
            end
            obj.ViewPinMapCloseFcn = strtrim(value);
        end
        
        function ret = get.SVDDevice(obj)
            switch (obj.DeviceClass)
                case 'Digital Write'
                    ret = 'DigitalWrite';
                case 'Digital Read'
                    ret = 'DigitalRead';
                case 'Analog Input'
                    ret = 'AnalogInput';
                case 'PWM Output'
                    ret = 'PWMOutput';
                case 'I2C Master Read'
                    ret = 'I2CMasterRead';
                case 'I2C Master Write'
                    ret = 'I2CMasterWrite';
                case 'I2C Slave Read'
                    ret = 'I2CSlaveRead';
                case 'I2C Slave Write'
                    ret = 'I2CSlaveWrite';
                case 'SPI Register Read'
                    ret = 'SPIRegisterRead';
                case 'SPI Register Write'
                    ret = 'SPIRegisterWrite';
                case 'SPI Master Transfer'
                    ret = 'SPIMasterTransfer';
                case 'SCI Read'
                    ret = 'SCIRead';
                case 'SCI Write'
                    ret = 'SCIWrite';
            end
        end
        
        function ret = get.SVDHeaderFile(obj)
            switch (obj.DeviceClass)
                case {'Digital Read','Digital Write'}
                    ret = 'MW_digitalIO.h';
                case 'Analog Input'
                    ret = 'MW_AnalogIn.h';
                case 'PWM Output'
                    ret = 'MW_PWM.h';
                case {'I2C Master Read', 'I2C Master Write', 'I2C Slave Read', 'I2C Slave Write'}
                    ret = 'MW_I2C.h';
                case {'SPI Register Read', 'SPI Register Write', 'SPI Master Transfer'}
                    ret = 'MW_SPI.h';
                case {'SCI Read', 'SCI Write'}
                    ret = 'MW_SCI.h';
            end
        end
        
        function generateSystemObject(obj,PropertyDataType)
            %generateSystemObject
            if nargin < 2
                PropertyDataType = 'numeric';
            else
                PropertyDataType = validatestring(PropertyDataType,obj.SupportedPropertyDataTypes);
            end
            % Validate Hw object
            obj.validateHwObject(obj.HwConstructor,obj.DeviceClass);
            switch (obj.DeviceClass)
                case 'Digital Write'
                    generateDigitalWrite(obj,PropertyDataType);
                case 'Digital Read'
                    generateDigitalRead(obj,PropertyDataType);
                case 'Analog Input'
                    generateAnalogInput(obj,PropertyDataType);
                case 'PWM Output'
                    generatePWMOutput(obj,PropertyDataType);
                case 'I2C Master Read'
                    generateI2CMasterRead(obj,PropertyDataType);
                case 'I2C Master Write'
                    generateI2CMasterWrite(obj,PropertyDataType);
                case 'I2C Slave Read'
                    generateI2CSlaveRead(obj,PropertyDataType);
                case 'I2C Slave Write'
                    generateI2CSlaveWrite(obj,PropertyDataType);
                case {'SPI Register Read', 'SPI Register Write', 'SPI Master Transfer'}
                    generateSPIMasterBlock(obj,PropertyDataType);
                case {'SCI Read', 'SCI Write'}
                    generateSCIBlock(obj,PropertyDataType);
            end
        end
    end
    
    methods (Access = private)
        function generateDigitalWrite(obj,PropertyDataType)
            %% Generate class definition
            s = StringWriter;
            hline = 'Set the logical value of a digital output pin.';
            s = writeClassdef(obj, s, hline);
            
            % Generate Pin properties
            s = generateDigitalIOPinProperties(obj,s,PropertyDataType);
            
            % Generate constructor
            s = generateDigitalIOConstructor(obj,s);
            
            % Generate coder.ExternalDependecy interface
            s = generateCoderExternalDependency(obj,s);
            
            % Generate View pin map button
            s = generateViewPinMapButton(obj,s,'Pin');
            
            % Close classdef
            s = finalizeClassdef(obj,s);
            
            % Generate System object
            s.indentCode;
            s.write([obj.SVDDevice '.m']);
        end
        
        function generateDigitalRead(obj,PropertyDataType)
            %% Generate class definition
            
            s = StringWriter;
            hline = 'Read the logical state of a digital input pin.';
            s = writeClassdef(obj,s,hline);
            
            % Generate Pin properties
            s = generateDigitalIOPinProperties(obj,s,PropertyDataType);
            
            % Generate constructor
            s = generateDigitalIOConstructor(obj,s);
            
            % Generate coder.ExternalDependecy interface
            s = generateCoderExternalDependency(obj,s);
            
            % Generate View pin map button
            s = generateViewPinMapButton(obj,s,'Pin');
            
            % Close classdef
            s = finalizeClassdef(obj,s);
            
            % Generate System object
            s.indentCode;
            s.write([obj.SVDDevice '.m']);
        end
        
        function generatePWMOutput(obj,PropertyDataType)
            %% Generate class definition
            s = StringWriter;
            hline = ['%PWMOUT Generate square waveform on the specified analog output pin.',newline,...
                '% The block input controls the duty cycle of the square waveform. An',newline,...
                '% input value of 0 produces a 0 percent duty cycle and an input value',newline,...
                '% of 100 produces a 100 percent duty cycle.',newline,...
                '% Enter the number of the analog output pin. Do not assign the same pin',newline,...
                '% number to multiple blocks within a model.'];
            s = writeClassdef(obj, s, hline);
            
            % Generate Pin properties
            s = generatePWMOutputPinProperties(obj,s,PropertyDataType);
            
            % Generate constructor
            s.addcr('methods');
            s.addcr(['function obj = ' obj.SVDDevice '(varargin)']);
            s.addcr('coder.allowpcode(''plain'');');
            % Include files using coder.cinclude
            % Limitation: The include files added in updateBuildInfo are
            % not added to model header file. Work around is to include
            % file in constructor itself
            addIncludeFiles(obj,s);
            if ~isempty(obj.HwConstructor)
                s.addcr(['obj.Hw = ' obj.HwConstructor ';']);
            end
            s.addcr(['obj.Logo = ''' obj.Logo, ''';']);
            s.addcr('setProperties(obj,nargin,varargin{:});');
            s.addcr('end');
            s.addcr('end');
            s.addcr;
            
            % Generate coder.ExternalDependecy interface
            s = generateCoderExternalDependency(obj, s);
            
            % Generate View pin map button
            s = generateViewPinMapButton(obj,s,'Pin');
            
            % Close classdef
            s = finalizeClassdef(obj, s);
            
            % Generate System object
            s.indentCode;
            s.write([obj.SVDDevice '.m']);
        end
        
        function generateAnalogInput(obj,PropertyDataType)
            %% Generate class definition
            s = StringWriter;
            hline = ['%ANALOGINPUT Measure the voltage of an analog input pin.' newline '%' newline ...
                '% The block output emits the voltage as a decimal value (0.0-1.0, minimum to maximum). The maximum voltage is determined by the input reference voltage, VREFH, which defaults to 3.3 volt.' newline '%' newline ...
                '% Do not assign the same Pin number to multiple blocks within a model.'];
            s = writeClassdef(obj, s, hline);
            
            % Generate Pin properties
            s = generateAnalogInputPinProperties(obj,s,PropertyDataType);
            
            % Generate constructor
            s.addcr('methods');
            s.addcr(['function obj = ' obj.SVDDevice '(varargin)']);
            s.addcr('coder.allowpcode(''plain'');');
            % Include files using coder.cinclude
            % Limitation: The include files added in updateBuildInfo are
            % not added to model header file. Work around is to include
            % file in constructor itself
            addIncludeFiles(obj,s);
            if ~isempty(obj.HwConstructor)
                s.addcr(['obj.Hw = ' obj.HwConstructor ';']);
            end
            s.addcr(['obj.Logo = ''' obj.Logo, ''';']);
            s.addcr('setProperties(obj,nargin,varargin{:});');
            s.addcr('end');
            s.addcr('end');
            s.addcr;
            
            % Generate coder.ExternalDependecy interface
            s = generateCoderExternalDependency(obj, s);
            
            % Generate View pin map button
            s = generateViewPinMapButton(obj,s,'Pin');
            
            % Close classdef
            s = finalizeClassdef(obj, s);
            
            % Generate System object
            s.indentCode;
            s.write([obj.SVDDevice '.m']);
        end
        
        function generateI2CMasterRead(obj,PropertyDataType)
            %% Generate class definition
            s = StringWriter;
            hline = ['Read data from an I2C slave device or an I2C slave device register.' newline '%' newline ...
                '%The block outputs the values received as an 1-D uint8 array.'];
            s = writeClassdef(obj, s, hline);
            
            s = generateI2CModuleProperties(obj,s,PropertyDataType);
            
            %% Generate constructor
            s.addcr('methods');
            s.addcr(['function obj = ' obj.SVDDevice '(varargin)']);
            s.addcr('coder.allowpcode(''plain'');');
            % Include files using coder.cinclude
            % Limitation: The include files added in updateBuildInfo are
            % not added to model header file. Work around is to include
            % file in constructor itself
            addIncludeFiles(obj,s);
            if ~isempty(obj.HwConstructor)
                s.addcr(['obj.Hw = ' obj.HwConstructor ';']);
            end
            s.addcr(['obj.Logo = ''' obj.Logo, ''';']);
            s.addcr('setProperties(obj,nargin,varargin{:});');
            s.addcr('end');
            s.addcr('end');
            s.addcr;
            
            % Generate coder.ExternalDependecy interface
            s = generateCoderExternalDependency(obj, s);
            
            % Generate View pin map button
            s = generateViewPinMapButton(obj,s,'I2CModule','-inherit',1);
            
            % Close classdef
            s = finalizeClassdef(obj, s);
            
            % Generate System object
            s.indentCode;
            s.write([obj.SVDDevice '.m']);
        end
        
        function generateI2CMasterWrite(obj,PropertyDataType)
            %% Generate class definition
            s = StringWriter;
            hline = ['Write data to an I2C slave device or an I2C slave device register.' newline '%' newline ...
                '%The block accepts a 1-D array of type uint8.'];
            s = writeClassdef(obj, s, hline);
            
            s = generateI2CModuleProperties(obj,s,PropertyDataType);
            
            % Generate constructor
            s.addcr('methods');
            s.addcr(['function obj = ' obj.SVDDevice '(varargin)']);
            s.addcr('coder.allowpcode(''plain'');');
            % Include files using coder.cinclude
            % Limitation: The include files added in updateBuildInfo are
            % not added to model header file. Work around is to include
            % file in constructor itself
            addIncludeFiles(obj,s);
            if ~isempty(obj.HwConstructor)
                s.addcr(['obj.Hw = ' obj.HwConstructor ';']);
            end
            s.addcr(['obj.Logo = ''' obj.Logo, ''';']);
            s.addcr('setProperties(obj,nargin,varargin{:});');
            s.addcr('end');
            s.addcr('end');
            s.addcr;
            
            % Generate coder.ExternalDependecy interface
            s = generateCoderExternalDependency(obj, s);
            
            % Generate View pin map button
            s = generateViewPinMapButton(obj,s,'I2CModule','-inherit',1);
            
            % Close classdef
            s = finalizeClassdef(obj, s);
            
            % Generate System object
            s.indentCode;
            s.write([obj.SVDDevice '.m']);
        end
        
        function generateI2CSlaveRead(obj,PropertyDataType)
            %% Generate class definition
            s = StringWriter;
            hline = ['Read data from an I2C master device.' newline '%' newline ...
                '%The block outputs the values received as an 1-D uint8 array.'];
            s = writeClassdef(obj, s, hline);
            
            s = generateI2CModuleProperties(obj,s,PropertyDataType);
            
            %% Generate constructor
            s.addcr('methods');
            s.addcr(['function obj = ' obj.SVDDevice '(varargin)']);
            s.addcr('coder.allowpcode(''plain'');');
            % Include files using coder.cinclude
            % Limitation: The include files added in updateBuildInfo are
            % not added to model header file. Work around is to include
            % file in constructor itself
            addIncludeFiles(obj,s);
            if ~isempty(obj.HwConstructor)
                s.addcr(['obj.Hw = ' obj.HwConstructor ';']);
            end
            s.addcr(['obj.Logo = ''' obj.Logo, ''';']);
            s.addcr('setProperties(obj,nargin,varargin{:});');
            s.addcr('end');
            s.addcr('end');
            s.addcr;
            
            % Generate coder.ExternalDependecy interface
            s = generateCoderExternalDependency(obj, s);
            
            % Generate View pin map button
            s = generateViewPinMapButton(obj,s,'I2CModule','-inherit',1);
            
            % Close classdef
            s = finalizeClassdef(obj, s);
            
            % Generate System object
            s.indentCode;
            s.write([obj.SVDDevice '.m']);
        end
        
        function generateI2CSlaveWrite(obj,PropertyDataType)
            %% Generate class definition
            s = StringWriter;
            hline = ['Write data to an I2C master device.' newline '%' newline ...
                '%The block accepts a 1-D array of type uint8.'];
            s = writeClassdef(obj, s, hline);
            
            s = generateI2CModuleProperties(obj,s,PropertyDataType);
            
            % Generate constructor
            s.addcr('methods');
            s.addcr(['function obj = ' obj.SVDDevice '(varargin)']);
            s.addcr('coder.allowpcode(''plain'');');
            % Include files using coder.cinclude
            % Limitation: The include files added in updateBuildInfo are
            % not added to model header file. Work around is to include
            % file in constructor itself
            addIncludeFiles(obj,s);
            if ~isempty(obj.HwConstructor)
                s.addcr(['obj.Hw = ' obj.HwConstructor ';']);
            end
            s.addcr(['obj.Logo = ''' obj.Logo, ''';']);
            s.addcr('setProperties(obj,nargin,varargin{:});');
            s.addcr('end');
            s.addcr('end');
            s.addcr;
            
            % Generate coder.ExternalDependecy interface
            s = generateCoderExternalDependency(obj, s);
            
            % Generate View pin map button
            s = generateViewPinMapButton(obj,s,'I2CModule','-inherit',1);
            
            % Close classdef
            s = finalizeClassdef(obj, s);
            
            % Generate System object
            s.indentCode;
            s.write([obj.SVDDevice '.m']);
        end

        function generateSPIMasterBlock(obj,PropertyDataType)
            %% Generate class definition
            s = StringWriter;
            hline = 'Set the logical value of a digital output pin.';
            derivedclasses = 'matlabshared.svd.SPIMasterBlock';
            if isequal(obj.DeviceClass, 'SPI Register Read')
                derivedclasses = sprintf('%s ...\n& %s',derivedclasses, 'matlabshared.svd.BlockSampleTime');
            end
            
            s = writeClassdef(obj, s, hline, derivedclasses);
            
            % Generate SPI properties
            s = generateSPIProperties(obj,s,PropertyDataType);

            % Generate constructor
            s.addcr('methods');
            s.addcr(['function obj = ' obj.SVDDevice '(varargin)']);
            s.addcr('coder.allowpcode(''plain'');');
            % Include files using coder.cinclude
            % Limitation: The include files added in updateBuildInfo are
            % not added to model header file. Work around is to include
            % file in constructor itself
            addIncludeFiles(obj,s);
            if ~isempty(obj.HwConstructor)
                s.addcr(['obj.Hw = ' obj.HwConstructor ';']);
            else
                s.addcr('obj.Hw = [];');
            end
            s.addcr(['obj.Logo = ''' obj.Logo, ''';']);
            if isequal(obj.DeviceClass,'SPI Register Read')
                BlockFunction = 'Read';
            elseif isequal(obj.DeviceClass,'SPI Register Write')
                BlockFunction = 'Write';
            else
                BlockFunction = 'Transfer';
            end
            s.addcr(['obj.BlockFunction = ''' BlockFunction ''';']);
            s.addcr('setProperties(obj,nargin,varargin{:});');
            s.addcr('end');
            s.addcr('end');
            s.addcr;

            % Sample time management
            if contains(derivedclasses,'matlabshared.svd.BlockSampleTime')
                s.addcr('properties (Nontunable)');
                    s.addcr('%SampleTime Sample time');
                    s.addcr('SampleTime = -1;');
                s.addcr('end');
                s.addcr;
                s.addcr('methods');
                    s.addcr('function set.SampleTime(obj,newTime)');
                    s.addcr('coder.extrinsic(''error'');');
                    s.addcr('coder.extrinsic(''message'');');

                    s.addcr('newTime = matlabshared.svd.internal.validateSampleTime(newTime);');
                    s.addcr('obj.SampleTime = newTime;');
                    s.addcr('end');
                s.addcr('end');
            end
            
            %% Generate block header and mask
            s = generateSPIBlockMask(obj,s);
            
            %% Generate coder.ExternalDependecy interface
            s = generateCoderExternalDependency(obj,s);
            
            % Close classdef
            s = finalizeClassdef(obj,s);
            
            % Generate System object
            s.indentCode;
            s.write([obj.SVDDevice '.m']);
        end
        
        function generateSCIBlock(obj,PropertyDataType)
            %% Generate class definition
            s = StringWriter;
            hline = 'Set the logical value of a digital output pin.';
            if isequal(obj.DeviceClass,'SCI Read')
                derivedclasses = 'matlabshared.svd.SCIRead';
            else
                derivedclasses = 'matlabshared.svd.SCIWrite';
            end
            
            s = writeClassdef(obj, s, hline, derivedclasses);
            
            % Generate SPI properties
            s = generateSCIProperties(obj,s,PropertyDataType);

            % Generate constructor
            s.addcr('methods');
            s.addcr(['function obj = ' obj.SVDDevice '(varargin)']);
            s.addcr('coder.allowpcode(''plain'');');
            % Include files using coder.cinclude
            % Limitation: The include files added in updateBuildInfo are
            % not added to model header file. Work around is to include
            % file in constructor itself
            addIncludeFiles(obj,s);
            if ~isempty(obj.HwConstructor)
                s.addcr(['obj.Hw = ' obj.HwConstructor ';']);
            else
                s.addcr('obj.Hw = [];');
            end
            s.addcr(['obj.Logo = ''' obj.Logo, ''';']);
            s.addcr('setProperties(obj,nargin,varargin{:});');
            s.addcr('end');
            s.addcr('end');
            s.addcr;
            
            %% Generate coder.ExternalDependecy interface
            s = generateCoderExternalDependency(obj,s);
            
            % Close classdef
            s = finalizeClassdef(obj,s);
            
            % Generate System object
            s.indentCode;
            s.write([obj.SVDDevice '.m']);
        end

        function s = writeClassdef(obj, s, hline, BaseClass)
            if nargin < 4
                BaseClass = ['matlabshared.svd.' obj.SVDDevice];
            end

            s.addcr(['classdef ' obj.SVDDevice ' < ' BaseClass ' ...']);
            s.addcr('& coder.ExternalDependency');
            s.addcr(['%' obj.SVDDevice ' ' hline]);
            s.addcr('%');
            s.addcr('');
            s.addcr('%#codegen');
            s.addcr('');
        end
        
        function s = generateDigitalIOConstructor(obj,s)
            %generateDigitalIOConstructor
            s.addcr('methods');
            s.addcr(['function obj = ' obj.SVDDevice '(varargin)']);
            s.addcr('coder.allowpcode(''plain'');');
            % Include files using coder.cinclude
            % Limitation: The include files added in updateBuildInfo are
            % not added to model header file. Work around is to include
            % file in constructor itself
            addIncludeFiles(obj,s);
            
            if ~isempty(obj.HwConstructor)
                s.addcr(['obj.Hw = ' obj.HwConstructor ';']);
            end
            
            s.addcr(['obj.Logo = ''' obj.Logo, ''';']);
            s.addcr('setProperties(obj,nargin,varargin{:});');
            s.addcr('end');
            s.addcr('end');
            s.addcr;
        end
        
        function s = finalizeClassdef(~, s)
            s.addcr('end');
            s.addcr('%[EOF]');
        end
        
        function s = generateCoderExternalDependency(obj, s)
            if (numel(obj.SourcePaths) > 1) && ...
                    (numel(obj.SourcePaths) ~= numel(obj.SourceFiles))
                error('svd:svd:MismatchSourceFilesPaths','Source files and source paths are not matching');
            end
            
            s.addcr('methods (Static)');
            s.addcr('function name = getDescriptiveName(~)');
            s.addcr(['    name = ''' obj.DeviceClass ''';']);
            s.addcr('end');
            s.addcr('');
            s.addcr('function b = isSupportedContext(context)');
            s.addcr('    b = context.isCodeGenTarget(''rtw'') || context.isCodeGenTarget(''sfun'');');
            s.addcr('end');
            s.addcr('');
            s.addcr('function updateBuildInfo(buildInfo, context)');
            s.addcr('if context.isCodeGenTarget(''rtw'') || context.isCodeGenTarget(''sfun'')');
            s.addcr('    % Digital I/O interface');
            s.addcr('    svdDir = matlabshared.svd.internal.getRootDir;');
            s.addcr('    addIncludePaths(buildInfo,fullfile(svdDir,''include''));');
            s.addcr(['   addIncludeFiles(buildInfo,''' obj.SVDHeaderFile ''');']);
            if isempty(obj.SourcePaths)
                for k = 1:numel(obj.SourceFiles)
                    [p, n, e] = fileparts(obj.SourceFiles{k});
                    srcFile = [n, e];
                    s.addcr(['addSourceFiles(buildInfo,''' srcFile ''', ''' p ''', ''SkipForSil'');']);
                end
            elseif isscalar(obj.SourcePaths)
                p = obj.SourcePaths{1};
                try
                    eval(obj.SourcePaths{1});
                catch exc
                    p = ['''' p ''''];
                end
                
                for k = 1:numel(obj.SourceFiles)
                    s.addcr(['addSourceFiles(buildInfo,''' obj.SourceFiles{k} ''', ' p ', ''SkipForSil'');']);
                end
            else
                for k = 1:numel(obj.SourceFiles)
                    p = obj.SourcePaths{k};
                    try
                        eval(p);
                    catch exc
                        p = ['''' p '''']; %#ok<AGROW>
                    end
                    
                    s.addcr(['addSourceFiles(buildInfo,''' obj.SourceFiles{k} ''', ' p ', ''SkipForSil'');']);
                end
            end
            for k = 1:numel(obj.IncludePaths)
                p = obj.IncludePaths{k};
                try
                    eval(p);
                catch exc
                    p = ['''' p '''']; %#ok<AGROW>
                end
                s.addcr(['addIncludePaths(buildInfo,' p ');']);
            end
            for k = 1:numel(obj.IncludeFiles)
                s.addcr(['addIncludeFiles(buildInfo,''' obj.IncludeFiles{k} ''');']);
            end
            for k = 1:numel(obj.Libraries)
                [p, n, e] = fileparts(obj.Libraries{k});
                libFile = [n, e];
                s.addcr(['addLinkObjects(buildInfo,''' libFile ''', ''' p ''', 1000, true, true);']);
            end
            for k = 1:numel(obj.LinkerFlags)
                s.addcr(['addLinkFlags(buildInfo,''' obj.LinkerFlags{k} ''');']);
            end
            for k = 1:numel(obj.Defines)
                s.addcr(['addDefines(buildInfo,''' obj.Defines{k} ''');']);
            end
            s.addcr('end');
            s.addcr('end');
            s.addcr('end');
        end
        
        % Generate Pin properties for Digital IO
        function s = generateDigitalIOPinProperties(obj,s,pinDataType)
            if ~isempty(obj.HwConstructor)
                try
                    hw = feval(obj.HwConstructor);
                catch ME
                    baseME = MException('svd:svd:InvalidHwObjectConstructor',...
                        'Error while construction a hardware object.');
                    EX = addCause(baseME, ME);
                    throw(EX);
                end
            else
                hw = [];
            end
            
            if ~isempty(obj.HwConstructor)
                if isequal(pinDataType,'numeric')
                    pins = getDigitalPinNumber(hw);
                else
                    pins = getDigitalPinName(hw);
                end
            else
                if isequal(pinDataType,'numeric')
                    pins = 0;
                else
                    pins = {'1'};
                end
            end
            
            % Generate Pin property
            s = generatePinProperties(obj,s,pins,'isValidDigitalPin',pinDataType);
        end
        
        % Generate Pin properties for PWM Output
        function s = generatePWMOutputPinProperties(obj,s,pinDataType)
            if ~isempty(obj.HwConstructor)
                try
                    hw = feval(obj.HwConstructor);
                catch ME
                    baseME = MException('svd:svd:InvalidHwObjectConstructor',...
                        'Error while construction a hardware object.');
                    EX = addCause(baseME, ME);
                    throw(EX);
                end
            else
                hw = [];
            end
            
            if ~isempty(obj.HwConstructor)
                if isequal(pinDataType,'numeric')
                    pins = getPWMPinNumber(hw);
                else
                    pins = getPWMPinName(hw);
                end
            else
                if isequal(pinDataType,'numeric')
                    pins = 0;
                else
                    pins = {'1'};
                end
            end
            
            % Generate Pin property
            s = generatePinProperties(obj,s,pins,'isValidPWMPin',pinDataType);
        end
        
        % Generate Pin properties for PWM Output
        function s = generateAnalogInputPinProperties(obj,s,pinDataType)
            if ~isempty(obj.HwConstructor)
                try
                    hw = feval(obj.HwConstructor);
                catch ME
                    baseME = MException('svd:svd:InvalidHwObjectConstructor',...
                        'Error while construction a hardware object.');
                    EX = addCause(baseME, ME);
                    throw(EX);
                end
            else
                hw = [];
            end
            
            if ~isempty(obj.HwConstructor)
                if isequal(pinDataType,'numeric')
                    pins = getAnalogPinNumber(hw);
                else
                    pins = getAnalogPinName(hw);
                end
            else
                if isequal(pinDataType,'numeric')
                    pins = 0;
                else
                    pins = {'1'};
                end
            end
            
            % Generate Pin property
            s = generatePinProperties(obj,s,pins,'isValidAnalogPin',pinDataType);
        end
        
        % Generate I2CModule properties for I2C
        function s = generateI2CModuleProperties(obj,s,PropertyDataType)
            if ~isempty(obj.HwConstructor)
                try
                    hw = feval(obj.HwConstructor);
                catch ME
                    baseME = MException('svd:svd:InvalidHwObjectConstructor',...
                        'Error while construction a hardware object.');
                    EX = addCause(baseME, ME);
                    throw(EX);
                end
            else
                hw = [];
            end
            
            if ~isempty(obj.HwConstructor)
                if isequal(PropertyDataType,'numeric')
                    I2CModuleProperty = getI2CModuleNumber(hw);
                else
                    I2CModuleProperty = getI2CModuleName(hw);
                end
            else
                if isequal(PropertyDataType,'numeric')
                    I2CModuleProperty = 0;
                else
                    I2CModuleProperty = {'1'};
                end
            end
            
            % Generate I2C Module property
            s = generateAbstractProperties(obj,s,'I2CModule','I2C module',I2CModuleProperty,...
                'isValidI2CModule','message(''svd:svd:ModuleNotFound'',''I2C'',value)', PropertyDataType);
        end
        
        % Generate Pin properties for device classes
        function s = generatePinProperties(obj,s,pins,pinValidateFcnName,pinDataType)
            % Create Nontuanble Pin property
            s.addcr('properties (Nontunable)');
            s.addcr('%Pin Pin');
            if ~isempty(obj.HwConstructor)
                if isequal(pinDataType,'numeric')
                    s.addcr(['Pin = ' num2str(pins(1)) ';']);
                else
                    s.addcr(['Pin = ''' pins{1} ''';']);
                end
            else
                if isequal(pinDataType,'numeric')
                    s.addcr('Pin = 0;');
                else
                    s.addcr('Pin = ''1'';');
                end
            end
            s.addcr('end');
            
            if isequal(pinDataType,'string') && ~isempty(obj.HwConstructor)
                % Create list for Nontunable property
                s.addcr('properties (Constant, Hidden)');
                s.addcr(['PinSet = matlab.system.StringSet(' obj.convertCell2String(pins) ')']);
                s.addcr('end');
            end
            
            % Set method for Pin for validation
            s.addcr('methods');
            s.addcr('function set.Pin(obj,value)');
            s.addcr('if ~coder.target(''Rtw'') && ~coder.target(''Sfun'')');
            s.addcr('if ~isempty(obj.Hw)');
            s.addcr(['if ~' pinValidateFcnName '(obj.Hw,value)']); %#ok<*MCSUP>
            s.addcr(['error(message(''svd:svd:PinNotFound'',value,''' obj.DeviceClass '''));']);
            s.addcr('end');
            s.addcr('end');
            s.addcr('end');
            if ~isequal(pinDataType,'numeric')
                s.addcr('obj.Pin = value;');
            else
                s.addcr('obj.Pin = uint32(value);');
            end
            s.addcr('end');
            s.addcr('end');
        end

        % Generate SPI properties for Digital IO
        function s = generateSPIProperties(obj,s,PropertyDataType)
            if ~isempty(obj.HwConstructor)
                try
                    hw = feval(obj.HwConstructor);
                catch ME
                    baseME = MException('svd:svd:InvalidHwObjectConstructor',...
                        'Error while construction a hardware object.');
                    EX = addCause(baseME, ME);
                    throw(EX);
                end
            else
                hw = [];
            end
            
            % Digital Pin properties
            if ~isempty(obj.HwConstructor)
                try
                    if isequal(PropertyDataType,'numeric')
                        pins = getSlaveSelectPinNumber(hw);
                    else
                        pins = getSlaveSelectPinName(hw);
                    end
                catch ME
                    baseME = MException('svd:svd:InvalidHwObjectConstructor',...
                        'Functions getSlaveSelectPinNumber and getSlaveSelectPinName are not defined in a hardware object.');
                    EX = addCause(baseME, ME);
                    throw(EX);
                end
            else
                if isequal(PropertyDataType,'numeric')
                    pins = 0;
                else
                    pins = {'1'};
                end
            end

            % SPI Module properites
            if ~isempty(obj.HwConstructor)
                try
                    if isequal(PropertyDataType,'numeric')
                        spimodules = getSPIModuleNumber(hw);
                    else
                        spimodules = getSPIModuleName(hw);
                    end
                catch ME
                    baseME = MException('svd:svd:InvalidHwObjectConstructor',...
                        'Functions getSPIModuleNumber and getSPIModuleName are not defined in a hardware object.');
                    EX = addCause(baseME, ME);
                    throw(EX);
                end
            else
                if isequal(PropertyDataType,'numeric')
                    spimodules = 0;
                else
                    spimodules = {'1'};
                end
            end
            
            % Generate SPI Module abstract property
            s = generateAbstractProperties(obj,s,'SPIModule','SPI module',spimodules,'isValidSPIModule','message(''svd:svd:ModuleNotFound'',''SPI'',value)', PropertyDataType);
            
            % Generate Pin property
            s = generateAbstractProperties(obj,s,'Pin','Slave select pin',pins,'isValidSlaveSelectPin',['message(''svd:svd:PinNotFound'',value,''' obj.DeviceClass ''')'], PropertyDataType,'obj.SPIModule');
        end
        
        function s = generateSPIBlockMask(obj,s)
            %% Generate Property group and block header
            s.addcr('methods(Static, Access=protected)');
            s.addcr('function header = getHeaderImpl()');
            s.addcr('header = matlab.system.display.Header(mfilename(''class''),...');
            s.addcr('''ShowSourceLink'', false, ...');
            s.addcr(['''Title'',''' obj.DeviceClass ''', ...']);
            if isequal(obj.DeviceClass, 'SPI Register Read')
                s.addcr('''Text'', [''Read data from registers of an SPI slave device.'' char(10) char(10) ...');
                s.addcr('''Initiate an SPI write sequence starting with the SPI slave register address followed by an SPI read sequence getting data of specified type and length from the slave registers.'' char(10) char(10) ...');
                s.addcr('''The block outputs the values received as an [Nx1] array.'']);');                
            elseif isequal(obj.DeviceClass, 'SPI Register Write')
                s.addcr('''Text'', [''Write data to registers of an SPI slave device.'' char(10) char(10) ...');
                s.addcr('''Initiate an SPI write sequence starting with the SPI slave register address followed by block input data.'' char(10) char(10) ...');
                s.addcr('''The block accepts the values as an [Nx1] or [1xN] array.'']);');
            elseif isequal(obj.DeviceClass, 'SPI Master Transfer')
                s.addcr('''Text'', [''Write data to and read data from an SPI slave device.'' char(10) char(10) ...');
                s.addcr('''The block accepts a 1-D array of data type int8, uint8, int16, uint16, int32, uint32, single or double. The block outputs an array of the same size and data type as the input values.'' char(10) char(10) ...');
                s.addcr('''The block can be used along with byte pack/unpack blocks to support heterogeneous data type transfers.'']);');
            end
            s.addcr('end');
            s.addcr('');
            s.addcr('function [groups, PropertyListMain, PropertyListAdvanced] = getPropertyGroupsImpl');
            if isequal(obj.DeviceClass, 'SPI Register Read')
                s.addcr('[groups, PropertyListMainOut, PropertyListAdvancedOut, SampleTimeProp] = matlabshared.svd.SPIMasterBlock.getPropertyGroupsImpl;');
                s.addcr('groups(1).PropertyList{end+1} = SampleTimeProp;');
            else
                s.addcr('[groups, PropertyListMainOut, PropertyListAdvancedOut, ~] = matlabshared.svd.SPIMasterBlock.getPropertyGroupsImpl;');
            end
            % Output property list if requested
            s.addcr('if nargout > 1');
            s.addcr('PropertyListMain = PropertyListMainOut;');
            s.addcr('PropertyListAdvanced = PropertyListAdvancedOut;');
            s.addcr('end');
            % Generate View pin map button
            s = generateViewPinMapButton(obj,s,'SPIModule','-append','groups(1)');
            
            s.addcr('end');
            s.addcr('end');
            
            % Add sample time method for SPI Master Read device class
            if isequal(obj.DeviceClass, 'SPI Register Read')
                s.addcr('methods(Access=protected)');
                s.addcr('function sts = getSampleTimeImpl(obj)')
                s.addcr('sts = getSampleTimeImpl@matlabshared.svd.BlockSampleTime(obj);')
                s.addcr('end');
                s.addcr('end');
            end
            s.addcr();
        end
        
        % Generate SPI properties for Digital IO
        function s = generateSCIProperties(obj,s,PropertyDataType)
            if ~isempty(obj.HwConstructor)
                try
                    hw = feval(obj.HwConstructor);
                catch ME
                    baseME = MException('svd:svd:InvalidHwObjectConstructor',...
                        'Error while construction a hardware object.');
                    EX = addCause(baseME, ME);
                    throw(EX);
                end
            else
                hw = [];
            end
            
            % SCI Module properites
            if ~isempty(obj.HwConstructor)
                try
                    if isequal(PropertyDataType,'numeric')
                        scimodules = getSCIModuleNumber(hw);
                    else
                        scimodules = getSCIModuleName(hw);
                    end
                catch ME
                    baseME = MException('svd:svd:InvalidHwObjectConstructor',...
                        'Functions getSPIModuleNumber and getSPIModuleName are not defined in a hardware object.');
                    EX = addCause(baseME, ME);
                    throw(EX);
                end
            else
                if isequal(PropertyDataType,'numeric')
                    scimodules = 0;
                else
                    scimodules = {'0'};
                end
            end
            
            % Generate SCI Module abstract property
            s = generateAbstractProperties(obj,s,'SCIModule','SCI module',scimodules,'isValidSCIModule','message(''svd:svd:ModuleNotFound'',''SCI'',value)', PropertyDataType);
        end

        % Generate Pin properties for device classes
        function s = generateAbstractProperties(obj,s,PropertyName,PropertyDescription,PropertyValues,PropertyValidateFcn,ErrorMessage, PropertyDataType,ValidateFcnArgStr)
            if nargin <= 8
                ValidateFcnArgStr = [];
            else
                ValidateFcnArgStr = [',' ValidateFcnArgStr];
            end
            
            if ~ischar(PropertyName)
                error('svd:svd:InvalidPropertyName',...
                    'PropertyName should be a valid string representing abstract property.');
            end
            if ~ischar(PropertyDescription)
                error('svd:svd:InvalidPropertyDescription',...
                    'PropertyDescription should be a valid string describing PropertyName.');
            end
            if ~ischar(PropertyValidateFcn)
                error('svd:svd:InvalidPropertyValidateFcn',...
                    'PropertyValidateFcn should be a valid function name for validating PropertyName.');
            end
            
            % Create Nontuanble property
            s.addcr('properties (Nontunable)');
            s.addcr(sprintf('%%%s %s', PropertyName,PropertyDescription));
            if ~isempty(obj.HwConstructor)
                if isequal(PropertyDataType,'numeric')
                    s.addcr([PropertyName ' = ' num2str(PropertyValues(1)) ';']);
                else
                    s.addcr([PropertyName ' = ''' PropertyValues{1} ''';']);
                end
            else
                if isequal(PropertyDataType,'numeric')
                    s.addcr([PropertyName ' = 0;']);
                else
                    s.addcr([PropertyName ' = ''1'';']);
                end
            end
            s.addcr('end');
            
            if isequal(PropertyDataType,'string') && ~isempty(obj.HwConstructor)
                % Create list for Nontunable property
                s.addcr('properties (Constant, Hidden)');
                s.addcr([PropertyName 'Set = matlab.system.StringSet(' obj.convertCell2String(PropertyValues) ')']);
                s.addcr('end');
            end
            
            % Set method for Pin for validation
            s.addcr('methods');
            s.addcr(['function set.' PropertyName '(obj,value)']);
            s.addcr('if ~coder.target(''Rtw'') && ~coder.target(''Sfun'')');
            s.addcr('if ~isempty(obj.Hw)');
            s.addcr(['if ~' PropertyValidateFcn '(obj.Hw' ValidateFcnArgStr ',value)']); %#ok<*MCSUP>
            s.addcr(['error(' ErrorMessage ');']);
            s.addcr('end');
            s.addcr('end');
            s.addcr('end');
            if ~isequal(PropertyDataType,'numeric')
                s.addcr(['obj.' PropertyName ' = value;']);
            else
                s.addcr(['obj.' PropertyName ' = uint32(value);']);
            end
            s.addcr('end');
            s.addcr('end');
            s.addcr('');
        end
        
        % generateViewPinMapButton Adds view pin map button above the
        % propName
        % - addMethod = '-inherit'
        %   The function responsible for adding pin map button already
        %   defined getPropertyGroupsImpl in higher classes
        % - addMethodValue = group index to which pin map action to be
        % added
        % - addMethod = '-append'
        %   No new getPropertyGroupsImpl function is created rather
        %   appended during generating getPropertyGroupsImpl.
        % - addMethodValue = group name to which pin map action to be added
        function s = generateViewPinMapButton(obj, s, propName, addMethod, addMethodValue)
            % Process addMethod and addMehtodValue arguments
            if nargin > 3
                if isequal(addMethod, '-inherit')
                    if ~isnumeric(addMethodValue)
                        error(message('svd:svd:GenViewPinMapButtonIdxError'));
                    end
                    CreateFunction = true;
                elseif isequal(addMethod, '-append')
                    if ~ischar(addMethodValue)
                        error(message('svd:svd:GenViewPinMapButtonNameError'));
                    end
                    CreateFunction = false;
                else
                    error(message('svd:svd:GenViewPinMapButtonInvalidArg'));
                end
            else
                addMethod = [];
                addMethodValue = [];
                CreateFunction = true;
            end
            
            if obj.EnableViewPinMapButton && ~isempty(obj.ViewPinMapOpenFcn)
                % s.addcr('%#ok<*EMFH>');
                % Start function
                if CreateFunction
                    s.addcr('methods (Static, Access=protected)');
                    s.addcr('function group = getPropertyGroupsImpl')
                end
                
                if isempty(addMethod)
                    s.addcr('group = matlab.system.display.Section(mfilename(''class''));');
                elseif isequal(addMethod, '-inherit')
                    s.addcr(['group = matlabshared.svd.' obj.SVDDevice '.getPropertyGroupsImpl;']);
                else % addMethod = 'append'
                    % No getPropertyGroupsImpl method is created
                end
                
                % Generate viewPinMap button
                s.addcr(['viewPinMapAction = matlab.system.display.Action(@' obj.ViewPinMapOpenFcn ', ...']);
                s.addcr('''Alignment'', ''right'', ...');
                s.addcr(['''Placement'',''' propName ''',...']);
                s.addcr('''Label'', ''View pin map'');');
                if ~isempty(obj.ViewPinMapCloseFcn)
                    s.addcr('matlab.system.display.internal.setCallbacks(viewPinMapAction, ...');
                    % s.addcr(['''DialogAppliedFcn'', @' obj.ViewPinMapOpenFcn ', ...']);
                    s.addcr(['''SystemDeletedFcn'', @' obj.ViewPinMapCloseFcn ');']);
                end
                
                if isempty(addMethod)
                    s.addcr('group.Actions = viewPinMapAction;');
                elseif isequal(addMethod, '-inherit')
                    s.addcr(['group(' num2str(addMethodValue) ').Actions = viewPinMapAction;']);
                else % addMethod = 'append'
                    s.addcr([addMethodValue '.Actions = viewPinMapAction;']);
                end
                
                % End function
                if CreateFunction
                    s.addcr('end');
                    s.addcr('end');
                end
            end
        end
        
        function s = addIncludeFiles(obj,s)
            if isempty(obj.IncludeFiles)
                return;
            end
            s.addcr('if coder.target(''Rtw'') || coder.target(''Sfun'')');
            for k = 1:numel(obj.IncludeFiles)
                s.addcr(['coder.cinclude(''' obj.IncludeFiles{k} ''');']);
            end
            s.addcr('end');
        end
    end
    
    
    methods (Access = public, Static = true)
        function validateHwObject(hwConstructor, DeviceClass)
            % It is OK not to provide a Hardware object
            if isempty(hwConstructor)
                return;
            end
            
            validatestring(DeviceClass, matlabshared.svd.SVDGenerator.AvailableDeviceClasses);
            
            % Construct a hardware object
            try
                hw = feval(hwConstructor);
            catch ME
                baseME = MException('svd:svd:InvalidHwObjectConstructor',...
                    'Error while construction a hardware object.');
                EX = addCause(baseME, ME);
                throw(EX);
            end
            
            % Test Digital IO details
            switch(DeviceClass)
                case {'Digital Read', ...
                        'Digital Write', ...
                        'SPI Register Read', ...
                        'SPI Register Write', ...
                        'SPI Master Transfer'}
                    matlabshared.svd.SVDGenerator.validateDigitalIOHardwareDetails(hw);
            end
            
            % Test Analog Input API
            switch(DeviceClass)
                case 'Analog Input'                    
                    matlabshared.svd.SVDGenerator.validateAnalogInputHardwareDetails(hw);
            end
            
            % Test PWM output API
            switch(DeviceClass)
                case 'PWM Output'
                    matlabshared.svd.SVDGenerator.validatePWMHardwareDetails(hw);
            end
            
            % Test I2C API
            switch (DeviceClass)
                case {'I2C Master Read', ...
                        'I2C Master Write', ...
                        'I2C Slave Read', ...
                        'I2C Slave Write'}
                    matlabshared.svd.SVDGenerator.validateI2CHardwareDetails(hw);
            end
            
            % Test SPI API
            switch (DeviceClass)
                case {'SPI Register Read', ...
                        'SPI Register Write', ...
                        'SPI Master Transfer'}
                    matlabshared.svd.SVDGenerator.validateSPIHardwareDetails(hw);
            end
            
            % Test SCI APIs
            switch (DeviceClass)
                case {'SCI Read', ...
                        'SCI Write'}
                    matlabshared.svd.SVDGenerator.validateSCIHardwareDetails(hw);
            end
        end
        
        function CellString = convertCell2String(CellArray)
            if ~iscell(CellArray)
                error('Input should be a cell array of strings.');
            end
            
            CellString = '{';
            for i = 1:numel(CellArray)
                
                CellString = [CellString '''' CellArray{i} '''' ',']; %#ok<AGROW>
            end
            CellString(end) = '}';
        end
    end
    
    methods (Static = true, Hidden)
        function validateDigitalIOHardwareDetails(hw)
            % Test getDigitalPinNumber API
            pinNumbers = getDigitalPinNumber(hw);
            try
                validateattributes(pinNumbers, ...
                    {'numeric'},{'integer','vector'});
            catch ME
                baseME = MException('svd:svd:InvalidTypeForPin',...
                    ['getDigitalPinNumber method of the hardware object must ', ...
                    'return a numeric vector ', ...
                    'representing pin numbers available for digital I/O.']);
                EX = addCause(baseME, ME);
                throw(EX);
            end
            
            % Test getDigitalPinName API
            pinNames = getDigitalPinName(hw);
            if ~iscell(pinNames)
                error('svd:svd:InvalidTypeForPin', ...
                    ['getDigitalPinName method of the hardware object must ', ...
                    'return a cell array of strings ', ...
                    'representing pins available for digital I/O.']);
            else
                if ~all(cellfun(@ischar, pinNames))
                    error('svd:svd:InvalidTypeForPin', ...
                        ['getDigitalPinName method of the hardware object must ', ...
                        'return a cell array of strings ', ...
                        'representing pins available for digital I/O. ', ...
                        'Some of the elements in the returned cell array are not a string.'])
                end
                
                pinname_spaces = regexp(pinNames,'[^\w_]','once');
                if ~all(cellfun(@isempty, pinname_spaces))
                    error('svd:svd:InvalidTypeForPin', ...
                        ['getDigitalPinName method of the hardware object must ', ...
                        'return a cell array of strings ', ...
                        'representing pins available for digital I/O. ', ...
                        'The names should contain only characters within [A-Za-z0-9_].'])
                end
            end
            if ~all(size(pinNames) == size(pinNumbers))
                error('svd:svd:InvalidTypeForPin', ...
                    ['getDigitalPinName method of the hardware object must ', ...
                    'return a cell array with the same size as the numeric ', ...
                    'array returned by getDigitalPinNumber.'])
            end
            for k = 1:numel(pinNumbers)
                tmpName = getDigitalPinName(hw,pinNumbers(k));
                if ~ismember(tmpName,pinNames)
                    error('svd:svd:InvalidPinName', ...
                        ['The pin name, %s, returned for pin number %d ', ...
                        ' is not in the cell array getDigitalPinName ', ...
                        'method of the hardware object.'],tmpName,uint32(pinNumbers(k)));
                end
                tmpNumber = getDigitalPinNumber(hw,tmpName);
                if tmpNumber ~= pinNumbers(k)
                    error('svd:svd:InvalidPinNumber', ...
                        ['The pin number, %d, returned for pin named %s ', ...
                        ' is not in array getDigitalPinNumber ', ...
                        'method of the hardware object.'],tmpNumber,tmpName);
                end
            end
        end
        
        function validateAnalogInputHardwareDetails(hw)
            % Test getDigitalPinNumber API
            pinNumbers = getAnalogPinNumber(hw);
            try
                validateattributes(pinNumbers, ...
                    {'numeric'},{'integer','vector'});
            catch ME
                baseME = MException('svd:svd:InvalidTypeForPin',...
                    ['getAnalogPinNumber method of the hardware object must ', ...
                    'return a numeric vector ', ...
                    'representing pin numbers available for analog output.']);
                EX = addCause(baseME, ME);
                throw(EX);
            end
            
            pinNames = getAnalogPinName(hw);
            if ~iscell(pinNames)
                error('svd:svd:InvalidTypeForPin', ...
                    ['getAnalogPinName method of the hardware object must ', ...
                    'return a cell array of strings ', ...
                    'representing pins available for analog output.']);
            else
                if ~all(cellfun(@ischar, pinNames))
                    error('svd:svd:InvalidTypeForPin', ...
                        ['getAnalogPinName method of the hardware object must ', ...
                        'return a cell array of strings ', ...
                        'representing pins available for analog output. ', ...
                        'Some of the elements in the returned cell array are not a string.'])
                end
                
                pinname_spaces = regexp(pinNames,'[^\w_]','once');
                if ~all(cellfun(@isempty, pinname_spaces))
                    error('svd:svd:InvalidTypeForPin', ...
                        ['getAnalogPinName method of the hardware object must ', ...
                        'return a cell array of strings ', ...
                        'representing pins available for analog output. ', ...
                        'The names should contain only characters within [A-Za-z0-9_].'])
                end
            end
            if ~all(size(pinNames) == size(pinNumbers))
                error('svd:svd:InvalidTypeForPin', ...
                    ['getAnalogPinName method of the hardware object must ', ...
                    'return a cell array with the same size as the numeric ', ...
                    'array returned by getAnalogPinNumber.'])
            end
            for k = 1:numel(pinNumbers)
                tmpName = getAnalogPinName(hw,pinNumbers(k));
                if ~ismember(tmpName,pinNames)
                    error('svd:svd:InvalidPinName', ...
                        ['The pin name, %s, returned for pin number %d ', ...
                        ' is not in the cell array getAnalogPinName ', ...
                        'method of the hardware object.'],tmpName,uint32(pinNumbers(k)));
                end
                tmpNumber = getAnalogPinNumber(hw,tmpName);
                if tmpNumber ~= pinNumbers(k)
                    error('svd:svd:InvalidPinNumber', ...
                        ['The pin number, %d, returned for pin named %s ', ...
                        ' is not in array getAnalogPinNumber ', ...
                        'method of the hardware object.'],tmpNumber,tmpName);
                end
            end
        end
        
        function validatePWMHardwareDetails(hw)
            pinNumbers = getPWMPinNumber(hw);
            try
                validateattributes(pinNumbers, ...
                    {'numeric'},{'integer','vector'});
            catch ME
                baseME = MException('svd:svd:InvalidTypeForPin',...
                    ['getPWMPinNumber method of the hardware object must ', ...
                    'return a numeric vector ', ...
                    'representing pin numbers available for PWM.']);
                EX = addCause(baseME, ME);
                throw(EX);
            end
            
            pinNames = getPWMPinName(hw);
            if ~iscell(pinNames)
                error('svd:svd:InvalidTypeForPin', ...
                    ['getPWMPinName method of the hardware object must ', ...
                    'return a cell array of strings ', ...
                    'representing pins available for PWM.']);
            else
                if ~all(cellfun(@ischar, pinNames))
                    error('svd:svd:InvalidTypeForPin', ...
                        ['getPWMPinName method of the hardware object must ', ...
                        'return a cell array of strings ', ...
                        'representing pins available for PWM. ', ...
                        'Some of the elements in the returned cell array are not a string.'])
                end
                
                pinname_spaces = regexp(pinNames,'[^\w_]','once');
                if ~all(cellfun(@isempty, pinname_spaces))
                    error('svd:svd:InvalidTypeForPin', ...
                        ['getPWMPinName method of the hardware object must ', ...
                        'return a cell array of strings ', ...
                        'representing pins available for PWM. ', ...
                        'The names should contain only characters within [A-Za-z0-9_].'])
                end
            end
            if ~all(size(pinNames) == size(pinNumbers))
                error('svd:svd:InvalidTypeForPin', ...
                    ['getPWMPinName method of the hardware object must ', ...
                    'return a cell array with the same size as the numeric ', ...
                    'array returned by getPWMPinNumber.'])
            end
            for k = 1:numel(pinNumbers)
                tmpName = getPWMPinName(hw,pinNumbers(k));
                if ~ismember(tmpName,pinNames)
                    error('svd:svd:InvalidPinName', ...
                        ['The pin name, %s, returned for pin number %d ', ...
                        ' is not in the cell array getPWMPinName ', ...
                        'method of the hardware object.'],tmpName,uint32(pinNumbers(k)));
                end
                tmpNumber = getPWMPinNumber(hw,tmpName);
                if tmpNumber ~= pinNumbers(k)
                    error('svd:svd:InvalidPinNumber', ...
                        ['The pin number, %d, returned for pin named %s ', ...
                        ' is not in array getPWMPinNumber ', ...
                        'method of the hardware object.'],tmpNumber,tmpName);
                end
            end
        end
        
        function validateI2CHardwareDetails(hw)
            I2CNumbers = getI2CModuleNumber(hw);
            try
                validateattributes(I2CNumbers, ...
                    {'numeric'},{'integer','vector'});
            catch ME
                baseME = MException('svd:svd:InvalidTypeForPin',...
                    ['getI2CModuleNumber method of the hardware object must ', ...
                    'return a numeric vector ', ...
                    'representing available I2C peripherals.']);
                EX = addCause(baseME, ME);
                throw(EX);
            end
            
            I2CNames = getI2CModuleName(hw);
            if ~iscell(I2CNames)
                error('svd:svd:InvalidTypeForPin', ...
                    ['getI2CModuleName method of the hardware object must ', ...
                    'return a cell array of strings ', ...
                    'representing names of available I2C peripherals.']);
            else
                if ~all(cellfun(@ischar, I2CNames))
                    error('svd:svd:InvalidTypeForPin', ...
                        ['getI2CModuleName method of the hardware object must ', ...
                        'return a cell array of strings ', ...
                        'representing names of available I2C peripherals. ', ...
                        'Some of the elements in the returned cell array are not a string.'])
                end
                
                i2cnames_spaces = regexp(I2CNames,'[^\w_]','once');
                if ~all(cellfun(@isempty, i2cnames_spaces))
                    error('svd:svd:InvalidTypeForPin', ...
                        ['getI2CModuleName method of the hardware object must ', ...
                        'return a cell array of strings ', ...
                        'representing names of available I2C peripherals. ', ...
                        'The names should contain only characters within [A-Za-z0-9_].'])
                end
            end
            if ~all(size(I2CNames) == size(I2CNumbers))
                error('svd:svd:InvalidTypeForPin', ...
                    ['getI2CModuleName method of the hardware object must ', ...
                    'return a cell array with the same size as the numeric ', ...
                    'array returned by getI2CModuleNumber.'])
            end
            for k = 1:numel(I2CNumbers)
                tmpName = getI2CModuleName(hw,I2CNumbers(k));
                if ~ismember(tmpName,I2CNames)
                    error('svd:svd:InvalidPinName', ...
                        ['The pin name, %s, returned for I2C peripheral %d ', ...
                        ' is not in the cell array getI2CModuleName ', ...
                        'method of the hardware object.'],tmpName,uint32(I2CNumbers(k)));
                end
                tmpNumber = getI2CModuleNumber(hw,tmpName);
                if tmpNumber ~= I2CNumbers(k)
                    error('svd:svd:InvalidPinNumber', ...
                        ['The I2C number, %d, returned for I2C named %s ', ...
                        ' is not in array getI2CModuleNumber ', ...
                        'method of the hardware object.'],tmpNumber,tmpName);
                end
            end
        end
        
        function validateSPIHardwareDetails(hw)
            SPINumbers = getSPIModuleNumber(hw);
            try
                validateattributes(SPINumbers, ...
                    {'numeric'},{'integer','vector'});
            catch ME
                baseME = MException('svd:svd:InvalidTypeForPin',...
                    ['getSPIModuleNumber method of the hardware object must ', ...
                    'return a numeric vector ', ...
                    'representing available SPI peripherals.']);
                EX = addCause(baseME, ME);
                throw(EX);
            end
            
            SPINames = getSPIModuleName(hw);
            if ~iscell(SPINames)
                error('svd:svd:InvalidTypeForPin', ...
                    ['getSPIModuleName method of the hardware object must ', ...
                    'return a cell array of strings ', ...
                    'representing names of available SPI peripherals.']);
            else
                if ~all(cellfun(@ischar, SPINames))
                    error('svd:svd:InvalidTypeForPin', ...
                        ['getSPIModuleName method of the hardware object must ', ...
                        'return a cell array of strings ', ...
                        'representing names of available SPI peripherals. ', ...
                        'Some of the elements in the returned cell array are not a string.'])
                end
                
                spinames_spaces = regexp(SPINames,'[^\w_]','once');
                if ~all(cellfun(@isempty, spinames_spaces))
                    error('svd:svd:InvalidTypeForPin', ...
                        ['getSPIModuleName method of the hardware object must ', ...
                        'return a cell array of strings ', ...
                        'representing names of available SPI peripherals. ', ...
                        'The names should contain only characters within [A-Za-z0-9_].'])
                end
            end
            if ~all(size(SPINames) == size(SPINumbers))
                error('svd:svd:InvalidTypeForPin', ...
                    ['getSPIModuleName method of the hardware object must ', ...
                    'return a cell array with the same size as the numeric ', ...
                    'array returned by getSPIModuleNumber.'])
            end
            for k = 1:numel(SPINumbers)
                tmpName = getSPIModuleName(hw,SPINumbers(k));
                if ~ismember(tmpName,SPINames)
                    error('svd:svd:InvalidPinName', ...
                        ['The pin name, %s, returned for SPI peripheral %d ', ...
                        ' is not in the cell array getSPIModuleName ', ...
                        'method of the hardware object.'],tmpName,uint32(SPINumbers(k)));
                end
                tmpNumber = getSPIModuleNumber(hw,tmpName);
                if tmpNumber ~= SPINumbers(k)
                    error('svd:svd:InvalidPinNumber', ...
                        ['The SPI number, %d, returned for SPI named %s ', ...
                        ' is not in array getSPIModuleNumber ', ...
                        'method of the hardware object.'],tmpNumber,tmpName);
                end
            end
            
            % Slave select pin validation
            pinNumbers = getSlaveSelectPinNumber(hw);
            try
                validateattributes(pinNumbers, ...
                    {'numeric'},{'integer','vector'});
            catch ME
                baseME = MException('svd:svd:InvalidTypeForPin',...
                    ['getSlaveSelectPinNumber method of the hardware object must ', ...
                    'return a numeric vector ', ...
                    'representing pin numbers available for SPI Slave selection.']);
                EX = addCause(baseME, ME);
                throw(EX);
            end
            
            pinNames = getSlaveSelectPinName(hw);
            if ~iscell(pinNames)
                error('svd:svd:InvalidTypeForPin', ...
                    ['getSlaveSelectPinName method of the hardware object must ', ...
                    'return a cell array of strings ', ...
                    'representing pins available for SPI Slave selection.']);
            else
                if ~all(cellfun(@ischar, pinNames))
                    error('svd:svd:InvalidTypeForPin', ...
                        ['getSlaveSelectPinName method of the hardware object must ', ...
                        'return a cell array of strings ', ...
                        'representing pins available for SPI Slave selection. ', ...
                        'Some of the elements in the returned cell array are not a string.'])
                end
                
                pinname_spaces = regexp(pinNames,'[^\w_]','once');
                if ~all(cellfun(@isempty, pinname_spaces))
                    error('svd:svd:InvalidTypeForPin', ...
                        ['getSlaveSelectPinName method of the hardware object must ', ...
                        'return a cell array of strings ', ...
                        'representing pins available for SPI Slave selection. ', ...
                        'The names should contain only characters within [A-Za-z0-9_].'])
                end
            end
            if ~all(size(pinNames) == size(pinNumbers))
                error('svd:svd:InvalidTypeForPin', ...
                    ['getSlaveSelectPinName method of the hardware object must ', ...
                    'return a cell array with the same size as the numeric ', ...
                    'array returned by getSlaveSelectPinNumber.'])
            end
            for k = 1:numel(pinNumbers)
                tmpName = getSlaveSelectPinName(hw,pinNumbers(k));
                if ~ismember(tmpName,pinNames)
                    error('svd:svd:InvalidPinName', ...
                        ['The pin name, %s, returned for pin number %d ', ...
                        ' is not in the cell array getSlaveSelectPinName ', ...
                        'method of the hardware object.'],tmpName,uint32(pinNumbers(k)));
                end
                tmpNumber = getSlaveSelectPinNumber(hw,tmpName);
                if tmpNumber ~= pinNumbers(k)
                    error('svd:svd:InvalidPinNumber', ...
                        ['The pin number, %d, returned for pin named %s ', ...
                        ' is not in array getSlaveSelectPinNumber ', ...
                        'method of the hardware object.'],tmpNumber,tmpName);
                end
            end
        end
        
        function validateSCIHardwareDetails(hw)
            SCINumbers = getSCIModuleNumber(hw);
            try
                validateattributes(SCINumbers, ...
                    {'numeric'},{'integer','vector'});
            catch ME
                baseME = MException('svd:svd:InvalidTypeForPin',...
                    ['getSCIModuleNumber method of the hardware object must ', ...
                    'return a numeric vector ', ...
                    'representing available SCI peripherals.']);
                EX = addCause(baseME, ME);
                throw(EX);
            end
            
            SCINames = getSCIModuleName(hw);
            if ~iscell(SCINames)
                error('svd:svd:InvalidTypeForPin', ...
                    ['getSCIModuleName method of the hardware object must ', ...
                    'return a cell array of strings ', ...
                    'representing names of available SCI peripherals.']);
            else
                if ~all(cellfun(@ischar, SCINames))
                    error('svd:svd:InvalidTypeForPin', ...
                        ['getSCIModuleName method of the hardware object must ', ...
                        'return a cell array of strings ', ...
                        'representing names of available SCI peripherals. ', ...
                        'Some of the elements in the returned cell array are not a string.'])
                end
                
                i2cnames_spaces = regexp(SCINames,'[^\w_]','once');
                if ~all(cellfun(@isempty, i2cnames_spaces))
                    error('svd:svd:InvalidTypeForPin', ...
                        ['getSCIModuleName method of the hardware object must ', ...
                        'return a cell array of strings ', ...
                        'representing names of available SCI peripherals. ', ...
                        'The names should contain only characters within [A-Za-z0-9_].'])
                end
            end
            if ~all(size(SCINames) == size(SCINumbers))
                error('svd:svd:InvalidTypeForPin', ...
                    ['getSCIModuleName method of the hardware object must ', ...
                    'return a cell array with the same size as the numeric ', ...
                    'array returned by getSCIModuleNumber.'])
            end
            for k = 1:numel(SCINumbers)
                tmpName = getSCIModuleName(hw,SCINumbers(k));
                if ~ismember(tmpName,SCINames)
                    error('svd:svd:InvalidPinName', ...
                        ['The pin name, %s, returned for SCI peripheral %d ', ...
                        ' is not in the cell array getSCIModuleName ', ...
                        'method of the hardware object.'],tmpName,uint32(SCINumbers(k)));
                end
                tmpNumber = getSCIModuleNumber(hw,tmpName);
                if tmpNumber ~= SCINumbers(k)
                    error('svd:svd:InvalidPinNumber', ...
                        ['The SCI number, %d, returned for SCI named %s ', ...
                        ' is not in array getSCIModuleNumber ', ...
                        'method of the hardware object.'],tmpNumber,tmpName);
                end
            end
        end
    end
end

%[EOF]

    
