classdef FigureImageCaptureService < handle & matlab.ui.internal.componentframework.services.optional.ControllerInterface
    %FIGUREIMAGECAPTURESERVICE A service for capturing images (i.e.
    %screenshots) of figures.
    %   FigureImageCaptureService currently only supports figures created
    %   using uifigure and in the MATLAB Desktop environment.

%   Copyright 2019-2023 The MathWorks, Inc.
        
    methods(Static)

        function image = captureImage(fig)
        %CAPTUREIMAGE Captures an image of the given UI Figure.
        % CAPTUREIMAGE(FIG) returns an image of the uifigure
        % for handle FIG as pixel data. Only figures created with uifigure
        % in MATLAB Desktop are currently supported.
            import matlab.internal.capability.Capability;

            % Error out in JSD as this functionality will no longer be
            % supported in JSD
            if feature('webui')
                throwAsCaller(MException('MATLAB:ui:figure:ExportUnsuccessful', ...
                    'matlab.ui.internal.FigureImageCaptureService.captureImage not supported in new desktop'));
            end
                        
            % Error out for MATLAB Online or deployed web apps.
            if matlab.internal.environment.context.isWebAppServer || ...
            ~Capability.isSupported(Capability.LocalClient)
                error(message('MATLAB:ui:uifigure:OnlyMATLABDesktopSupported'));
            end
            
            % Wait for the figure to draw.
            drawnow;
            
            matlab.ui.internal.FigureImageCaptureService.verifyFigIsValidUifigure(fig);

            % Error out for invisible figure
            if (strcmpi(fig.Visible, 'off'))
                error(message('MATLAB:ui:uifigure:FigureNotVisible'));
            end
                        
            % Get the figure controller.
            figController = fig.getControllerHandle();
                        
            % Since this is definitely a desktop uifigure, we should only
            % get a CEFPlatformHost here.
            cefWindow = figController.PlatformHost.CEF;
            
            % Capture the screenshot.
            image = cefWindow.getScreenshot();
        end
           
        function exportToPDF(fig, fullFileName, includeFigureTools)
            % EXPORTTOPDF - Given uifigure FIG, exports a PDF image of FIG to
            % a file indicated by FULLFILENAME. It must include the full
            % path to the file.
            % INCLUDEFIGURETOOLS is an optional argument for including 
            % figure tools in the output (such as toolbars and menubars).
            
            matlab.ui.internal.FigureImageCaptureService.verifyFigWindowCanBeDisplayed('exportToPDF');
            
            % Ensure figure is loaded
            drawnow;
                        
            % Do not include Figure tools by default if not specified
            if nargin < 3 
                includeFigureTools = false;
            end
            
            matlab.ui.internal.FigureImageCaptureService.verifyFigIsValidUifigure(fig);
            figController = fig.getControllerHandle();
            figController.exportToPDF(fullFileName, includeFigureTools);
        end
        
        function base64string = exportToPngBase64(fig, includeFigureTools)
            % EXPORTTOPNGBASE64 - Given uifigure FIG, returns a png base64
            % encoded string. 
            % INCLUDEFIGURETOOLS is an optional argument for including 
            % figure tools in the output (such as toolbars and menubars).
            
            matlab.ui.internal.FigureImageCaptureService.verifyFigWindowCanBeDisplayed('exportToPngBase64');
            
            if nargin < 2
                includeFigureTools = false;
            end
            
            % Ensure figure is loaded
            drawnow;
            
            matlab.ui.internal.FigureImageCaptureService.verifyFigIsValidUifigure(fig);
            figController = fig.getControllerHandle();
            base64string = figController.exportToPngBase64(includeFigureTools);
        end
        
        function verifyFigWindowCanBeDisplayed(functionName)
            if feature('NoFigureWindows')
                error(message('MATLAB:hg:NoDisplayNoFigureSupport', functionName));
            end
        end
        
        function verifyFigIsValidUifigure(fig)
            % Error out for destroyed figure.
            if ~isvalid(fig)
                error(message('MATLAB:ui:components:invalidObject', 'fig'));
            end
            
            % Error out for Java figure
            if ~matlab.ui.internal.isUIFigure(fig)
                error(message('MATLAB:ui:uifigure:UnsupportedFigureFunctionality', 'figure'));
            end
        end
    end
end
