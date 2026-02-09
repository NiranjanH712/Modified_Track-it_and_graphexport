function [datanew]=dataresampler(data,percentage,N)
    %Create real events from cumulated histograms
    data=diffsum(data);
    %Preallocate Memory
    datanew=data;
    
    %Resampling
    for q=1:numel(data)/3
        original=data{q,2};
        resampled=original*0;
        %Amount of samples
        Q=floor(max(sum(original)*percentage,N));
        for idx=1:Q
            %Create probability distribution of robserving an event
            ptemp=original/sum(original);
            %Choose the event from the distribution
            [ choice ]=choose(ptemp);
            %No replacement
            original(choice)=original(choice)-1;
            %Add event to new probability distribution
            resampled(choice)=resampled(choice)+1;
        end
        datanew{q,2}=resampled;     
    end
    %Bring data back to original file format
    datanew=cumuldata(datanew);
       
end

function [datad]=diffsum(data)
    %Reverse cumsum operation 
    datad=data;
    for q=1:numel(data)/3
       ncum=data{q,2};
       ndiff=ones(numel(ncum),1);
       for w=1:numel(ncum)-1
          ndiff(w)=ncum(w)-ncum(w+1); 
       end
       ndiff(end)=ncum(end);
       datad{q,2}=ndiff;
    end
    
    
end

function [data]=cumuldata(data)
    %Cumsum operation
    for q=1:numel(data)/3  
         data{q,2}=flipud(cumsum(flipud(data{q,2})));
         
         data{q,1}(data{q,2}==0)=[];
         data{q,2}(data{q,2}==0)=[];         
    end    
    flag=1;
    
    while flag==1
        flag=0;
        for q=1:numel(data)/3
            if numel(data{q,1})<3
                 disp('timelapse excluded')
                 data(q,:)=[];
                 flag=1;
                 break
            end
        end
    end

end

%Choose a random element from a probability distribution
function [ choice ]=choose(vector)

    %random number
    z=rand(1);
    
    %decision
    for n=1:numel(vector)
        if z<=vector(n)
            choice=n;
            break
        else
            vector(n+1)=vector(n+1)+vector(n);
        end
    end
    
end