function export_MLE_batch(allAnalysisResults, LongTracksvsAllevents, ShortTracksvsAllevents, LongtracksvsLongandShorttracks)
    % Use current working directory as output directory
    outDir = pwd;

    % Process each graph type
    processGraph(allAnalysisResults, LongTracksvsAllevents, 'longtracksvsallevents', outDir);
    processGraph(allAnalysisResults, ShortTracksvsAllevents, 'shorttracksvsallevents', outDir);
    processGraph(allAnalysisResults, LongtracksvsLongandShorttracks, 'longtracksvslong+shorttracks', outDir);
end

function processGraph(allStruct, graphStruct, graphType, outDir)
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
        batchMean   = graphStruct(b).mean(1);
        batchStdErr = graphStruct(b).stdError(1);
        rawValues   = graphStruct(b).movieWiseValues(:)'; % always 14 values
        movieValsStr = string("c(" + strjoin(string(rawValues), ",") + ")");

        % Build row (all scalars + collapsed string)
        newRow = table(batchName, sex, condition, ...
                       nSpotsTotal, nTracks, nShort, nLong, ...
                       nAllEvents, nNonLinkedSpots, ...
                       N, nSpotsTotal, batchMean, batchStdErr, movieValsStr, ...
                       'VariableNames', {'BatchName','Sex','Condition', ...
                                         'nSpots','nTracks','nShort','nLong', ...
                                         'nAllEvents','nNonLinkedSpots', ...
                                         'N','n','Mean','StdError','MovieWiseValues'});

        batchTable = [batchTable; newRow];
    end

    % Export
    writetable(batchTable, fullfile(outDir, graphType + "_allinfo.csv"));
    writetable(batchTable, fullfile(outDir, graphType + "_allinfo.xlsx"), 'FileType','spreadsheet');

    fprintf('Exported %s with %d batch rows to %s\n', graphType, height(batchTable), outDir);
end
