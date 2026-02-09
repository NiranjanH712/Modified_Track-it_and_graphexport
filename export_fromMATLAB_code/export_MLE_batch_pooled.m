function export_MLE_batch_pooled(allAnalysisResults, LongTracksvsAllevents, ShortTracksvsAllevents, LongtracksvsLongandShorttracks)
     % Define new output directory for pooled exports
    outDir = fullfile(pwd, "pooled_exports");
    if ~exist(outDir, 'dir')
        mkdir(outDir);
    end

    % Process each graph type
    processGraph_pooled(allAnalysisResults, LongTracksvsAllevents, 'longtracksvsallevents', outDir);
    processGraph_pooled(allAnalysisResults, ShortTracksvsAllevents, 'shorttracksvsallevents', outDir);
    processGraph_pooled(allAnalysisResults, LongtracksvsLongandShorttracks, 'longtracksvslong+shorttracks', outDir);
end

function processGraph_pooled(allStruct, graphStruct, graphType, outDir)
    % Initialize table
    batchTable = table();

    % Loop over batches
    for b = 1:numel(allStruct)
        % Batch name as scalar string
        batchName = string(allStruct(b).batchName);
        bnLower   = lower(batchName);

        % Parse Sex (check female first to avoid substring issue)
        if contains(bnLower,"female")
            sex = "Female";
        elseif contains(bnLower,"male")
            sex = "Male";
        else
            sex = "Unknown";
        end

        % Parse Condition
        if contains(bnLower," con ") || contains(bnLower,"con ")
            condition = "Con";
        elseif contains(bnLower,"rnai")
            condition = "RNAi";
        else
            condition = "Unknown";
        end

        % Metadata (force scalars where needed)
        % If these fields are vectors per movie, we take sums for n where appropriate
        nSpotsVec       = allStruct(b).nSpots;           % may be vector
        nSpotsTotal     = sum(nSpotsVec(:),'omitnan');   % n = sum of nSpots for the batch/group
        nTracks         = allStruct(b).nTracks(1);
        nShort          = allStruct(b).nShort(1);
        nLong           = allStruct(b).nLong(1);
        nAllEvents      = allStruct(b).nAllEvents(1);
        nNonLinkedSpots = allStruct(b).nNonLinkedSpots(1);

        % Biological replicate count (independent of vector length)
        if condition == "Con"
            N = 14;
        elseif condition == "RNAi"
            N = 12;
        else
            N = NaN;
        end

        % Mean, StdError, and MovieWiseValues from graphStruct
batchPooledVal = graphStruct(b).pooledValue(1);
batchPooledErr = graphStruct(b).pooledValueError(1);

% Convert SEM to SD
batchSD = batchPooledErr * sqrt(N);

% Replicate values as string
rawValues = graphStruct(b).movieWiseValues(:); 
movieValsStr = string("c(" + strjoin(string(rawValues), ",") + ")");

% Build row (14 variables, 14 names)
newRow = table(batchName, sex, condition, ...
    nSpotsTotal, nTracks, nShort, nLong, ...
    nAllEvents, nNonLinkedSpots, ...
    N, batchPooledVal, batchPooledErr, batchSD, movieValsStr, ...
    'VariableNames', {'BatchName','Sex','Condition', ...
    'nSpotsTotal','nTracks','nShort','nLong', ...
    'nAllEvents','nNonLinkedSpots', ...
    'N','PooledValue','PooledError','SD','MovieWiseValues'});


        batchTable = [batchTable; newRow];
    end

    % Export
    writetable(batchTable, fullfile(outDir, graphType + "_allinfo.csv"));
    writetable(batchTable, fullfile(outDir, graphType + "_allinfo.xlsx"), 'FileType','spreadsheet');

    fprintf('Exported %s with %d batch rows to %s\n', graphType, height(batchTable), outDir);
end
