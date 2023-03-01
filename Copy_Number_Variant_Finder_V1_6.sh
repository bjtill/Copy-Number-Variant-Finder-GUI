#!/bin/bash
#BT February 22, 2023
#GUI Version: Tested on Linux and Mac
#Version 1.6 updates plot axis label and changes color in tile plots.  
  
zenity --width 1000 --info --title "Copy Number Variation Finder (CNVF) GUI: Click OK to start" --text "
  
ABOUT: 
This program aids in the identification of copy number variants between control and test samples by parsing coverage data from a BAM alignment file and plotting the results.  

PREREQUISITES:
1) BAM files that are position sorted and have PCR duplicates removed, 2) An index of each BAM file, 3)the following tools installed: samtools, bash, datamash, awk, sed, zenity, R, and the R package ggplot2. This program was built to run on Ubuntu 20.04 and higher. See the readme file for information on using with other opperating systems.  

TO RUN:
Click OK to start. When prompted, enter the name forT your analysis directory. A new directory will be created and the files created will be deposited in the directory.  Follow the information to select files and start the program.  

LICENSE:  
MIT License 

Copyright (c) 2023 Bradley John Till

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the *Software*), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED *AS IS*, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
Version Information:  Version 1.6, February 28, 2023"
  
directory=`zenity --width 500 --title="DIRECTORY" --text "Enter text to create a new directory (e.g. Sample1234).  
WARNING: No spaces or symbols other than an underscore." --entry`

if [ "$?" != 0 ]
then
    exit
    fi
mkdir $directory
cd $directory

exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>CNVFt.log 2>&1
now=$(date)  
echo "Copy Number Variation Finder (CNVF) GUI, Version 1.0
Script Started $now." 
  
zenity --width 500 --info --title "File Selection" --text "Click OK to select the BAM files you wish to analzye. CAUTION: Select multiple files by holding the Shift or Ctrl keys."

ZAR=$(zenity --file-selection --title="Select the BAM files" --multiple)
echo $ZAR >> bampath 

if [ "$?" != 0 ]
then
    exit
    fi

VAR=`zenity --scale --title="Select the ploidy of your samples" --text "Use the arrow keys if the mouse is frustrating" --value="2" --min-value="0" --max-value="100" –step="1"`
echo $VAR >> ploidy

if [ "$?" != 0 ]
then
    exit
    fi

TAR=`zenity --scale --title="Select the bin size for analysis" --text "Use the arrow keys if the mouse is frustrating" --value="50000" --min-value="1000" --max-value="500000" --step="1000"`
echo $TAR >> binsize
if [ "$?" != 0 ]
then
    exit
    fi
ans=$(zenity --width 500 --info --title 'All Chromosomes & Contigs or a Subset?' \
      --text 'Click All_Chroms_Contigs if you would like to evaluate all chromosomes and contigs in your mapped data. WARNING: Some genome assemblies may have a large number of small contigs that cause the creation of many plots.  You may want to start with a subset.' \
      --ok-label All_Chroms_Contigs \
      --extra-button Subset \
      )

echo $ans >> answer.ans
for file in *.ans
do
   
   if [ -f "$file" ]
   then
       newname=`head -1 $file`
       if [ -f "$newname" ]
       then
              echo "Cannot rename $file to $newname - file already exists"
       else
              mv "$file" "$newname".subset
       fi
   fi
done
if [ -f "Subset.subset" ]; 
then
echo "Subset_selected" > ChromosomeSelection
#Format paths and extract chromosome names from first BAM file
tr '|' '\t' < bampath > bp2
datamash transpose < bp2 > bp3
awk 'NR==1 {print "samtools idxstats", $0, "> chromsa"}' bp3 > bp4.sh
chmod +x bp4.sh
./bp4.sh 
awk '{print $1}' chromsa > Chroms.list 
#Compensate for cases where chromosomes contain a *
mkdir CNVTtemp00001
cp Chroms.list ./CNVTtemp00001/
cd CNVTtemp00001
awk '{if ($1!="*") print $0}' Chroms.list | awk '{print $1, "Blank"}' | datamash transpose | rev | cut -c6- | rev | tr '\t' ' '  > SL5
cp SL5 ..
cd ..
rm -r CNVTtemp00001
zenlist=$(head -1 SL5)
CHR=$(zenity --width 600 --height 600 --list --title="Choose one or more chromosomes/contigs you wish to analyze"  --separator="\n" --column="Select" --column="Chromosome" echo $zenlist --checklist)

if [ "$?" != 0 ]
then
    exit
    fi
echo $CHR >> CHRL  

else 
echo "All Chromosomes Chosen" > Allchrom  #not currently used 
fi


sns=$(zenity --width 500 --info --title 'Is there a Control Sample?' \
      --text 'Click YES if you have a control sample. This will result in two types of data: coverage compared to the control and coverage compared to the mean of all samples. Clicking NO will result in only mean sample comparison.' \
      --ok-label NO \
      --extra-button YES \
      )

echo $sns >> answer.sns
for file in *.sns
do
  
   if [ -f "$file" ]
   then
       newname=`head -1 $file`
       if [ -f "$newname" ]
       then
              echo "Cannot rename $file to $newname - file already exists"
       else
              mv "$file" "$newname".controlsample
       fi
   fi
done
if [ -f "YES.controlsample" ]; 
then
tr '|' '\t' < bampath > bp2
datamash transpose < bp2 > bp3
awk -F'/' '{print $NF}' bp3 > bp4
awk '{print $1, "Blank"}' bp4 | datamash transpose | rev | cut -c6- | rev | tr '\t' ' '  > BP5

zenlist=$(head -1 BP5)
CTL=$(zenity --width 600 --height 600 --list --title="Choose One Sample For Control"  --separator="\n" --column="Select" --column="Sample" echo $zenlist --radiolist)

if [ "$?" != 0 ]
then
    exit
    fi
echo $CTL >> control
else "nocontrol" > nocontrol
tr '|' '\t' < bampath > bp2
datamash transpose < bp2 > bp3
awk -F'/' '{print $NF}' bp3 > bp4
fi 

zenity --width 500 --info --title "READY TO LAUNCH" --text "Click OK to start the Copy Number Variant Finder program. Progress is indicated by a progress bar. A log file titled CNVF.log will be created."

(#Start progress bar
echo "# Starting"; sleep 2
echo "10"
echo "# Generating coverage data from the BAM files. This may take a long time."; sleep 2
#collect coverage
samtools depth -a -H -f bp3 -o STdepth
for file in CHRL
do
   # Avoid renaming diretories!
   if [ -f "$file" ]
then
tr ' ' '\t' < CHRL > CHRL2
datamash transpose < CHRL2 > CHRL3
head -1 STdepth > STH
awk 'NR==FNR{a[$1]=$1;next}{if (a[$1]) print $0}' CHRL3 STdepth > STdepth2a
cat STH STdepth2a > STdepth2
else 
mv STdepth STdepth2
fi
done
echo "50"
###################################################################################################

tail -n +2 STdepth2 > OT
head -1 STdepth2 > h2
rm STdepth2 STdepth
#Split the table into info columns and data colums for processing
awk '{print $1, $2}' OT > OTA
#Mac fix
cut -f3- OT > OTB
#Get info columns with binsize
a=$(head -1 binsize)
awk -v var=$a 'NR % var == 0' OTA > OT1
awk 'BEGIN{print "Chromosome", "Position"}1' OT1 > IC2  #Info Columns with header
rm OT1
#Take the mean of every n lines with binsize variable 
a=$(head -1 binsize)
awk -v N=$a '{ for (i = 1; i <= NF; i++) sum[i] += $i } NR % N == 0 { for (i = 1; i <= NF; i++) {printf("%.6f%s", sum[i]/N, (i == NF) ? "\n" : " ") 
sum[i] = 0}}' OTB > OTC  #NOTE the newline here is intentional 
#Mac fix
cut -f3- h2 > h3
rm OTB
###################################################################################################
echo "# Processing coverage data"; sleep 2
datamash transpose < bp4 > bp4t

for file in control
do
   
   if [ -f "$file" ]
#Get coverage values when control coverage is set to the ploidy value
then 
b=$(head -1 control)
awk -v b="$b" '{for (i=1;i<=NF;i++) { if ($i == b) { print i } }}' bp4t > h4
c=$(head -1 h4)
awk -v c="$c" '{ for( i=1;i<=NF;i++ ) { printf "%f%s",  $i/($c+0.0000000000001), OFS }; printf "%s", ORS  }' OTC > OTG
p=$(head -1 ploidy)
awk -v p="$p" '{ for( i=1;i<=NF;i++ ) { printf "%f%s",  $i*p, OFS }; printf "%s", ORS  }' OTG > OTH
rm OTG

awk '{for (i=1;i<=NF;i++) printf $i "_controlcompare "}' bp4t | awk '{print $0}' > cc1
cat cc1 OTH > OTI #add header
rm OTH
mkdir ControlCompare
mv OTI ./ControlCompare/
cp IC2 ./ControlCompare/
cp ploidy ./ControlCompare/
cd ControlCompare
#split each sample column to process for plotting
#Fix Mac
awk '$1=$1' OTI | awk -F '[ ]' '{for(i=1; i<=NF; i++)  print $i >> ("column" i ".txt"); close("column" i ".txt")}' 
#Combine data and sample name and fill the empty columns
for i in *.txt; do 
tail -n +2 $i > ${i%.*}.tail
head -1 $i > ${i%.*}.hed
paste ${i%.*}.tail ${i%.*}.hed > ${i%.*}.sail
awk '$2==""{$2=p}{p=$2}1' ${i%.*}.sail > ${i%.*}.bail ; done 
tail -n +2 IC2 > ICUP
for i in *.bail; do 
paste ICUP ${i%.*}.bail > ${i%.*}.boil; done 
cat *.boil > controldata
sed 's/_controlcompare //g' controldata > controldata2
#Split by chromosome
awk '{print > ($1".bb")}' controldata2
#Split by chromosome
for i in *.bb; do 
#Prepare coverage groups
a=$(head -1 ploidy)
 awk -v v="$a" '{if($3 <= (v+0.7) && $3 >= (v-0.7)) print $0, "3"; else if ($3 > (v+0.7) && $3 <= (v+1.7)) print $0, "4"; else if ($3 > (v+1.7) && $3 <= (v+2.7)) print $0, "5"; else if ($3 > (v+2.7)) print $0, "6"; else if ($3 < (v-0.7) && $3 >= (v-1.7)) print $0, "2"; else if ($3 < (v-1.7) && $3 >= (v-2.7)) print $0, "1"; else if ($3 < (v-2.7)) print $3, "0"; else print $0, "ERROR"}' $i > ${i%.*}.nf3
 
 done 
 
#Add header and prepare for plotting
for i in *.nf3; do 
awk 'BEGIN{print "Chromosome", "Position", "CovBMean", "Sample", "CovGp"}1' $i > ${i%.*}.nf4; done 
for i in *.nf4; do 
tr ' ' ',' < $i > ${i%.*}.nf5
tr '\t' ',' < ${i%.*}.nf5 > ${i%.*}.nf6
done

printf 'library(ggplot2) \nfile_list=list.files(full.names=F, pattern="\\\.nf6") \nfilenames <- gsub("\\\.nf6$","", list.files(pattern="\\\_tmp$")) \nfor (i in file_list){ \ng<-read.csv(i) \np <- ggplot(g, aes(x=Position, y=Sample, fill=factor(CovGp))) + geom_tile() + scale_fill_manual(values =c("0"="#273046","1"="#046C9A", "2"="#3B9AB2", "3"="darkgreen", "4"="#EBCC2A", "5"="#E58601", "6"="#B40F20"), name = "Coverage Groups") + theme(axis.text.x = element_text(angle = 90, size =8, vjust = 0.5, hjust=1), axis.text.y = element_text(size = 8)) + xlab("Position")\np2 <- p + labs(title= sub("\\\.nf6$","",i)) \nggsave(plot = p2, filename= paste0(i, "AFbinsc3.tiff")) \n#p3 <- ggplotly(p2) \n#htmlwidgets::saveWidget(p3, file = paste0(i, ".html")) \n}' > AFbin.R

Rscript AFbin.R
for i in *nf6AFbins*; do mv $i ${i%.nf6*}_ControlCompare_CoverageGroups.jpeg; done
mkdir CovPlot
cp *.nf6 ./CovPlot
cd CovPlot 

printf 'library(ggplot2) \nfile_list=list.files(full.names=F, pattern="\\\\.nf6") \nfilenames <- gsub("\\\.nf6$","", list.files(pattern="\\\_tmp$")) \nfor (i in file_list){ \ng<-read.csv(i) \np <- ggplot(g, aes(x=Position, y=CovBMean, color=Sample)) + geom_point(size=1, alpha = 0.5) + theme(axis.text.x = element_text(angle = 90, size =8), axis.text.y = element_text(size = 8)) + labs(title="_Coverage_Variation") + ylab("Coverage Compared to Control") \np2 <- p + labs(title= sub("\\\.nf6$","",i))\nggsave(plot = p2, filename= paste0(i, "Covbins.jpeg"), width=10, height=5, units=c("in"))  \n}' > BFbin.R

Rscript BFbin.R
for i in *nf6Covbins*; do mv $i ${i%.nf6*}_ControlCompare_Coverage.jpeg; done
cp *.jpeg ..
cd ..
rm -r CovPlot
#Prepare a data table for keeping 
cat *.nf3 | awk 'BEGIN{print "Chromosome", "Position", "CovBMean", "Sample", "CovGp"}1'| tr ' ' ',' | tr '\t' ',' > AllData_ControlCompare.csv
rm *.sail *.hed *.boil *.bail *.tail *.txt controldata controldata2 IC2 ICUP OTI ploidy *.bb *.nf3 *.nf4 *.nf5 *.nf6 AFbin.R
cd ..
fi
done
echo "80"
echo "# Generating plots."; sleep 2

#Process the data compared to the mean of all samples  
awk '{sum=0; for (i=1;i<=NF;i++)sum+=$i; print $0,sum/(NF)}' OTC > CT1
awk 'NR==1 {print NF}' CT1 > meancol
d=$(head -1 meancol)
awk -v d="$d" '{ for( i=1;i<=NF;i++ ) { printf "%f%s",  $i/($d+0.0000000000001), OFS }; printf "%s", ORS  }' CT1 > CT2   
#remove terminal column
awk 'NF{NF-=1};1' CT2 > CT3
#Setting values to user selected ploidy. 
p=$(head -1 ploidy)
awk -v p="$p" '{ for( i=1;i<=NF;i++ ) { printf "%f%s",  $i*p, OFS }; printf "%s", ORS  }' CT3 > CT4
datamash transpose < bp4 > bp4t
awk '{for (i=1;i<=NF;i++) printf $i "_meancompare "}' bp4t | awk '{print $0}' > mc1
cat mc1 CT4 > ct5
mkdir MeanCompare
mv ct5 ./MeanCompare/
cp IC2 ./MeanCompare/
cp ploidy ./MeanCompare/
cd MeanCompare

#Split tables by sample, add sample name and fill empty rows in table.
#MAC fix
awk '$1=$1' ct5 | awk -F '[ ]' '{for(i=1; i<=NF; i++)  print $i >> ("column" i ".txt"); close("column" i ".txt")}'  
for i in *.txt; do 
tail -n +2 $i > ${i%.*}.tail
head -1 $i > ${i%.*}.hed
paste ${i%.*}.tail ${i%.*}.hed > ${i%.*}.sail
awk '$2==""{$2=p}{p=$2}1' ${i%.*}.sail > ${i%.*}.bail ; done 
tail -n +2 IC2 > ICUP
for i in *.bail; do 
paste ICUP ${i%.*}.bail > ${i%.*}.boil; done 
cat *.boil > meandata
sed 's/_meancompare//g' meandata > meandata2
#Split data by chromosome
awk '{print > ($1".bb")}' meandata2

 
for i in *.bb; do 
#Prepare coverage groups
a=$(head -1 ploidy)
 awk -v v="$a" '{if($3 <= (v+0.7) && $3 >= (v-0.7)) print $0, "3"; else if ($3 > (v+0.7) && $3 <= (v+1.7)) print $0, "4"; else if ($3 > (v+1.7) && $3 <= (v+2.7)) print $0, "5"; else if ($3 > (v+2.7)) print $0, "6"; else if ($3 < (v-0.7) && $3 >= (v-1.7)) print $0, "2"; else if ($3 < (v-1.7) && $3 >= (v-2.7)) print $0, "1"; else if ($3 < (v-2.7)) print $3, "0"; else print $0, "ERROR"}' $i > ${i%.*}.nf3
 
 done 
 
#Format for plotting
for i in *.nf3; do 
awk 'BEGIN{print "Chromosome", "Position", "CovBMean", "Sample", "CovGp"}1' $i > ${i%.*}.nf4; done 
for i in *.nf4; do 
tr ' ' ',' < $i > ${i%.*}.nf5
tr '\t' ',' < ${i%.*}.nf5 > ${i%.*}.nf6
done
 
printf 'library(ggplot2) \nfile_list=list.files(full.names=F, pattern="\\\.nf6") \nfilenames <- gsub("\\\.nf6$","", list.files(pattern="\\\_tmp$")) \nfor (i in file_list){ \ng<-read.csv(i) \np <- ggplot(g, aes(x=Position, y=Sample, fill=factor(CovGp))) + geom_tile() + scale_fill_manual(values =c("0"="#273046","1"="#046C9A", "2"="#3B9AB2", "3"="darkgreen", "4"="#EBCC2A", "5"="#E58601", "6"="#B40F20"), name = "Coverage Groups") + theme(axis.text.x = element_text(angle = 90, size =8, vjust = 0.5, hjust=1), axis.text.y = element_text(size = 8)) + xlab("Position")\np2 <- p + labs(title= sub("\\\.nf6$","",i)) \nggsave(plot = p2, filename= paste0(i, "AFbinsc3.tiff")) \n#p3 <- ggplotly(p2) \n#htmlwidgets::saveWidget(p3, file = paste0(i, ".html")) \n}' > AFbin.R

Rscript AFbin.R

mkdir CovPlot
cp *.nf6 ./CovPlot
cd CovPlot 

printf 'library(ggplot2) \nfile_list=list.files(full.names=F, pattern="\\\\.nf6") \nfilenames <- gsub("\\\.nf6$","", list.files(pattern="\\\_tmp$")) \nfor (i in file_list){ \ng<-read.csv(i) \np <- ggplot(g, aes(x=Position, y=CovBMean, color=Sample)) + geom_point(size=1, alpha = 0.5) + theme(axis.text.x = element_text(angle = 90, size =8), axis.text.y = element_text(size = 8)) + labs(title="_Coverage_Variation") + ylab("Coverage Compared to Mean of All Samples") \np2 <- p + labs(title= sub("\\\.nf6$","",i))\nggsave(plot = p2, filename= paste0(i, "Covbins.jpeg"), width=10, height=5, units=c("in"))  \n}' > BFbin.R

Rscript BFbin.R
cp *.jpeg ..
cd .. 
rm -r CovPlot
for i in *nf6AFbins*; do mv $i ${i%.nf6*}_MeanCompare_CoverageGroups.jpeg; done
#Prepare a data table for keeping
cat *.nf3 | awk 'BEGIN{print "Chromosome", "Position", "CovBMean", "Sample", "CovGp"}1'| tr ' ' ',' | tr '\t' ',' > AllData_MeanCompare.csv
rm *.sail *.hed *.boil *.bail *.tail *.txt controldata controldata2 IC2 ICUP OTI ploidy *.bb *.nf3 *.nf4 *.nf5 *.nf6 AFbin.R ct5 meandata meandata2
for i in *nf6Covbins*; do mv $i ${i%.nf6*}_MeanCompare_Coverage.jpeg; done
cd ..


echo "95" 
echo "# Final processing steps.  Program almost finished."; sleep 2
) | zenity --width 800 --title "PROGRESS" --progress --auto-close
now=$(date)  
echo "Program finished $now."
#Collect info on user parameters 
awk 'BEGIN{print "BAM files selected and their path:"}1' bp3 > B4L
awk 'BEGIN{print "Bin size selected (in base pairs):"}1' binsize > BSL
 #awk 'BEGIN{print "Chromosomes selected:"}1' CHRL > CSL
awk 'BEGIN{print "Ploidy selected:"}1' ploidy > PSL

#Update log and remove extra files
cat CNVFt.log B4L BSL PSL > CNVF.log
rm CNVFt.log 
rm bampath binsize bp2	bp3 bp4 bp4.sh	bp4t BP5 cc1 CHRL CHRL2 CHRL3 ChromosomeSelection chromsa Chroms.list CNVFt.log control controllist CT1 CT2 CT3 CT4 h2 h3 h4 IC2 mc1 mc1t mean meancol OT OT1 OTA OTB OTC OTG OTH ploidy SL5	STdepth2a STH Subset.subset YES.controlsample B4L BSL PSL

#End of program
