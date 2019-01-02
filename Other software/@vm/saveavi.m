% Write a compressed movie file
%
% vm: Vectorized movie class
%
% 2016-2017 Vicente Parot
% Cohen Lab - Harvard University
%
        function saveavi(obj,fname)
            % save compressed avi movie
            if nargin > 1
                pname = '';
            else
                [fname, pname] = uiputfile('*.avi');
            end
            fullname = fullfile(pname,fname);
            tic
            fprintf('saving %s ...\n',fullname)
            v = VideoWriter(fullname);
            v.FrameRate = 25;
            v.Quality = 95;
            v.open
            dat = single(permute(obj.toimg.data,[1 2 4 3]));
            obj = obj.setSaturationLimits;
            dat = dat - single(obj.SortedFew(ceil(obj.DisplaySaturationFraction*end)));
            dat = dat./single(diff(obj.SortedFew(ceil([obj.DisplaySaturationFraction 1-obj.DisplaySaturationFraction]*end))'));
            dat = min(1,max(0,dat));
            writeVideo(v,uint8(dat*256))
            v.close
            disp(['saving took ' num2str(toc) ' s']);
        end
