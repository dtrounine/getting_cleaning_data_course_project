library(dplyr)
library(tools)

#
# Scans the current directory recursively for a file having MD5 checksum of the data file we need
# Returns the found file, ot NULL if therea are no such file
#
findRawDataFile <- function() {
    allFiles <- list.files(path = ".", all.files = TRUE, recursive = TRUE, include.dirs = FALSE)
    foundFiles <- allFiles[md5sum(allFiles) == "d29710c9530a31f303801b6bc34bd895"]
    if (length(foundFiles) >= 1) {
        foundFiles[[1]]
    } else {
        NULL
    }
}

iswindows <- function() {
    tolower(Sys.info()["sysname"]) == "windows"
}

#
# Finds previously downloaded or, if not found, downloads the raw data file to be used for analysis.
# Returns the file name.
#
getRawFile <- function() {
    filename <- findRawDataFile()
    
    if (!is.null(filename)) {
        print(paste("Using data file: ", filename, sep = ""))
        
    } else {
        if (!file.exists("data")) {
            dir.create("data")
        }
        fileUrl <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"
        filename <- file.path("data", "samsung_raw_data.zip")
        print(paste("Downloading from ", fileUrl, " to ", filename, sep = ""))
        downloadMethod <- if (iswindows()) "auto" else "curl"
        download.file(fileUrl, filename, method = downloadMethod)
    }
    filename
}

#
# Loads raw list of features
#
loadFeatures <- function(rawFile) {
    con <- unz(description = rawFile, 
               filename = "UCI HAR Dataset/features.txt")
    features <- read.table(con, 
                           stringsAsFactors = FALSE, 
                           header = FALSE, 
                           sep = " ", 
                           col.names = c("offset", "feature"))
    features
}

#
# Loads raw activity labels
#
loadLabels <- function(rawFile) {
    con <- unz(description = rawFile, 
               filename = "UCI HAR Dataset/activity_labels.txt")
    labels <- read.table(con, 
                         stringsAsFactors = FALSE, 
                         header = FALSE, 
                         sep = " ", 
                         col.names = c("value", "label"))
    labels
}

#
# Loads raw measurements data from specified sub-folder of raw archive file
#
loadMeasurements <- function(rawFile, subfolder, suffix) {
    con <- unz(description = rawFile,
               filename = paste("UCI HAR Dataset/", subfolder, "/X", suffix, ".txt", sep = ""))
    measurements <- read.table(con,
                               stringsAsFactors = FALSE,
                               header = FALSE,
                               sep = "")
    measurements
}

#
# Loads subject data from specified sub-folder of raw archive file
#
loadSubjects <- function(rawFile, subfolder, suffix) {
    con <- unz(description = rawFile,
               filename = paste("UCI HAR Dataset/", subfolder, "/subject", suffix, ".txt", sep = ""))
    subjects <- readLines(con)
    close(con)
    subjects
}

#
# Loads activity data from specified sub-folder of raw archive file
#
loadActivities <- function(rawFile, subfolder, suffix) {
    con <- unz(description = rawFile,
               filename = paste("UCI HAR Dataset/", subfolder, "/y", suffix, ".txt", sep = ""))
    activities <- readLines(con)
    close(con)
    activities
}

#
# Loads data from the specified sub-folder of the raw archive file,
# selects features and replace activity value by their label names
# 
# Params:
#   features - table of features to extraxt with their offsets and names
#   labels - table of label names
#   subfolder - "test" or "train"
#   suffix - "_test" or "_train"
#
loadData <- function(rawFile, features, labels, subfolder, suffix) {
    #
    # Load measurements and select required columns, set pretty column names
    #
    d <- loadMeasurements(rawFile, subfolder, suffix)
    d <- tbl_df(d)
    d <- d %>% select(features$offset)
    colnames(d) <- features$feature
    
    #
    # Load subject data and add subject column to dataset
    #
    subjects <- loadSubjects(rawFile, subfolder, suffix)
    d <- d %>% mutate(subject = subjects)
    
    #
    # Load activity data, replace values by pretty name and add activity column to dataset
    #
    activities <- loadActivities(rawFile, subfolder, suffix)
    activities <- labels$label[match(activities, labels$value)]
    d <- d %>% mutate(activity = activities)
    
    #
    # Reorder columns so that subject and activity come first
    #
    d <- d %>% select(subject, activity, one_of(features$feature))
    
    d
}

doAnalysis <- function() {
    #
    # Obtain the original file
    #
    rawFile <- getRawFile()
    
    #
    #  Get list of features and select those having mean() or std() in name
    #  as required for our analysis.
    #  Then convert the raw names ofto pretty names with no "(" nor "-" characters
    #
    features <- loadFeatures(rawFile)
    features <- tbl_df(features)
    features <- features %>%
        # Select only faetures containing mean() or std()
        filter(grepl("mean[(][)]|std[(][)]", feature)) %>%
        # Convert mean() to Mean
        mutate(feature = sub("mean[(][)]", "Mean", feature)) %>%
        # Convert std() to Std
        mutate(feature = sub("std[(][)]", "Std", feature)) %>%
        # Remove "-"
        mutate(feature = gsub("-", "", feature))
    
    #
    # Get the list of activity labels and convert raw names to pretty name
    #
    labels <- loadLabels(rawFile)
    labels <- tbl_df(labels)
    labels <- labels %>%
        mutate(label = tolower(label))
    
    #
    # Load test and train data and merge them into single dataset
    #
    testData <- loadData(rawFile, features, labels, "test", "_test")
    trainData <- loadData(rawFile, features, labels, "train", "_train")
    allData <- bind_rows(trainData, testData)
    
    #
    # Create independent dataset with average value of each variable groupped by subject and activity
    #
    avgBySubjAct <- allData %>% group_by(subject, activity) %>% summarize_each(funs(mean))
    
    #
    # Save to output file
    #
    outFilename <- "avg_by_subject_activity.csv"
    if (file.exists(outFilename)) {
        file.remove(outFilename)
    }
    write.csv(avgBySubjAct, outFilename, row.names = FALSE)
    print(paste("Data set saved to ", outFilename, sep = ""))
}

doAnalysis()
