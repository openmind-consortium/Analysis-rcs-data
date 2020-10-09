# Analysis-rcs-data
Selection of Matlab functions to extract .json raw data from Summit RC+S device, transform it to .mat format and manipulate it for initial stages of data analysis. More detail of processing flow below. 

**Background**: UCSF teams are working with Summit RC+S (RCS) devices for adaptive neurostimulation and need a validated data analysis framework to further the research. 

**Aim**: To consolidate a set of matlab functions for accessing RCS data from .json files and transforming it into data formats that enables further data analyses.

**Collaborators**: Simon.Little@ucsf.edu, Prasad.Shirvalkar@ucsf.edu, Roee.Gilron@ucsf.edu, Kristin.Sellers@ucsf.edu, Juan.AnsoRomeo@ucsf.edu, Kenneth.Louie@ucsf.edu (stays open for more colleagues to join...)

**Policy**: Master will contain functions that have been tested in branch and pushed after pull request reviewers have approved. The collaborator doing the initial development and testing of a function in a testing branch (e.g. in 'importRawData') will make a pull request and assign 1-2 reviewers of the group who will review the code structure and the output of each function.

## Installation Instructions:
- Compatibility - Mac or PC. We rely on a toolbox to open .json files which does not work on Linux. Requires **Matlab R2019a or prior**. The toolbox we rely on to open .json files is not compatible with Matlab R2019b
- Clone this repository and add to Matlab path. 

## What is the RC+S native data format?
The Medtronic API saves data into a session directory. There are 11 .json files which are created for each session, which contain both meta-data and numerical data. These files can contain data from streaming up to 30 hours if streaming time domain data or even longer if streaming power domain data; the limit to this duration is dictated by the max INS battery life. 

There are multiple challenges associated with these .json file and analyzing them: Interpreting metadata within and across the files, handling invalid / missing / misordered packets, creating a timestamp value for each sample, aligning timestamps (and samples) across data streams, and parsing the data streams when there was a change in recording or stimulation parameters. See below for the current approach for how to tackle these challenges.

## Data parsing overview

To facilitate most standard analyses of time-series data, we would optimally like the data formatted in a matrix with samples in rows, data features in columns, and a timestamp assigned to each row. The difference in time between the rows is either 1/Fs or 1/Fs\*x, where x is any whole number multiple. (In the latter case, the user could fill the missing rows with NaNs, if desired). There are many challenges in transforming RC+S data into such a matrix. Here, we provide an overview of the overall approach. More detailed information on specific steps can be found **HERE** and **HERE** and **HERE**






[Diagram showing general data flow]



## RC+S raw data structures
Each of the .json files has packets which were streamed from the RC+S using a UDP protocol. This means that some packets may have been lost in transmission (e.g. if patient walks out of range) and/or they may be received out of order. Below is a non-comprehensive guide regarding the main datatypes that exists within each .json file as well as their organization when imported into Matlab table format. In the Matlab tables, samples are in rows and data features are in columns. Note: much of the metadata contained in the .json files is not human readable -- sample rates are stored in binary format or coded values that must be converted to Hz. 

### Data in .json files
- **RawDataTD.json**: Contains continuous raw time domain data in packet form. Each packet has timing information (and packet sizes are not consistant). Data can be streamed from up to 4 time domain channels (2 on each bore) at 250Hz and 500Hz or up to 2 time domain channels at 1000Hz. A timestamp and systemTick is only available for the last element of each data packet and timing information for each sample must be deduced. *See section below on timestamp and systemTick*
- **RawDataAccel.json**: Contains continuous raw onboard 3-axis accelerometry data as well as timing information. The structure and timing information is similar to the time domain files.
- **DeviceSettings.json**: Contains information about which datastreams were enabled, start and stop times of streaming, stimulation settings, and device parameters (e.g. sampling rate, montage configuration [which electrodes are being recorded from], power bands limits, etc). Many of these settings can be changed within a given recording; each time such a change is made, another packet is written to DeviceSettings.json file. 
- **RawDataFFT.json** - Contains continuous information streamed from the onboard (on-chip) FFT engine. The structure and timing information is similar to the time domain files.
- **RawDataPower.json** - Contains continuous information streamed from the on board FFT engine in select power bands. The data rate is set by the FFT engine, and can be very fast (1ms) and very slow (upper limit is in the hours or days range). This is the raw input in the onboard embedded adaptive detector. The raw power is much less data intensive than the FFT data. You can stream up to 8 power domain channels (2/each TD channel) simultaneously. Note that the actual bandpass limits are not contained in RawDataPower.json but rather in DeviceSettings.json. If these values are changed during a recording, mapping will be required from the times in DeviceSettings to the data in RawDataPower.
- **AdaptiveLog.json** - Contains any information from the embedded adaptive detector. The structure and timing information is similar to the time domain files.
- **StimLog.json** - Contains information about the stimulation setup (e.g. which group, program, rate and amplitude the device is currently using for stimulation). The structure and timing information is similar to the time domain files. Much of this information is duplicated in DeviceSettings.json.
- **ErrorLog.json**- Contains information about errors. Not currently used.
- **EventLog.json** - Contains discrete information we write into the device. These can be experimental timings or patient report of his state if streaming at home. Note that this information only contains timing information in computer time, whereas all other .json files have timing relative to (on-board) INS time. *See section below on timestamp and systemTick for more information*.
- **DiagnosticsLog.json** - Contains discrete information that can be used for error checking.
- **TimeSync.json**: Not currently used

Note that in each recording session, all .json files will be created and saved. If a particular datastream (e.g. FFT) is not enabled to stream, that .json file will be mostly empty, containing only minimal metadata.

### Data imported into Matlab 

- RawDataTD.json --> timeDomainData:
  - key0: Channel 0 on the first INS bore (assuming no bridging); contains numerical data in millivolts
  - key1: Channel 1 on the first INS bore (assuming no bridging); contains numerical data in millivolts
  - key2: Channel 2 on the first INS bore (assuming no bridging); contains numerical data in millivolts
  - key3: Channel 3 on the first INS bore (assuming no bridging); contains numerical data in millivolts
  - systemTick: 16-bit INS clock timer that rolls over every 2^16 values. Highest resolution is 100 microseconds. One value per packet, corresponding to last sample in the packet. *See section on systemTick and timestamp*
  - timestamp: INS clock driven timer that does not roll over. Highest resolution is 1 second. Total elaped time since March 1, 2000 at midnight. One value per packet, corresponding to last sample in the packet. *See section on systemTick and timestamp*
  - samplerate: Fs in Hz; only written in rows corresponding to last sample of each packet.
  - PacketGenTime: API estimate of when the packet was created on the INS within the PC clock domain. Estimate created by using results of latest latency check (one is done at system initialization, but can re-perform whenever you want) and time sync streaming. Only accurate within ~50ms.
  - PacketRxUnixTime: PC clock-driven time when the packet was received. Highly inaccurate after packet drops.
  - packetsizes: Number of samples per packet. Written in rows corresponding to the last sample of each packet.
  - dataTypeSequence: 8-bit packet number counter that rolls over, ranging from 0 to 255; can be used to help identify if packets are in order or are missing. Should run continuously, but instances of resetting have been observed.
  - DerivedTime: Computed time for each sample - see *Calculating DerivedTime* for more information
  
- RawDataAccel.json --> AccelData
  - XSamples: X-axis
  - YSamples: Y-axis
  - ZSamples: Z-axis
  - systemTick
  - timestamp
  - samplerate
  - PacketGenTime
  - PacketRxUnixTime
  - packetsizes
  - dataTypeSequence
  - DerivedTime

- DeviceSettings.json 
[examples from different files]
  - timeDomainSettings
  
    ![timeDomainSettings](https://github.com/openmind-consortium/Analysis-rcs-data/blob/DocumentationUpdate/documentationFigures/timeDomain.PNG)
  
  - powerSettings
  
    ![powerSettings](https://github.com/openmind-consortium/Analysis-rcs-data/blob/DocumentationUpdate/documentationFigures/powerSettings_2.PNG)
  
  - fftSettings
    ![fftSettings](https://github.com/openmind-consortium/Analysis-rcs-data/blob/DocumentationUpdate/documentationFigures/fftSettings.PNG)
  
  - metaData

- RawDataFFT.json --> FFTData
  - PacketGenTime
  - PacketRxUnixTime
  - Channel
  - FftSize
  - FftOutput
  - Units
  - TDsamplerate
  - dataSize
  - dataType
  - dataTypeSequence
  - globalSequence
  - info
  - systemTick
  - user1
  - user2
  - timestamp
  - samplerate
  - packetsizes
  - DerivedTIme
    
- RawDataPower.json --> PowerData
  - dataSize
  - dataType
  - dataTypeSequence
  - globalSequence
  - info
  - systemTick
  - timestamp
  - TDsamplerate
  - PacketGenTime
  - PacketRxUnixTime
  - ExternalValueMask
  - FFTSize
  - IsPowerChannelOverrange
  - Band1
  - Band2
  - Band3
  - Band4
  - Band5
  - Band6
  - Band7
  - Band8
  - samplerate
  - packetsizes
  - DerivedTime

- AdaptiveLog.json: TBD
- StimLog.json: TBD
- ErrorLog.json: Not currently used
- EventLog.json: TBD
- DiagnosticsLog.json: TBD
- TimeSync.json: Not currently used

## Structure of Repository:
- **code**
  - functions: code for specific needs; [TBD if these are further organized in subfolders]
  - toolboxes: turtle_son, etc...
- **testDataSets**: benchtop generated test data sets for validation of code; often generated signals are simultaneously recorded with DAQ to allow for verification of timing across data streams. 
- **outputFigs**: will contain the output of function testing to the specified test dataset

## Functions: 
This list contains the functions that have been tested in brach and pushed to master (brief description of function input output next to each function name)

### Wrappers
- **DEMO_ProcessRCS**: Demo wrapper script for importing raw .JSON files from RC+S, parsing into Matlab table format, and handling missing packets / harmonizing timestamps across data streams

### CreateTables
- **createDeviceSettingsTable**: Extract information from DeviceSettings related to configuration for time domain, power, and FFT channels
- **createTimeDomainTable**: Create Matlab table of raw data from RawDataTD.json
- **createAccelTable**: Create Matlab table of raw data from RawDataAccel.json
- **createPowerTable**: Create Matlab table of raw data from RawDataPower.json
- **createFFTtable**: Create Matlab table of raw data from RawDataFFT.json

### Utility
- **deserializeJSON**: Reads .json files and loads into Matlab
- **fixMalfomedJSON**: Checks for and replaces missing brackets and braces in json file, which can prevent proper loading
- **convertTDcodes**: Conversion of Medtronic numeric codes into values (e.g. Hz)
- **getSampleRate**: Convert Medtronic codes to sample rates in Hz for time domain data
- **getSampleRateAcc**: Convert Medtronic codes to sample rates in Hz for accelerometer data
- **getPowerBands**: Calculate lower and upper bounds, in Hz, for each power domain timeseries
- **getFFTparameters**: Determine FFT parameters from FFTconfig and TD sample rate

### (Pre)Processing
- **assignTime**: Function for creating timestamps for each sample of valid RC+S data. 



## SystemTick and Timestamp

The function assignTime is designed to * 





__________________________________________________________________________________________________________

assignTime.m: Function for creating timestamps for each sample of valid RC+S data. 

Given known limitations of all recorded timestamps, need to use multiple variables to derive time.

General approach: Remove packets with faulty meta-data. Identify gaps in data (by checking deltas in timestamp, systemTick, and dataTypeSequence). Consecutive packets of data without gaps are referred to as 'chunks'. For each chunk, determine best estimate of the first packet time, and then calculate time for each  sample based on sampling rate -- assume no missing samples. Best estimate of start time for each chunk is determined by taking median (across all packets in that chunk) of the offset between delta PacketGenTime and expected time to have elapsed (as a function of sampling rate and number of samples per packet).


__________________________________________________________________________________________________________






