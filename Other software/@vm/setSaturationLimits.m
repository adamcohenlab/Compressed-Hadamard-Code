% Sets the colormap limits for display
%
% vm: Vectorized movie class
%
% 2016-2017 Vicente Parot
% Cohen Lab - Harvard University
%
        function obj = setSaturationLimits(obj,lim)
            if exist('lim','var')
                obj.SaturationLimits = lim;
            else
                targetelms = 1e7;
                rszf = max(1/8,min(1,sqrt(targetelms/numel(obj.data))));
                obj.SortedFew = sort(reshape(imresize(obj.data,rszf),[],1));
                obj.SaturationLimits = obj.SortedFew;
                obj.SaturationLimits = obj.SaturationLimits(~isnan(obj.SaturationLimits));
                obj.SaturationLimits = obj.SaturationLimits(~isinf(obj.SaturationLimits));
                obj.SaturationLimits = obj.SaturationLimits(max(1,ceil([obj.DisplaySaturationFraction 1-obj.DisplaySaturationFraction]*end)))';
                if numel(obj.SaturationLimits) < 2
                    obj.SaturationLimits = [0 1];
                end            
                if ~diff(obj.SaturationLimits)
                    obj.SaturationLimits = obj.SaturationLimits + [0 eps];
                end
            end
        end
