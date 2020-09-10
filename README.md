# UCSF-rcs-data-analysis
Selection of functions to extract .json raw data from Summit RCS device, transform it to .mat format and manipulate it for initial stages of data analysis.

Background: UCSF teams are working with Summit RC+S (RCS) devices for adaptive neurostimulation and require to have a validated data analysis framework to further the research. One of the members of the Starr Lab (Ro'ee Gilron, PhD) has developed and shared within openmind (om) his first working repository (om fork: https://github.com/openmind-consortium/rcsviz). To further continue the efforts on creation of a consolidated set of general functons for the RCS community, we have decided to start a new repo which will be based on previous working functions and new ones. By collaborating with a other colleagues we will make an effort to follow GIT quality control standards (https://github.com/openmind-consortium/UCSF-rcs-data-analysis).

Aim: to consolidate a set of matlab functions for accessing RCS data from .json files and transforming it into data formats that enables further data analyses.

Collaborators: Simon.Little@ucsf.edu, Prasad.Shirvalkar@ucsf.edu, Roee.Gilron@ucsf.edu, Kristin.Sellers@ucsf.edu, Juan.AnsoRomeo@ucsf.edu, (stays open for more colleagues to join...)

Policy: master will contain functions that have been tested in branch and pushed after pull request reviewers (at least 2 group members) have approved. A branch of master (code-dev-test) has been created with a set of preselected functions from https://github.com/roeegilron/rcsanalysis. These functions will be tested in a 1 by 1 basis using specific testing data-sets. Each data-set will be saved in a root repo folder called 'Data'. The collaborator doing the initial review and testing of a function in a testing branch (e.g. in 'code-dev-test') will make a pull request and assign 2 reviewers of the group who will oversea the code structure and the output of the function when running it in the assigned test data set.

Structure:
- code
  + functions: we will make a subfolder categories to group functions by generic grouping names, e.g. categories: 'loaders', 'gettersAndSetters', 'plotters', etc...
  + toolboxes: turtle_son, PAC-master, etc...
- testDataSets: will be selected from existing datasets or created explicitly for generic testing of function
- outputFigs: will contain the output of function testing to the specified test dataset

Functions: this list contains the functions that have been tested in brach and pushed to master (brief description of function input output next to each function name)
- function1: this function is doing X and requires an input argument/s Y1,Y2,Yn and outputs Z
- ...

In Dev Branch:
- deserializeJSON: Used to read data from RawDataTD.json into Matlab
    - fixMalformedJson
- unravelData: Used in the processing pipeline for converting data in RawDataTD.json to Matlab table format. Takes output from deserializeJSON and converts to Matlab table, without remove any packets  
