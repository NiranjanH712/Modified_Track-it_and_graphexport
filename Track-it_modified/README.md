# Modified_Track-it_and_graphexport
This project is a modified version of Track-it a  Image analysis pipeline that is used to track molecule properties (i.e. movement,binding) along with graphing export options in R and preprocessing 

To anyone stumbling across this project, my name is Niranjan Harish and I am a student currently studying in my last semester at the University of Massachussetts Boston

I am uploading the modified version of my Track-it along with some graph export code from R and my pre-processing code for my particular project, so that people who faced the same issues as me in my project

The original code of Track-it belongs to @Gebhardtlab (Gebhardt lab Github page) and If you want to access their version, here is the link: https://gitlab.com/GebhardtLab/TrackIt.git

Along with some other changes, I applied 2 major changes to the code:
- Made the pipeline more accessible to other operating systems (initially only runnable through windows OS)

- If the graph made in Track-it is not in the format you need, you can use my MATLAB export code to export all the data in the struct variable file and make a graph in R that follows a more clear format)

  (for this change, the graph generated still has horizontal x axis lines which I am working on removing)

  (Also there are pipelines for 2 types of data, regular and pooled data (pooled data looks into the mean across each group), depending on the data type you want to use, you can use their respective functions for exporting and graphing in R)
    - I am working on a version that will allow you to choose between the types of data when you export the data in MATLAB and this will come out soon

Any updates made will be posted here 

Niranjan
(updated on 2/9/2026)
