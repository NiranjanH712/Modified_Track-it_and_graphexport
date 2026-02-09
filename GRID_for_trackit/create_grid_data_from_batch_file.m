function data = create_grid_data_from_batch_file(batch, subRegionIdx)
%% Function to create grid data from a batch file.

% Check if sub-region index is provided
if nargin == 1
    %No sub-region region was specified so we initialize the subRegionIdx
    %variable with an empty array.
    subRegionIdx = [];
end

% Create list of TL (TimeLapse) conditions
allframeCycleTimes = zeros(length(batch),1);
for idx = 1:length(batch)
    allframeCycleTimes(idx) = batch(idx).movieInfo.frameCycleTime;
end

[frameCycleTimesList,idEval,~] = unique(allframeCycleTimes);
nTL = numel(frameCycleTimesList); %Amount of tl conditions

%Create list of shortest track allowed in each tl condition 
shortestTrackList = zeros(nTL);
for idx = 1:nTL
   shortestTrackList(idx) = batch(idEval(idx)).params.minTrackLength-1;
end

%Create cell array where each cell contains all track lifes of a given timelapse condition
allTrackLifes = repmat({[]},nTL,1);

%Accumulate track lifetimes of each tl Condition
for idx = 1:length(batch)
    %Calculated track lifetimes
    
    if isempty(subRegionIdx)
        % If no sub-region index is specified, use track lengths directly
        trackLifes = batch(idx).results.trackLengths;
    else
         % If a sub-region index is specified, check if it's within bounds
        nSubRegionsInCurMovie = batch(idx).results.nSubRegions+1;
        if subRegionIdx > nSubRegionsInCurMovie
            % If the specified sub-region index is out of bounds, set trackLifes to 0
            trackLifes = 0;
        else
            % Otherwise, use track lengths of the specified sub-region
            trackLifes = batch(idx).results.subRegionResults(subRegionIdx).trackLengths;
        end
    end
    % Find the index of the current TL condition
    curTlIdx = find(frameCycleTimesList == batch(idx).movieInfo.frameCycleTime);
    
    % Add track lifetimes to the corresponding TL condition if not empty
    if trackLifes ~= 0
        allTrackLifes{curTlIdx} = [allTrackLifes{curTlIdx}; trackLifes-1];
    end
end

data = cell(nTL,2); %Initialize data cell
data = [data, num2cell(frameCycleTimesList/1000)]; %Write tl conditions into data cell

%Create cumulated histogram of track lifetimes for each tl condition
for idx = 1:nTL %Iterate through tl conditions
    
    %Get current TL condition
    frameCycleTime = data{idx,3};
    %Get largest track of this tl condition
    maxTrackLength = max(allTrackLifes{idx});
    
    %Get shortest possible track of this tl condition
    shortestTrackLength = shortestTrackList(idx);

    %Creat time vector and save in data
    data{idx,1} = transpose(shortestTrackLength*frameCycleTime:frameCycleTime:maxTrackLength*frameCycleTime);
    
    %Unique list of track lifetimes
    curTrackLengths = unique(allTrackLifes{idx});
    
    %Number of occurences of each lifetime
    amount = zeros(maxTrackLength,1);    
    for j=1:length(curTrackLengths) %Iterate through all occuring track lifetimes
        amount(curTrackLengths(j)) = sum(allTrackLifes{idx} == curTrackLengths(j));
    end
    
    %Delete first n rows to account for shortestTrack
    amount = amount(shortestTrackLength:end);
    
    % Create cumulative histogram
    data{idx,2} = flipud(cumsum(flipud(amount)));        
end

end