
function [params] = psfFit_Image(img, param_init, param_optimizeMask, useIntegratedGauss, useMLErefine, hWinSize, global_init)
    if nargin < 3 || isempty(param_optimizeMask)
        param_optimizeMask = logical([1,1,1,1,1,0,0]);
    end
    if nargin < 4 || isempty(useIntegratedGauss)
        useIntegratedGauss = false;
    end
    if nargin < 5 || isempty(useMLErefine)
        useMLErefine = false;
    end
    if nargin < 6 || isempty(hWinSize)
        hWinSize = 5;
    end
    if nargin < 7
        global_init = [];
    end

    img = double(img);
    [h, w] = size(img);
    numSpots = size(param_init, 2);
    params = zeros(8, numSpots);

    for i = 1:numSpots
        p0 = param_init(:, i);
        if ~isempty(global_init)
            p0(5:min(7, length(global_init)+4)) = global_init;
        end

        defaults = [0, 0, max(img(:)), median(img(:)), 1.5, 1.5, 0];
        for j = 1:length(defaults)
            if length(p0) < j || p0(j) <= 0
                p0(j) = defaults(j);
            end
        end

        x = round(p0(1)); y = round(p0(2));
        x1 = max(1, x - hWinSize); x2 = min(w, x + hWinSize);
        y1 = max(1, y - hWinSize); y2 = min(h, y + hWinSize);
        subImg = img(y1:y2, x1:x2);

        [X, Y] = meshgrid(x1:x2, y1:y2);
        X = X - p0(1); Y = Y - p0(2);

        fitfun = @(p, xy) gaussian2D(p, xy);
        xydata = [X(:), Y(:)];
        zdata = subImg(:);

        mask = param_optimizeMask;
        p_fit = p0(mask);
        model = @(p_fit) fitfun(apply_mask(p0, p_fit, mask), xydata);

        try
            p_fit_opt = lsqcurvefit(@(p) model(p), p_fit, [], zdata);
            p_opt = apply_mask(p0, p_fit_opt, mask);
            exitflag = 1;

            if useMLErefine
                mle_obj = @(p) sum(gaussian2D(p, xydata) - zdata .* log(gaussian2D(p, xydata) + eps));
                options = optimset('Display', 'off');
                p_mle = fminsearch(mle_obj, p_opt, options);
                p_opt = p_mle;
            end
        catch
            p_opt = p0;
            exitflag = -2;
        end

        params(:, i) = [p_opt(:); exitflag];
    end
end

function z = gaussian2D(p, xy)
    x = xy(:,1); y = xy(:,2);
    A = p(3); BG = p(4);
    sx = p(5); sy = p(6); theta = p(7)*pi/180;
    a = (cos(theta)^2)/(2*sx^2) + (sin(theta)^2)/(2*sy^2);
    b = -(sin(2*theta))/(4*sx^2) + (sin(2*theta))/(4*sy^2);
    c = (sin(theta)^2)/(2*sx^2) + (cos(theta)^2)/(2*sy^2);
    z = A * exp(-(a*x.^2 + 2*b*x.*y + c*y.^2)) + BG;
end

function p_full = apply_mask(p0, p_fit, mask)
    p_full = p0;
    p_full(mask) = p_fit;
end
