<<<<<<< HEAD
# Check if dependencies are installed and require them.
RequireOrInstall <- function(package) {
  suppressWarnings({
    if (!require(package,character.only=TRUE)) {
      installPackage <- readline(paste("Package",package,"not found. Install? (y for yes, otherwise for no): "))
      if (installPackage == "y") {
        install.packages(package)
      }
      require(package,character.only=TRUE)  
  }})
}
RequireOrInstall("plyr")
RequireOrInstall("reshape2")

DeriveTidy1 <- function(dataRootDir = "UCI HAR Dataset") {

  # utility function
  FilePath <- function(file) {
    paste(dataRootDir,"/",file,sep="")
  }

  # some constants describing file locations
  kXTestFile <- FilePath("test/X_test.txt")
  kXTrainFile <- FilePath("train/X_train.txt")
  kFeaturesFile <- FilePath("features.txt")
  kActivityLabelsFile <- FilePath("activity_labels.txt")
  kTestActivitiesFile <- FilePath("test/y_test.txt")
  kTrainActivitiesFile <- FilePath("train/y_train.txt")
  kSubjectTestFile <- FilePath("test/subject_test.txt")
  kSubjectTrainFile <- FilePath("train/subject_train.txt")

  #merge training and test sets
  testSet <- read.table(kXTestFile)
  trainingSet <- read.table(kXTrainFile)
  allObservations <- rbind(testSet,trainingSet)

  #add feature names as column names
  featureNames <- read.table(kFeaturesFile,stringsAsFactors=FALSE)[[2]]
  colnames(allObservations) <- featureNames
  #only select the columns that have mean, std or activityLabel in their name
  allObservations <- allObservations[,grep("mean|std|activityLabel",featureNames)]

  #rename variable names to more readable form.
  #I have deliberately chosen not to rename to a full English words,
  #because column names tend to get very long then
  varNames = names(allObservations)
  varNames <- gsub(pattern="^t",replacement="time",x=varNames)
  varNames <- gsub(pattern="^f",replacement="freq",x=varNames)
  varNames <- gsub(pattern="-?mean[(][)]-?",replacement="Mean",x=varNames)
  varNames <- gsub(pattern="-?std[()][)]-?",replacement="Std",x=varNames)
  varNames <- gsub(pattern="-?meanFreq[()][)]-?",replacement="MeanFreq",x=varNames)
  varNames <- gsub(pattern="BodyBody",replacement="Body",x=varNames)
  names(allObservations) <- varNames

  #use the activity names to name the activities in the set
  activityLabels <- read.table(kActivityLabelsFile,stringsAsFactors=FALSE)
  colnames(activityLabels) <- c("activityID","activityLabel")

  #appropriately label the data set with descriptive activity names
  #first we create the activity column for the entire dataset, test+train:
  testActivities <- read.table(kTestActivitiesFile,stringsAsFactors=FALSE)
  trainingActivities <- read.table(kTrainActivitiesFile,stringsAsFactors=FALSE)
  allActivities <- rbind(testActivities,trainingActivities)
  #assign a column name so we can merge on it
  colnames(allActivities)[1] <- "activityID"
  #join the activityLabels - we use join from the plyr package and not merge, because join
  #preserves order
  activities <- join(allActivities,activityLabels,by="activityID")

  #and add the column to the entire dataset
  allObservations <- cbind(activity=activities[,"activityLabel"],allObservations)

  #extra step: include the subject ids, for processing in the next step
  testSubjects <- read.table(kSubjectTestFile,stringsAsFactors=FALSE)
  trainingSubjects <- read.table(kSubjectTrainFile,stringsAsFactors=FALSE)
  allSubjects <- rbind(testSubjects,trainingSubjects)
  colnames(allSubjects) <- "subject"
  allObservations <- cbind(allSubjects,allObservations)

  sorted <- allObservations[order(allObservations$subject,allObservations$activity),]
  sorted
}

DeriveTidy2 <- function(rawData) {
  #create a long shaped dataset from a wide shaped dataset
  molten <- melt(rawData,id.vars= c("subject","activity"))
  #transform the long shaped dataset back into a wide shaped dataset, aggregating on subject 
  #and activity using the mean function
  cast <- dcast(molten, subject+activity ~ variable, fun.aggregate=mean)
  cast
}

DeriveAndWriteDataSets <- function() {
  tidy1 <- DeriveTidy1()
  tidy2 <- DeriveTidy2(tidy1)
  write.csv(tidy1,file="tidy1.csv")
  write.csv(tidy2,file="tidy2.csv")
}
=======
#Step 1: "Merges the training and the test sets to create one data set."
# read subject training data
subject_train = read.table("UCI HAR Dataset/train/subject_train.txt", col.names=c("subject_id"))
# assign row number as the values of ID column
subject_train$ID <- as.numeric(rownames(subject_train))
# read training data
X_train = read.table("UCI HAR Dataset/train/X_train.txt")
# assign row number as the values of ID column
X_train$ID <- as.numeric(rownames(X_train))
# read activity training data
y_train = read.table("UCI HAR Dataset/train/y_train.txt", col.names=c("activity_id"))  # max = 6
#y_train = merge(y_train, activity_labels)
# assign row number as the values of ID column
y_train$ID <- as.numeric(rownames(y_train))
# merge subject_train and y_train to train
train <- merge(subject_train, y_train, all=TRUE)
# merge train and X_train
train <- merge(train, X_train, all=TRUE)

# read subject training data
subject_test = read.table("UCI HAR Dataset/test/subject_test.txt", col.names=c("subject_id"))
# assign row number as the values of ID column
subject_test$ID <- as.numeric(rownames(subject_test))
# read testing data
X_test = read.table("UCI HAR Dataset/test/X_test.txt")
# assign row number as the values of ID column
X_test$ID <- as.numeric(rownames(X_test))
# read activity testing data
y_test = read.table("UCI HAR Dataset/test/y_test.txt", col.names=c("activity_id"))  # max = 6
#y_test = merge(y_test, activity_labels)
# assign row number as the values of ID column
y_test$ID <- as.numeric(rownames(y_test))
# merge subject_test and y_test to train
test <- merge(subject_test, y_test, all=TRUE) 
# merge test and X_test
test <- merge(test, X_test, all=TRUE) 
 
#combine train and test
data1 <- rbind(train, test)

#Step 2: "Extracts only the measurements on the mean and standard deviation for each measurement."
features = read.table("UCI HAR Dataset/features.txt", col.names=c("feature_id", "feature_label"),)  #561
#Extracts only the measurements on the mean and standard deviation for each measurement. 
selected_features <- features[grepl("mean\\(\\)", features$feature_label) | grepl("std\\(\\)", features$feature_label), ]
data2 <- data1[, c(c(1, 2, 3), selected_features$feature_id + 3) ]

#Step 3: "Uses descriptive activity names to name the activities in the data set."
activity_labels = read.table("UCI HAR Dataset/activity_labels.txt", col.names=c("activity_id", "activity_label"),) #
data3 = merge(data2, activity_labels)

#Step 4: "Appropriately labels the data set with descriptive activity names." 
selected_features$feature_label = gsub("\\(\\)", "", selected_features$feature_label)
selected_features$feature_label = gsub("-", ".", selected_features$feature_label)
for (i in 1:length(selected_features$feature_label)) {
    colnames(data3)[i + 3] <- selected_features$feature_label[i]
}
data4 = data3

#Step 5: "Creates a second, independent tidy data set with the average of each variable for each activity and each subject."
drops <- c("ID","activity_label")
data5 <- data4[,!(names(data4) %in% drops)]
aggdata <-aggregate(data5, by=list(subject = data5$subject_id, activity = data5$activity_id), FUN=mean, na.rm=TRUE)
drops <- c("subject","activity")
aggdata <- aggdata[,!(names(aggdata) %in% drops)]
aggdata = merge(aggdata, activity_labels)
write.csv(file="submit.csv", x=aggdata)
>>>>>>> fc5c402d4d3591d79a5a02d50ef6590159922b0a
