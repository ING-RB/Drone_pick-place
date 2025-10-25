function setChartData(this, varargin)
    %#codegen
    for counterVar1 = 1 :2: length(varargin)
        switch varargin{counterVar1}
            %@TODO: move configuration names to single place
            case {'-executeInitStep','-eventQueueSize','-enableAnimation','-warningOnUninitializedData','-animationDelay'}
                continue;
            otherwise
                this.set(varargin{counterVar1},  varargin{counterVar1+1});
        end
    end
end