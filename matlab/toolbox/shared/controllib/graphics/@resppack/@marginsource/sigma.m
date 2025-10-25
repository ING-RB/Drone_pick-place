function sigma(this,r,wspec)
% Computes disk margin based on largest singular value of S-(1-e)*I/2 and
% updates gain/phase margin data accordingly. No D scaling is involved. 
% This is used to show the "tuned lower bound" in TuningGoal.Margins.
% Note that the D scaling computed by SYSTUNE is already absorbed in 
% the system.

%   Copyright 1986-2020 The MathWorks, Inc.

% NOTE: Data units are Frequency:rad/s, Magnitude:abs, and Phase:rad
nsys = length(r.Data);
if nsys==0
   return
end
LData = getModelData(this);
Ts = abs(LData(1).Ts);
TU = this.Model.TimeUnit;
UCT = tunitconv(TU,'seconds');
UCF = funitconv('rad/TimeUnit','rad/s',TU);

% Skew
e = this.Skew;
[nL,~] = iosize(LData(1));
M = kron([(1+e)/2 1;-1 -1],eye(nL));

% Get new data
for ct=1:nsys
   % Look for visible+cleared responses in response array
   if isempty(r.Data(ct).Magnitude) && strcmp(r.View(ct).Visible,'on') && ...
         isfinite(LData(ct))
      % Form Se = S-(1-e)*I/2 
      Se = lft(createGain(LData(ct),M),LData(ct),nL+1:2*nL,nL+1:2*nL,1:nL,1:nL);
      % Check stability
      if isa(this.Model,'FRDModel')
         STABLE = true;
      else
         STABLE = this.Cache(ct).Stable;
         if isempty(STABLE)
            STABLE = isstable(Se);
         end
      end
      if STABLE
         % Compute singular values of Se
         [sv,w,FocusInfo] = sigmaresp(Se,0,wspec,true);
         % Enforce alpha*|1+e|<2 (e.g., for L=tf([1 1 1],[1 2 3]), e=0)
         alpha = 1./sv(1,:)';
      else
         % Not stable: GM=1 and PM=0 at all frequencies
         Focus = ltipack.getFreqFocus(wspec,Ts,'log'); % 1x2, may contain NaNs
         AutoFocus = any(isnan(Focus));
         if isempty(wspec) || iscell(wspec)
            % No frequency grid specified
            if AutoFocus
               w = logspace(-20,min(20,log10(pi/Ts)),10)';
            else
               w = logspace(log10(Focus(1)),log10(Focus(2)),10)';
            end
         else
            % User-defined grid
            w = wspec(:);  w = w(w>=0);
         end
         alpha = zeros(size(w));
         FocusInfo = struct('Focus',Focus,'DynRange',Focus,'Soft',AutoFocus);
      end
      % Compute gain and phase margin data to plot
      [GM,PM,alpha] = dm2gmPlot(alpha,e);
      % Store data
      d = r.Data(ct);
      d.Ts = UCT * Ts;
      d.Focus = UCF * FocusInfo.Focus;
      d.SoftFocus = FocusInfo.Soft;
      d.Frequency = UCF * w;
      d.DiskMargin = alpha;
      d.Magnitude = GM; % abs
      d.Phase = (pi/180)*PM; % rad
   end
end

