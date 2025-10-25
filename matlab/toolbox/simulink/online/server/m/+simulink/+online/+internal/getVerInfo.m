function getVerInfo()

	jobInfoFile=['/opt/mlsedu/matlab/R' version('-release') '/info.txt'];
	jobInfo='Job info not present';
	if exist(jobInfoFile,'file')
		jobInfo = fileread(jobInfoFile);
	end

	disp(['synced from job : ' jobInfo]);
	disp(['version output : ' version]);

end
