rm(list=ls()) ##Removing any remaining objects

###Change to whatever drive is appropriate for your setup
setwd("C://Users/elisw/Dropbox/School/Data, analyses/Emilie SR/Butterfly comparative brain project/April 2016/Dryad Test")

###These packages may need to be installed.
library(bbmle)
library(picante)
library(caper)
library(ape)
library(nlme)
library(geiger)
library(reshape)
library(ggplot2)

###Loading nexus file with phylogeny
###Depending on how you download the data, this might be "butterfly_tree.nex" or "butterfly_tree.txt"
treeb<-read.nexus("butterfly_tree.txt")

data <- read.csv("individual_field_data.csv")  ###Reading in file

data$spec.id <- as.numeric(data$Species)
data$binom <- data$Species

treeb<-makeNodeLabel(treeb) 
data$Wing.Length <- log(data$Wing.length)

###Setting up and scaling the individual-level data
model.data <- data.frame("Number.Eggs" = data$Number.of.mature.eggs, "N.family.level" = data$N.family.level,"spec.id" = data$spec.id, "binom" = data$binom, "Wing.Length" = data$Wing.length, "Timing" = data$Timing, "Family" = data$Family,"Species" = data$Species)
model.data <- na.omit(model.data)
model.data$Number.Eggs <- scale(model.data$Number.Eggs)
model.data$Wing.Length <- scale(model.data$Wing.Length)
model.data$N.family.level <- scale(model.data$N.family.level)

###Aggregating and scaling the species level data
species.data <- recast(model.data,Species+Family+Timing~variable,mean)
species.data$Number.Eggs <- scale(species.data$Number.Eggs)
species.data$Wing.Length <- scale(species.data$Wing.Length)
species.data$N.family.level <- scale(species.data$N.family.level)

family.data <- recast(model.data,Family~variable,mean)

###Creating comparative data object for PGLS
row.names(species.data) <- species.data$Species
treedata<-treedata(treeb,species.data)
comp.data<-comparative.data(phy=treedata$phy,data.frame(treedata$data),names.col= Species)

egg.lambda <- pgls(Number.Eggs~1,data=comp.data,lambda='ML')  ##Calculating lambda for intercept model

###Running models with uncorrected egg size
egg.N <- pgls(Number.Eggs~N.family.level,data=comp.data,lambda='ML')
egg.N.F <- pgls(Number.Eggs~N.family.level*Family,data=comp.data,lambda='ML')
egg.N.T <- pgls(Number.Eggs~N.family.level*Timing,data=comp.data,lambda='ML') #Not estimable

aics <- data.frame(print(AICctab(egg.N,egg.N.F,egg.N.T,nobs=nrow(comp.data$data))))  ###Calculating AICc table

###Models with body size corrected egg size
egg.corr.N <- pgls(Number.Eggs~N.family.level+Wing.Length,data=comp.data,lambda='ML')
egg.corr.N.F <- pgls(Number.Eggs~N.family.level*Family+Wing.Length,data=comp.data,lambda='ML')
egg.corr.N.T <- pgls(Number.Eggs~N.family.level*Timing+Wing.Length,data=comp.data,lambda='ML') #Not estimable

corr.aics <- data.frame(print(AICctab(egg.corr.N,egg.corr.N.F,egg.corr.N.T,nobs=nrow(comp.data$data))))  ###Calculating AICc table

###Summaries of models
sum.egg.N <- summary(egg.N)
sum.egg.N.F <- summary(egg.N.F)
sum.egg.N.T <- summary(egg.N.T)
sum.egg.corr.N <- summary(egg.corr.N)
sum.egg.corr.N.F <- summary(egg.corr.N.F)
sum.egg.corr.N.T <- summary(egg.corr.N.T)

