function colors = distinguishable_colors_hybrid(nColors, excludeColors)
    % Generate visually distinct colors using Lab if ICC available,
    % otherwise fallback to RGB-based method.

    if nargin < 2
        excludeColors = {'k'}; % Default: exclude black
    end

    % Try ICC-based Lab conversion
    iccPath = '/System/Library/ColorSync/Profiles/sRGB Profile.icc'; % macOS default ICC profile
    useLab = false;
    if exist(iccPath, 'file')
        try
            sRGB_profile = iccread(iccPath);
            cform = makecform('srgb2lab', 'ICCProfile', sRGB_profile);
            useLab = true;
        catch
            warning('ICC profile found but could not be loaded. Falling back to RGB.');
        end
    else
        warning('ICC profile not found. Falling back to RGB.');
    end

    % Candidate colors: sample RGB space
    nCandidates = 1000;
    candidates = rand(nCandidates, 3); % Random RGB values

    % Convert excluded colors to RGB
    excludeRGB = cellfun(@(c) rgb(c), excludeColors, 'UniformOutput', false);
    excludeRGB = vertcat(excludeRGB{:});

    % Initialize output
    colors = zeros(nColors, 3);

    for i = 1:nColors
        if useLab
            % Convert candidates and exclusions to Lab
            candidatesLab = applycform(candidates, cform);
            excludeLab = applycform(excludeRGB, cform);
            if i == 1
                dists = min(pdist2(candidatesLab, excludeLab), [], 2);
            else
                chosenLab = applycform(colors(1:i-1,:), cform);
                dists = min(pdist2(candidatesLab, [excludeLab; chosenLab]), [], 2);
            end
        else
            % Fallback: RGB distance
            if i == 1
                dists = min(pdist2(candidates, excludeRGB), [], 2);
            else
                dists = min(pdist2(candidates, [excludeRGB; colors(1:i-1,:)]), [], 2);
            end
        end
        [~, idx] = max(dists);
        colors(i,:) = candidates(idx,:);
    end
end

function rgbVal = rgb(colorName)
    % Convert color name to RGB
    rgbVal = reshape(getfield(struct('k',[0 0 0],'w',[1 1 1],'r',[1 0 0],'g',[0 1 0],'b',[0 0 1],'c',[0 1 1],'m',[1 0 1],'y',[1 1 0]), colorName),1,3);
end