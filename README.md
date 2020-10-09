# Analysis-rcs-data
Selection of functions to extract .json raw data from Summit RCS device, transform it to .mat format and manipulate it for initial stages of data analysis. More detail below.

Background: UCSF teams are working with Summit RC+S (RCS) devices for adaptive neurostimulation and need a validated data analysis framework to further the research. 

Aim: To consolidate a set of matlab functions for accessing RCS data from .json files and transforming it into data formats that enables further data analyses.

Collaborators: Simon.Little@ucsf.edu, Prasad.Shirvalkar@ucsf.edu, Roee.Gilron@ucsf.edu, Kristin.Sellers@ucsf.edu, Juan.AnsoRomeo@ucsf.edu, Kenneth.Louie@ucsf.edu (stays open for more colleagues to join...)

Policy: Master will contain functions that have been tested in branch and pushed after pull request reviewers have approved. The collaborator doing the initial development and testing of a function in a testing branch (e.g. in 'importRawData') will make a pull request and assign 1-2 reviewers of the group who will review the code structure and the output of each function.

Structure:
- code
  + functions: code for specific needs; [TBD if these are further organized in subfolders]
  + toolboxes: turtle_son, etc...
- testDataSets: benchtop generated test data sets for validation of code; often generated signals are simultaneously recorded with DAQ to allow for verification of timing across data streams. 
- outputFigs: will contain the output of function testing to the specified test dataset

Functions: this list contains the functions that have been tested in brach and pushed to master (brief description of function input output next to each function name)

Wrappers
- DEMO_ProcessRCS: Demo wrapper script for importing raw .JSON files from RC+S, parsing into Matlab table format, and handling missing packets / harmonizing timestamps across data streams

CreateTables
- createDeviceSettingsTable: Extract information from DeviceSettings related to configuration for time domain, power, and FFT channels
- createTimeDomainTable: Create Matlab table of raw data from RawDataTD.json
- createAccelTable: Create Matlab table of raw data from RawDataAccel.json
- createPowerTable: Create Matlab table of raw data from RawDataPower.json
- createFFTtable: Create Matlab table of raw data from RawDataFFT.json

Utility
- deserializeJSON: Reads .json files and loads into Matlab
- fixMalfomedJSON: Checks for and replaces missing brackets and braces in json file, which can prevent proper loading
- convertTDcodes: Conversion of Medtronic numeric codes into values (e.g. Hz)
- getSampleRate: Convert Medtronic codes to sample rates in Hz for time domain data
- getSampleRateAcc: Convert Medtronic codes to sample rates in Hz for accelerometer data
- getPowerBands: Calculate lower and upper bounds, in Hz, for each power domain timeseries
- getFFTparameters: Determine FFT parameters from FFTconfig and TD sample rate

(Pre)Processing
- assignTime: Function for creating timestamps for each sample of valid RC+S data. 

_______________________________________________________________________________________________________


[Diagram showing general data flow]



__________________________________________________________________________________________________________

assignTime.m: Function for creating timestamps for each sample of valid RC+S data. 

Given known limitations of all recorded timestamps, need to use multiple variables to derive time.

General approach: Remove packets with faulty meta-data. Identify gaps in data (by checking deltas in timestamp, systemTick, and dataTypeSequence). Consecutive packets of data without gaps are referred to as 'chunks'. For each chunk, determine best estimate of the first packet time, and then calculate time for each  sample based on sampling rate -- assume no missing samples. Best estimate of start time for each chunk is determined by taking median (across all packets in that chunk) of the offset between delta PacketGenTime and expected time to have elapsed (as a function of sampling rate and number of samples per packet).






