% Display movie with scaled intensity
%
% vm: Vectorized movie class
%
% 2016-2017 Vicente Parot
% Cohen Lab - Harvard University
%
        function moviesc(obj,fr,scalingmode)
            % display movie with auto scale
            % optionally input the initially displayed frame, defaults to 1
            if ~exist('fr','var')
                fr = 1;
            end
            if ~exist('scalingmode','var')
                scalingmode = 'frame';
            end
            
            obj = obj.toimg;
            fi = gcf;
            clf reset;
            ax = gca;
            sliderHeight = 20;
            uf = uicontrol(fi,'style','slider');
            uf.Value = (fr-.5)/obj.frames;
            addlistener(uf,'Value','PostSet',@(hObj,event)moviescUpdateFrame(hObj,event,ax));
            fi.SizeChangedFcn = @moviescFigResize;
            fi.WindowScrollWheelFcn = @moviescScrollWheel;

            ax.Units = 'pixels';
            ax.Position(2) = ax.Position(2) + sliderHeight;
            ax.Position(4) = ax.Position(4) - sliderHeight;
            ax.Units = 'normalized';
            uf.Units = 'normalized';
            uf.Position([1 3]) = ax.Position([1 3]);
            uf.Units = 'pixels';
            uf.Position([2 4]) = [1 sliderHeight];
            uf.Units = 'normalized';
            
            if isreal(obj.data)
                im = obj.frame(fr);
                if ~isempty(obj.SaturationLimits)
                    lims = double(obj.SaturationLimits);
                else
                    lims = double([min(im(:)) max(im(:))]);
                    lims = lims + [0 eps(mean(lims))];
                end
                if ~isempty(obj.xscale)
                    imagesc(obj.xscale,obj.yscale,im,lims)
                else
                    imagesc(im,lims)
                end
            else
                ofr = obj.frame(fr);
                im = zeros([size(ofr) 3]);
                im(:,:,1) = real(ofr);
                im(:,:,2) = real(ofr)/2+imag(ofr)/2;
                im(:,:,3) = imag(ofr);
                im = im/std(im(:))/8+.5;
                if ~isempty(obj.xscale)
                    imagesc(obj.xscale,obj.yscale,im)
                else
                    imagesc(im)
                end
            end

            ut = uicontrol('style','text','FontSize',10,'HorizontalAlignment','left');
            ut.Units = 'pixels';
            uf.Units = 'pixels';
            ut.Position(1) = uf.Position(1);
            ut.Position(3) = ut.Position(3) + 20;
            ut.Position(2) = sum(uf.Position([2 4]));
            uf.Units = 'normalized';

            setappdata(fi,'scalingmode',scalingmode)
            setappdata(fi,'ut',ut)
            setappdata(fi,'uf',uf)
            setappdata(fi,'ax',ax)
            setappdata(fi,'sliderHeight',sliderHeight)
            setappdata(fi,'myMov',obj)
            setappdata(fi,'fr',fr)

            moviescRedraw(fi)
            if isreal(obj.data)
                colormap(gray(2^11))
                colorbar
            end
            axis equal tight
        end

function moviescRedraw(src)
% update figure image data when advancing frames
% 2016 Vicente Parot
% Cohen Lab - Harvard University
    sm = getappdata(src,'scalingmode');
    ut = getappdata(src,'ut');
    ax = getappdata(src,'ax');
    myMov = getappdata(src,'myMov');
    fr = getappdata(src,'fr');
    imh = findall(ax.Children,'Type','Image');
    if isreal(myMov.data)
        imh(1).CData = myMov.frame(fr);
    else
        ofr = myMov.frame(fr);
        im = zeros([size(ofr) 3]);
        % green-magenta contrast
        im(:,:,1) = real(ofr);
        im(:,:,2) = real(ofr)/2+imag(ofr)/2;
        im(:,:,3) = imag(ofr);
        im = im/std(im(:))/8+.5;
        imh(1).CData = im;
    end
    switch sm
        case 'frame'
            % change scaling for every frame
            scd = sort(imh(1).CData(:));
            scd = scd(~isnan(scd));
            scd = scd(~isinf(scd));
            scd = double(scd);
            scd = scd(max(1,ceil([myMov.DisplaySaturationFraction 1-myMov.DisplaySaturationFraction]*end)));
            if ~diff(scd)
                scd = scd + [0 eps(scd(2))]';
            end
            ax.CLim = scd;
        case 'fixed'
            % scaling was initially set already
    end
    ut.String = sprintf('frame %d',fr);
end

function moviescUpdateFrame(~,event,ax)
% advance frames when slider moves
% 2016 Vicente Parot
% Cohen Lab - Harvard University
    myMov = getappdata(ax.Parent,'myMov');
    fr = max(1,min(ceil(event.AffectedObject.Value*(myMov.frames-1)+1),myMov.frames));
    setappdata(ax.Parent,'fr',fr)
    moviescRedraw(ax.Parent)
end

function moviescScrollWheel(src,callbackdata)
% advance frames when wheel-scrolling
% 2016 Vicente Parot
% Cohen Lab - Harvard University
    fr = getappdata(src,'fr');
    uf = getappdata(src,'uf');
    myMov = getappdata(src,'myMov');
    switch callbackdata.VerticalScrollCount
        case -1
            fr = max(1,fr-1);
        case 1
            fr = min(myMov.frames,fr+1);
    end
    uf.Value = (fr-1)/(myMov.frames-1);
    setappdata(src,'fr',fr)
    moviescRedraw(src)
end

function moviescFigResize(src,~)
% reorganize movie figure when resizing
% 2016 Vicente Parot
% Cohen Lab - Harvard University
    uf = getappdata(src,'uf');
    ut = getappdata(src,'ut');
    sliderHeight = getappdata(src,'sliderHeight');
    uf.Units = 'pixels';
    uf.Position(4) = sliderHeight;
    uf.Units = 'normalized';
    ut.Units = 'pixels';
    uf.Units = 'pixels';
    ut.Position(1) = uf.Position(1);
    ut.Position(2) = sum(uf.Position([2 4]));
    uf.Units = 'normalized';
end
