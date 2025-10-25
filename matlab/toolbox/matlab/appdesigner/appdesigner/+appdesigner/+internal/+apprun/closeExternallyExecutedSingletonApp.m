function closeExternallyExecutedSingletonApp(fullFileName)
	%CLOSEEXTERNALLYEXECUTEDSINGLETOPAPP If an app was executed externally then
	%executed again from design environment, search for and close any singleton apps
	%with the same full file name

	% Copyright 2021, MAthWorks Inc.
	
	runningAppFigures = appdesigner.internal.service.AppManagementService.getRunningAppFigures();

	if ~isempty(runningAppFigures)
		for ix = 1:numel(runningAppFigures)
			runningAppInstance = runningAppFigures(ix).RunningAppInstance;

			runningAppFullFileName = runningAppFigures(ix).RunningInstanceFullFileName;

			if ((ispc && strcmpi(runningAppFullFileName, fullFileName)) || ...
				(~ispc && strcmp(runningAppFullFileName, fullFileName)))
				try 
					% The deletion of the previously running app could
					% throw an exception if the running app's code was
					% updated and fails when parsed.
					runningAppInstance.delete();
				catch
					% Allow the exception to pass through because it will
					% also fail when we attempt to eval the app in the
					% code.
					% Reporting the eval failure is more relevant
					% and useful than reporting the delete failure.
				end
			end
		end
	end
end

