function [tracksBound, tracksFree] = vbSPT_TrackItPlugin(tracks, minTrackLength)

%This function converts TrackIt tracks into a vbSPT format and classifies
%tracks into free and bound segments using a Hidden Markov Model. 
%
%Note: vbSPT cannot handle gap frames and this script will split tracks
%with gap frames into separate tracks
%
%Input: 
%   tracks      -   Cell array that has as many entries as there are
%                   tracks. Each cell contains an array with 9 columns:
%                   [frame,xpos,ypos,A,BG,sigma_x,sigma_y,angle,exitflag]
%                   The first column contains the frame in which the spot
%                   appears, the other columns are equal to those in the
%                   spotsAll variable.
%   minTrackLength  Minimum amount of spots a track segment has to consist 
%                   of after classification




%Get number of tracks in current movie
nTracks = length(tracks);

%Initialize variable to save reformatted tracks for later use with TrackIt
formattedTracks = {};

%Initialize variable that goes into vbSPT
Traj = {};


%Iterate through tracks
for trackId=1:nTracks


    curTrack = tracks{trackId};
    framesOfCurTrack = curTrack(:,1);

    %Search for gap frames
    mobilityChangeIdx = find(diff(framesOfCurTrack)==2)';

    if isempty(mobilityChangeIdx)
        %Track has no gap frames so take it as it is
        formattedTracks{end+1} = curTrack;
        Traj{end+1} = curTrack(:,2:3);
    else
        %Track has gap frames, so divide it into separate tracks segments


        %Add beginning and end of track
        divisionIdx = [0 mobilityChangeIdx length(framesOfCurTrack)];

        %Iterate through all segments of the track that are divided by gap frames
        for j=2:length(divisionIdx)
            %Only save track segment if it is longer than the minimum track length

            if size(curTrack(divisionIdx(j-1)+1:divisionIdx(j),:),1) >= max(minTrackLength,2)

                formattedTracks{end+1} = curTrack(divisionIdx(j-1)+1:divisionIdx(j),:);
                Traj{end+1} = curTrack(divisionIdx(j-1)+1:divisionIdx(j),2:3);

            end
        end
    end


end

%-------------Classification with vbSPT----------------------------


save('Jdata.mat','Traj') %save the trajectories in a separate file, for the classification function to access it
R=VB3_HMManalysis('runinput.m'); %this is where the classification takes place


mobilityClass=R.Wbest.est2.viterbi; %save the classification results to the results struct of the movie

%---------Split tracks into bound and mobile classes-------------------


%Get total number of tracks in current movie
nTracks = length(formattedTracks);

tracksFree = {};
tracksBound = {};

%Loop over all tracks
for trackIdx = 1:nTracks

    %Get current track
    curTrack = formattedTracks{trackIdx};

    %Get mobility class of current track and convert it from uint8
    %to int8, because we need negative numbers to find change
    %points in the mobility
    curTrackMobClass = int8(mobilityClass{trackIdx});

    %Find changes in the mobility
    mobilityChangeIdx = find(abs(diff(curTrackMobClass))==1)';


    if isempty(mobilityChangeIdx)
        %No change in mobility -> whole track has same mobility
        if curTrackMobClass(1) == 1
            %Current track is completely bound
            tracksBound{end+1} = curTrack;
        else
            %Current track is completely free
            tracksFree{end+1} = curTrack;
        end

    else

        %Add beginning and end of track to get a vector that
        %defines, where the track has to be cut into segments
        divisionIdx = [0 mobilityChangeIdx size(curTrackMobClass,1)];


        %Iterate though all segments with different mobility
        for j=1:length(divisionIdx)-1
            %Get current segment
            curSlice = curTrack(divisionIdx(j)+1:divisionIdx(j+1)+1,:);

            %Check if current segment length is greater or equal to
            %the minimum track length
            if size(curSlice,1) >= minTrackLength
                %Check wich mobility class the segment is
                if curTrackMobClass(divisionIdx(j)+1) == 1
                    %Segment is bound
                    tracksBound{end+1} = curSlice;
                else
                    %Segment is free
                    tracksFree{end+1} = curSlice;
                end

            end
        end
    end

end

end



