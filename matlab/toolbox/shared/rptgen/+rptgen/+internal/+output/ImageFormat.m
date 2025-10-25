classdef ImageFormat < handle
    %IMAGEFORMAT Define image formats supported by the Report Explorer
    %
    %   ImageFormat properties:
    %     IsSL       - True if format is valid for Simulink
    %     IsSF      - True if format is valid for Stateflow
    %     IsHG      - True if format is valid for MATLAB graphics
    %     ID        - Format print command ID
    %     Name      - Format name
    %     Extension - Format file extension
    %     Driver    - Format print command driver
    %     Options   - Print command options for format
    %
    %   ImageFormat methods:
    %    (static)
    %     getFormat       - Get format by its print command ID (e.g., png)
    %     getAllFormatsSL - Get formats valid for Simulink
    %     getAllFormatsSF - Get formats valid for Stateflow
    %     getAllFormatsHG - Get formats valid for MATLAB graphics
    %    (dynamic)
    %     getID           - Get format's print command id
    %     getName         - Get format's name
    %     getExtension    - Get formats's file extension
    %     getDriver       - Get formats's print driver (e.g., -dpng)
    %     getSL           - True if format is valid for Simulink
    %     getSF           - True if format is valid for Stateflow
    %     getHG           - True if format is valid for MATLAB graphics
    %     getOptions      - Get print command options for this format
    %     getPrintCmd     - Get print command to generate this format
    
    %    Copyright 2017-2023 MathWorks, Inc.
    
    methods (Static)
        
        function format = getFormat(id)
            import rptgen.internal.output.ImageFormat
            registry = ImageFormat.Registry;
            format = registry(char(id));
        end
        
    end
    
    methods (Static)
        
        
        function formats = getAllFormatsSL()
            % Returns an array of ImageFormats that are valid for SL
            import rptgen.internal.output.ImageFormat
            registry = ImageFormat.Registry;
            formats = values(registry);
            formats  = formats(cellfun(@(format) getSL(format),formats));
            formatNames = cellfun(@(format) getName(format),formats);
            [~,idxs] = sort(formatNames);
            formats = formats(idxs);
        end
        
        function formats = getAllFormatsSF()
            % Returns an array of ImageFormats that are valid for Stateflow
            import rptgen.internal.output.ImageFormat
            registry = ImageFormat.Registry;
            formats = values(registry);
            formats  = formats(cellfun(@(format) getSF(format),formats));
            formatNames = cellfun(@(format) getName(format),formats);
            [~,idxs] = sort(formatNames);
            formats = formats(idxs);
        end
        
        function formats = getAllFormatsHG()
            % Returns an array of ImageFormats that are valid for
            % MATLAB Graphics
            import rptgen.internal.output.ImageFormat
            registry = ImageFormat.Registry;
            formats = values(registry);
            formats  = formats(cellfun(@(format) getHG(format),formats));
            formatNames = cellfun(@(format) getName(format),formats);
            [~,idxs] = sort(formatNames);
            formats = formats(idxs);
        end
        
    end
    
    properties
        IsSL logical = false
        IsSF logical = false
        IsHG logical = false
        
        ID {mustBeObjectOrEmpty(ID,'string')} = []
        Name {mustBeObjectOrEmpty(Name,'string')} = []
        Extension {mustBeObjectOrEmpty(Extension,'string')} = []
        Driver {mustBeObjectOrEmpty(Driver,'string')} = []
        Options (1,:) {mustBeObjectOrEmpty(Options,'string')} = []
    end
        
    methods
        
        function v = getID(obj), v = obj.ID; end
        function v = getName(obj), v = obj.Name; end
        function v = getExtension(obj), v = obj.Extension; end
        function v = getDriver(obj), v = obj.Driver; end
        function v = getSL(obj), v = obj.IsSL; end
        function v = getSF(obj),  v = obj.IsSF; end
        function v = getHG(obj), v = obj.IsHG; end
        
        function options = getOptions(obj,screenPixelsPerInch)
            % If the print options contains a -r resolution setting,
            %  this will replace it with screenPixelsPerInch
            import rptgen.internal.output.ImageFormat
            if isempty(obj.Options), options = []; return; end
            nOptions = numel(obj.Options);
            options = string.empty(0,nOptions);
            for i=1:nOptions
                if obj.Options(i) == ImageFormat.SCREEN_RESOLUTION
                    options(i) = "-r" + num2str(screenPixelsPerInch);
                else
                    options(i) = obj.Options(i);
                end
            end
        end
        
        function cmd = getPrintCmd(obj,varargin)
            % Returns the driver and options concatenated into a single string
            % If the print options contains a -r resolution setting, this will
            % replace it with screenPixelsPerInch
            import rptgen.internal.output.ImageFormat
            
            if nargin > 1
                screenPixelsPerInch = varargin{1};
            else
                screenPixelsPerInch = [];
            end
            
            cmd = obj.Driver;
            if ~isempty(obj.Options)
                nOptions = numel(obj.Options);
                for i=1:nOptions
                    if ~isempty(screenPixelsPerInch) && ...
                            obj.Options(i) == ImageFormat.SCREEN_RESOLUTION
                        cmd = cmd + " -r" + num2str(screenPixelsPerInch);
                    else
                        cmd = cmd + " " + obj.Options(i);
                    end
                end
            end
            
        end
        
    end
    
    
    methods (Access=private)
        function obj = ImageFormat(newID,newName,newExtension, ...
                newDriver, newOptions,newSL,newSF,newHG)
            % Creates a new instance of ImageFormat
            % %1=unique identifier
            % %2=name
            % %3=file extension
            % %4=device
            % %5=options
            % %6=is ok for simulink
            % %7=is ok for stateflow
            % %8=is ok for HG
            import rptgen.internal.output.ImageFormat
            obj.ID = newID;
            obj.Name = newName;
            obj.Extension = newExtension;
            obj.Driver = newDriver;
            obj.Options = newOptions;
            obj.IsSL = newSL;
            obj.IsSF = newSF;
            obj.IsHG = newHG;
        end
    end
    
    methods (Static,Access=private)
        
        function v = SCREEN_RESOLUTION(), v = "-r72"; end
        
        function registry = Registry()
            import rptgen.internal.output.ImageFormat
            persistent REGISTRY
            if isempty(REGISTRY)
                REGISTRY = containers.Map('KeyType', 'char', ...
                    'ValueType', 'any');
                ImageFormat.buildRegistry(REGISTRY);
            end
            registry = REGISTRY;
        end
        
        function registerFormats(registry,formats)
            nFormats = numel(formats);
            for i=1:nFormats
                format = formats(i);
                registry(char(format.ID)) = format;
            end
        end

        function msg = localize(msgID)
            msg = string(message("rptgen:ImageFormat:"+msgID));
        end
        
        function buildRegistry(registry)
            import rptgen.internal.output.ImageFormat
            
            formats = ImageFormat.empty(0,1);
            formats(1) = ImageFormat("eps",ImageFormat.localize("eps"),"eps","-deps",[],false,false,true);
            formats(end+1) = ImageFormat("epsc",ImageFormat.localize("epsc"),"eps","-depsc",[],false,false,true);
            formats(end+1) = ImageFormat("eps2",ImageFormat.localize("eps2"),"eps","-deps2",[],false,false,true);
            formats(end+1) = ImageFormat("epsc2",ImageFormat.localize("epsc2"),"eps","-depsc2",[],false,false,true);
            formats(end+1) = ImageFormat("epst",ImageFormat.localize("epst"),"eps","-deps","-tiff",false,false,true);
            formats(end+1) = ImageFormat("epsct",ImageFormat.localize("epsct"),"eps","-depsc","-tiff",false,false,true);
            formats(end+1) = ImageFormat("eps2t",ImageFormat.localize("eps2t"),"eps","-deps2","-tiff",false,false,true);
            formats(end+1) = ImageFormat("epsc2t",ImageFormat.localize("epsc2t"),"eps","-depsc2","-tiff",false,false,true);
            formats(end+1) = ImageFormat("ill",ImageFormat.localize("ill"),"ill","-dill",[],false,false,false);
            formats(end+1) = ImageFormat("jpeg90",ImageFormat.localize("jpeg90"),"jpg","-djpeg90",ImageFormat.SCREEN_RESOLUTION,true,true,true);
            formats(end+1) = ImageFormat("jpeg75",ImageFormat.localize("jpeg75"),"jpg","-djpeg75",ImageFormat.SCREEN_RESOLUTION,true,true,true);
            formats(end+1) = ImageFormat("jpeg30",ImageFormat.localize("jpeg30"),"jpg","-djpeg30",ImageFormat.SCREEN_RESOLUTION,true,true,true);
            formats(end+1) = ImageFormat("png",ImageFormat.localize("png"),"png","-dpng",ImageFormat.SCREEN_RESOLUTION,true,true,true);
            formats(end+1) = ImageFormat("tiffc",ImageFormat.localize("tiffc"),"tiff","-dtiff",ImageFormat.SCREEN_RESOLUTION,false,false,true); % no way to set compression for sl/sf
            formats(end+1) = ImageFormat("tiffu",ImageFormat.localize("tiffu"),"tiff","-dtiffnocompression",ImageFormat.SCREEN_RESOLUTION,false,false,true);
            formats(end+1) = ImageFormat("wmf",ImageFormat.localize("wmf"),"emf","-dmeta",[],ispc,ispc,ispc);
            formats(end+1) = ImageFormat("svg",ImageFormat.localize("svg"),"svg","-dsvg",[],true,true,false);
            formats(end+1) = ImageFormat("pdf",ImageFormat.localize("pdf"),"pdf","-dpdf",[],false,false,true);
            ImageFormat.registerFormats(registry, formats);
        end
    end
    
end

function tf = mustBeObjectOrEmpty(value,class)
if isempty(value)
    tf = true;
else
    if isa(value,class)
        tf = true;
    else
        tf = false;
    end
end
end

