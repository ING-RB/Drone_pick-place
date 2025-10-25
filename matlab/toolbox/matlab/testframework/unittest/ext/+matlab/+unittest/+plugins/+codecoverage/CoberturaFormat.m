classdef CoberturaFormat < matlab.unittest.plugins.codecoverage.CoverageFormat
    % CoberturaFormat - A format to create a code coverage report using Cobertura XML format.
    %
    %   To produce code coverage results that conform with the Cobertura
    %   XML format, use an instance of the CoberturaFormat class with the
    %   CodeCoveragePlugin.
    %
    %   CoberturaFormat methods:
    %       CoberturaFormat - Class constructor
    %                                                                      
    %   Example:
    %                                                                      
    %       import matlab.unittest.plugins.CodeCoveragePlugin;
    %       import matlab.unittest.plugins.codecoverage.CoberturaFormat;
    %                                                                      
    %       % Construct the Cobertura XML coverage format 
    %       format = CoberturaFormat('CoverageResults.xml');
    %       
    %       % Construct a CodeCoveragePlugin with the Cobertura XML format
    %       plugin = CodeCoveragePlugin.forFolder('C:\projects\myproj',...
    %           'Producing',format);
    %                                                                      
    %   See also: matlab.unittest.plugins.CodeCoveragePlugin
    
    % Copyright 2017-2023 The MathWorks, Inc. 
    
    properties (Hidden,SetAccess = private)
        Filename
    end
    
    methods
        function format = CoberturaFormat(filename)
            % CoberturaFormat - Construct a CoberturaFormat format.
            %
            % FORMAT = CoberturaFormat(FILENAME) constructs a CoberturaFormat format
            % and returns it as FORMAT. When used with the CodeCoveragePlugin,
            % the code coverage results are saved to the file FILENAME.
            import matlab.unittest.internal.newFileResolver;
            validFileExtension = '.xml';
            format.Filename = newFileResolver(filename, validFileExtension);            
        end
    end
    
    methods (Hidden, Access = {?matlab.unittest.internal.mixin.CoverageFormatMixin,...
            ?matlab.unittest.plugins.codecoverage.CoverageFormat})
        function generateCoverageReport(coberturaFormat,sources,coverageResults,~,~)
           import matlab.unittest.internal.services.coverage.MATLABCoberturaPublishingService
           import matlab.automation.internal.services.ServiceLocator
           import matlab.unittest.internal.services.ServiceFactory

           namespace = "matlab.unittest.internal.services.coverage.located";
           locator = ServiceLocator.forNamespace(meta.package.fromName(namespace));
           serviceClass = ?matlab.unittest.internal.services.coverage.CoberturaPublishingService;
           
           locatedServiceClasses = locator.locate(serviceClass);
           locatedServices = ServiceFactory.create(locatedServiceClasses);
           coveragePublishingServices = [MATLABCoberturaPublishingService(); ...
               locatedServices];

           fulfill(coveragePublishingServices,coberturaFormat.Filename,sources,coverageResults);
           
        end
    end
    methods (Hidden)
        function validateReportCanBeCreated(coberturaFormat)
            import matlab.unittest.internal.validateFileCanBeCreated
            validateFileCanBeCreated(coberturaFormat.Filename);
        end
    end  
end

% LocalWords:  Cobertura myproj cobertura
