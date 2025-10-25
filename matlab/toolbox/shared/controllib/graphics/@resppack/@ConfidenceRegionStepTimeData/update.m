function update(this,r)
%UPDATE  Data update method @ConfidenceRegionStepTimeData class

%   Author(s): Craig Buhr
%   Copyright 1986-2022 The MathWorks, Inc.


% Struct Data(ny,nu,2).Amplitude  
%                      .Time 

if ~isempty(this.Data), return; end

% add protection for empty source etc
idxModel = find(r.Data==this.Parent);
m = r.DataSrc.getModelData(idxModel);
[ny, nu] = iosize(m); 
if nu==0, nu = ny; end % for nonlinear time series models
Config = r.Context.Config;

try
    % Determine if the last time point is an extension or a computed
    % timestep
    tvec = this.Parent.Time;
    if (length(tvec)>2)
        TEndDiff = tvec(end)-tvec(end-1);
        TBeginDiff = tvec(2)-tvec(1);
        if abs(TEndDiff-TBeginDiff) > 0.01*TBeginDiff
            tvec = tvec(1:end-1);
        end
    end
catch ME
     tvec = this.Parent.Time(1:end-1);
end

[y,t,~,~,ysd] = timeresp(m,'step',tvec,Config);
if ~isempty(ysd)
    for yct = 1:ny
        for uct = 1:nu
            % Remove trailing NaNs
            idx = find(isfinite(ysd(:,yct,uct)),1,'last');
            this.Data(yct,uct).Amplitude = y(1:idx,yct,uct);
            this.Data(yct,uct).AmplitudeSD =  this.NumSD*ysd(1:idx,yct,uct);
            this.Data(yct,uct).Time = t(1:idx);
        end
    end
end
this.Ts = r.DataSrc.Model(:,:,idxModel).Ts;
this.TimeUnit = r.DataSrc.Model(:,:,idxModel).TimeUnit;      


% % Compute uncertain responses
% if isempty(r.DataSrc)% || ~isUncertain(r.DataSrc)
%    % If there is no source do not give a valid yf gain result.
%    % Set Data to NaNs
%    this.Ts = r.DataSrc.Ts;
%    %yf = NaN(nrows,ncols);
% else
%    % If the response contains a source object compute the uncertain
%    % Responses
%    %t = this.Parent.Time(1:end-1);
%    %getUncertainTimeRespData(r.DataSrc,'step',r,this,t);
%    getUncertainTimeRespData(r.DataSrc,'step',r,this,[]);
%    
% end  


