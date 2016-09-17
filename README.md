# Human Activity Recognition Using Smartphones Data Set 

This repo contains R script for processing the data set originally published [here](http://archive.ics.uci.edu/ml/datasets/Human+Activity+Recognition+Using+Smartphones). 

## Files

* [run_analysis.R](https://github.com/dtrounine/getting_cleaning_data_course_project/blob/master/run_analysis.R) - R script which generates data set
* [CodeBook.md](https://github.com/dtrounine/getting_cleaning_data_course_project/blob/master/CodeBook.md) - Code Book, description of data set

## Generating data

In order to generate the data set, run the [run_analysis.R](https://github.com/dtrounine/getting_cleaning_data_course_project/blob/master/run_analysis.R) script. For this you can type ```source("run_analysis.R")``` in R Studio from the directory containing the script.

When the script is executed it checks the current directory for the original raw data file (ZIP archive downloaded from [https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip](https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip)) and downloads it if it's missing. Then the data set is generated in ```avg_by_subject_activity.csv``` file. The content of output data set is described in the [Code Book](https://github.com/dtrounine/getting_cleaning_data_course_project/blob/master/CodeBook.md)
