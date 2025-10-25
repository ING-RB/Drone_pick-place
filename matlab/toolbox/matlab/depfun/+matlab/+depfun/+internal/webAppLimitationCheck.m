function webAppLimitationCheck(parts,expected)
import matlab.depfun.internal.requirementsConstants

% Show warnings without stack trace.
orgBacktraceState = warning('backtrace','off');
restoreWarningState = onCleanup(@()warning(orgBacktraceState));
        
% check if program contains multiple mlapps by looking at all the
% parts returned. mlapp files have type 'MCOSClass'
idx = strcmp({parts.type},'MCOSClass');
clsfile = parts(idx);
if numel(clsfile)>1
    appFiles={};
    for k = 1:numel(clsfile)
        % warn about multiple mlapp files, including the main mlapp
        [~,~,ext]=fileparts(clsfile(k).path);
        % check the extension to make sure it is mlapp file
        % .m files can be MCOSClass too
        if strcmp(ext,'.mlapp')
           appFiles{end+1} = clsfile(k).path; %#ok
        end
    end
    if numel(appFiles)>1
       warning(message('MATLAB:depfun:req:WebAppMultiAppLimitation',strjoin(appFiles,newline)));
    end
end
% check if the expected list contains unsupported multiwindow functions
unSupportedList = fullfile(requirementsConstants.MatlabRoot,requirementsConstants.WebAppMultiwindowUnsupportedList);
detectedList = intersect(unSupportedList,expected);
functionNames={};
for k = 1:numel(detectedList)
    [~,name,~]=fileparts(detectedList{k});
    functionNames{end+1}=name;%#ok
end
if ~isempty(functionNames)
    warning(message('MATLAB:depfun:req:WebAppMultiwindowLimitation',strjoin(functionNames,',')));
end

% check if the expected list contains unsupported printing functions
% warning is shown for each single function since there are only two functions
% in this category
unSupportedList = fullfile(requirementsConstants.MatlabRoot,requirementsConstants.WebAppPrintingUnsupportedList);
detectedList = intersect(unSupportedList,expected);
for k = 1:numel(detectedList)
    [~,name,~]=fileparts(detectedList{k});
    warning(message('MATLAB:depfun:req:WebAppPrintingLimitation',name));
end

end


 